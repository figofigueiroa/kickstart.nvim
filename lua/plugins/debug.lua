-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for .NET (C#/F#),
-- but can be extended to other languages as well.
--
-- Everything loads lazily: the first <F5> / <leader>d* keypress loads
-- nvim-dap and its UI/management stack.

local uv = vim.uv or vim.loop
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

-- Used by `<leader>da` (Run with Args).
local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
  local args_str = type(args) == 'table' and table.concat(args, ' ') or args
  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input('Run with args: ', args_str))
    return require('dap.utils').splitstr(new_args)
  end
  return config
end

-- ===========================================================================
-- Descoberta de assemblies .NET (substitui o vim.fn.input sem autocomplete)
-- ===========================================================================

-- Pastas que nunca precisam ser varridas ao procurar projetos.
local skip_dirs = { bin = true, obj = true, ['.git'] = true, ['.vs'] = true, ['.idea'] = true, node_modules = true }

local function is_project(name) return name:match '%.csproj$' ~= nil or name:match '%.fsproj$' ~= nil end

--- Procura *.csproj / *.fsproj abaixo de `root` (ignorando bin/obj/.git/...).
local function find_project_files(root)
  local projects = {}
  local ok, iter = pcall(vim.fs.dir, root, {
    depth = 5,
    skip = function(dir) return not skip_dirs[dir] end,
  })
  if not ok then return projects end
  for name, kind in iter do
    if kind == 'file' and is_project(name) then table.insert(projects, vim.fs.normalize(root .. '/' .. name)) end
  end
  return projects
end

--- Lista todos os assemblies EXECUTÁVEIS já compilados dentro do cwd.
--- Truque central: só projetos executáveis geram `<Nome>.runtimeconfig.json`
--- ao lado do `.dll`. Isso elimina bibliotecas, testhost, Microsoft.*, xunit.*
--- e o resto do ruído sem precisar de lista negra de nomes.
local function runnable_assemblies()
  local root = vim.fs.normalize(vim.fn.getcwd())
  local buf = vim.api.nvim_buf_get_name(0)
  buf = buf ~= '' and vim.fs.normalize(buf) or nil
  local items, seen = {}, {}

  for _, project in ipairs(find_project_files(root)) do
    local dir = vim.fs.dirname(project)
    local name = vim.fn.fnamemodify(project, ':t:r')

    local globs = {
      dir .. '/bin/*/*/' .. name .. '.dll', -- bin/Debug/net9.0/App.dll
      dir .. '/bin/*/*/*/' .. name .. '.dll', -- bin/Debug/net9.0/win-x64/App.dll (RID)
      dir .. '/bin/*/' .. name .. '.dll', -- OutputPath customizado
    }

    for _, glob in ipairs(globs) do
      for _, hit in ipairs(vim.fn.glob(glob, true, true)) do
        local dll = vim.fs.normalize(hit)
        local runtimeconfig = (dll:gsub('%.dll$', '.runtimeconfig.json'))
        if not seen[dll] and uv.fs_stat(runtimeconfig) then
          seen[dll] = true
          local config_name, tfm = dll:match '/bin/([^/]+)/(net[^/]+)'
          local stat = uv.fs_stat(dll)
          table.insert(items, {
            path = dll,
            project_file = project,
            project = name,
            config = config_name or '?',
            tfm = tfm or '?',
            mtime = stat and stat.mtime.sec or 0,
            rel = vim.startswith(dll, root .. '/') and dll:sub(#root + 2) or dll,
            is_test = name:lower():match 'tests?$' ~= nil,
            -- afinidade com o buffer atual: o projeto que eu estou editando
            -- é quase sempre o que eu quero debugar
            is_current = buf ~= nil and vim.startswith(buf, dir .. '/'),
          })
        end
      end
    end
  end

  -- Projeto do buffer atual primeiro, testes por último, empate pelo build
  -- mais recente. A afinidade com o buffer importa porque um `dotnet build`
  -- na solution iguala o mtime de todos os assemblies de uma vez.
  table.sort(items, function(a, b)
    if a.is_current ~= b.is_current then return a.is_current end
    if a.is_test ~= b.is_test then return b.is_test end
    return a.mtime > b.mtime
  end)

  return items
end

--- Picker que funciona dentro da coroutine em que o nvim-dap avalia os campos
--- da configuração: dispara `vim.ui.select` e suspende a coroutine até o
--- callback devolver a escolha (mesma técnica do `dap.utils.pick_process`).
local function pick_one(items, prompt, format_item)
  local co, ismain = coroutine.running()
  if co and not ismain then
    vim.ui.select(items, { prompt = prompt, format_item = format_item }, vim.schedule_wrap(function(choice) coroutine.resume(co, choice) end))
    return coroutine.yield()
  end
  -- Fallback raro: fora de coroutine não há como suspender a execução.
  local lines = { prompt }
  for i, item in ipairs(items) do
    table.insert(lines, ('%d: %s'):format(i, format_item(item)))
  end
  local idx = vim.fn.inputlist(lines)
  return items[idx]
end

local function format_assembly(item) return ('%-26s %-9s %-8s %s  %s'):format(item.project, item.tfm, item.config, os.date('%d/%m %H:%M', item.mtime), item.rel) end

-- ===========================================================================
-- `dotnet build` antes do launch (equivalente ao preLaunchTask do VS Code)
-- ===========================================================================

--- Solution na raiz do repo, se houver. Busca rasa de propósito: `.sln`
--- enterrado em subpasta costuma ser exemplo/template, não o build alvo.
local function find_solution(root)
  for name, kind in vim.fs.dir(root, { depth = 2, skip = function(dir) return not skip_dirs[dir] end }) do
    if kind == 'file' and name:match '%.slnx?$' then return vim.fs.normalize(root .. '/' .. name) end
  end
  return nil
end

--- Roda `dotnet build` e devolve true/false. Assíncrono quando chamado de
--- dentro da coroutine do dap (mesmo yield/resume do picker); o callback do
--- `vim.system` roda em fast event context, daí o vim.schedule_wrap.
---@param target string|nil caminho do .csproj/.sln; nil = deixa o dotnet decidir
---@param configuration string|nil Debug/Release, para casar com o assembly escolhido
local function dotnet_build(target, configuration)
  local root = vim.fs.normalize(vim.fn.getcwd())
  local cmd = { 'dotnet', 'build', '--nologo' }
  if target then table.insert(cmd, target) end
  if configuration == 'Debug' or configuration == 'Release' then vim.list_extend(cmd, { '-c', configuration }) end

  vim.notify('dotnet build ' .. (target and vim.fs.basename(target) or '(cwd)') .. '...')

  local co, ismain = coroutine.running()
  local res
  if co and not ismain then
    vim.system(cmd, { cwd = root, text = true }, vim.schedule_wrap(function(out) coroutine.resume(co, out) end))
    res = coroutine.yield()
  else
    res = vim.system(cmd, { cwd = root, text = true }):wait()
  end

  if res.code ~= 0 then
    vim.notify('Build falhou:\n' .. ((res.stdout or '') .. (res.stderr or '')), vim.log.levels.ERROR)
    return false
  end

  vim.notify 'Build ok'
  return true
end

-- `program` e `cwd` são avaliados separadamente e em ordem não determinística,
-- então o resultado (assembly OU abort) é cacheado por alguns segundos: seja
-- qual for avaliado primeiro, escolha e build acontecem uma única vez.
local dll_cache = { value = nil, at = 0 }
local should_build = false

local function reset_launch_state()
  dll_cache = { value = nil, at = 0 }
  should_build = false
end

local function select_dll()
  local dap = require 'dap'

  if dll_cache.value ~= nil and (uv.now() - dll_cache.at) < 30000 then return dll_cache.value end

  -- consome a flag já: ela NÃO pode sobreviver a um launch que falhou, senão
  -- todo <leader>dc seguinte na mesma sessão do Neovim também buildaria
  local build = should_build
  should_build = false

  local function abort()
    dll_cache = { value = dap.ABORT, at = uv.now() }
    return dap.ABORT
  end

  local items = runnable_assemblies()

  -- Nada compilado ainda: só nesse caso o build precisa vir ANTES da escolha.
  if #items == 0 and build then
    if not dotnet_build(find_solution(vim.fs.normalize(vim.fn.getcwd()))) then return abort() end
    items = runnable_assemblies()
    build = false
  end

  local chosen
  if #items == 0 then
    vim.notify('Nenhum assembly executável encontrado em bin/.', vim.log.levels.WARN)
    local input = vim.fn.input('Path to dll: ', vim.fs.normalize(vim.fn.getcwd()) .. '/', 'file')
    chosen = input ~= '' and { path = vim.fs.normalize(input) } or nil
  elseif #items == 1 then
    chosen = items[1]
  else
    chosen = pick_one(items, 'Debug: selecione o assembly', format_assembly)
  end

  if not chosen then return abort() end

  -- Build DEPOIS da escolha: builda só o projeto escolhido (com as dependências
  -- dele), na mesma configuração do assembly, e sem embaralhar a ordem da lista.
  if build and chosen.project_file then
    if not dotnet_build(chosen.project_file, chosen.config) then return abort() end
  end

  -- Última checagem antes de entregar ao adapter: sem isso, um path inválido
  -- só aparece como `Failed command 'configurationDone' : 0x80070002`
  if not uv.fs_stat(chosen.path) then
    vim.notify('Assembly não encontrado no disco: ' .. chosen.path, vim.log.levels.ERROR)
    return abort()
  end

  dll_cache = { value = chosen.path, at = uv.now() }
  return dll_cache.value
end

--- Hook de `before`: só liga a flag. O build em si acontece dentro do
--- select_dll, atrás do cache, para não depender da ordem de expansão.
local function build_first(config)
  if config.request == 'launch' and config.type == 'coreclr' then should_build = true end
  return config
end

return {
  { 'nvim-lua/plenary.nvim', lazy = true },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neotest/nvim-nio',
      'mason-org/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
      'igorlfs/nvim-dap-view',
    },
    -- Basic debugging keymaps (function keys)
    keys = {
      { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
      { '<F1>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
      { '<F2>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
      { '<F3>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
      { '<F7>', function() require('dap-view').toggle() end, desc = 'Debug: Toggle UI' },

      -- LazyVim-style debug keymaps (<leader>d prefix)
      { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Breakpoint Condition' },
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
      { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Run/Continue' },
      { '<leader>da', function() require('dap').continue { before = get_args } end, desc = 'Debug: Run with Args' },
      -- `before` é só transformação de config, então os hooks compõem
      { '<leader>dD', function() require('dap').continue { before = build_first } end, desc = 'Debug: Build + Run' },
      {
        '<leader>dA',
        function()
          require('dap').continue { before = function(c) return get_args(build_first(c)) end }
        end,
        desc = 'Debug: Build + Run with Args',
      },
      { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Debug: Run to Cursor' },
      { '<leader>dg', function() require('dap').goto_() end, desc = 'Debug: Go to Line (No Execute)' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
      { '<leader>dj', function() require('dap').down() end, desc = 'Debug: Down' },
      { '<leader>dk', function() require('dap').up() end, desc = 'Debug: Up' },
      { '<leader>dl', function() require('dap').run_last() end, desc = 'Debug: Run Last' },
      { '<leader>do', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
      { '<leader>dO', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
      { '<leader>dP', function() require('dap').pause() end, desc = 'Debug: Pause' },
      { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Debug: Toggle REPL' },
      { '<leader>ds', function() require('dap').session() end, desc = 'Debug: Session' },
      { '<leader>dt', function() require('dap').terminate() end, desc = 'Debug: Terminate' },
      { '<leader>dw', function() require('dap.ui.widgets').hover() end, desc = 'Debug: Widgets' },
      { '<leader>du', function() require('dap-view').toggle() end, desc = 'Debug: Toggle Debug View' },
    },
    config = function()
      local dap = require 'dap'
      -- Setas como controles de step, ativas apenas durante uma sessão DAP
      local arrow_maps = {
        ['<Down>'] = { dap.step_over, 'Debug: Step Over' },
        ['<Right>'] = { dap.step_into, 'Debug: Step Into' },
        ['<Left>'] = { dap.step_out, 'Debug: Step Out' },
        ['<Up>'] = { dap.continue, 'Debug: Continue' },
      }
      local saved_maps = {}
      local arrows_active = false

      local function enable_arrows()
        if arrows_active then return end
        arrows_active = true
        for lhs, map in pairs(arrow_maps) do
          -- Guarda o mapeamento global que existia antes (se houver)
          saved_maps[lhs] = vim.fn.maparg(lhs, 'n', false, true)
          vim.keymap.set('n', lhs, function() map[1]() end, { desc = map[2] })
        end
      end

      local function disable_arrows()
        if not arrows_active then return end
        arrows_active = false
        for lhs in pairs(arrow_maps) do
          pcall(vim.keymap.del, 'n', lhs)
          local prev = saved_maps[lhs]
          -- Restaura só mapeamentos globais (buffer == 0)
          if prev and not vim.tbl_isempty(prev) and prev.buffer == 0 then vim.fn.mapset('n', false, prev) end
        end
        saved_maps = {}
      end

      dap.listeners.after.event_initialized['arrow_keys'] = enable_arrows
      dap.listeners.before.event_terminated['arrow_keys'] = disable_arrows
      dap.listeners.before.event_exited['arrow_keys'] = disable_arrows
      dap.listeners.before.disconnect['arrow_keys'] = disable_arrows

      -- Zera cache e flag de build em QUALQUER desfecho, não só no sucesso:
      -- um launch que falha nunca emite event_initialized.
      dap.listeners.after.event_initialized['launch_state'] = reset_launch_state
      dap.listeners.before.event_terminated['launch_state'] = reset_launch_state
      dap.listeners.before.event_exited['launch_state'] = reset_launch_state
      dap.listeners.before.disconnect['launch_state'] = reset_launch_state

      vim.fn.sign_define('DapStopped', { text = '󰁕 ', texthl = 'DiagnosticWarn', linehl = 'DapStoppedLine', priority = 20 })
      vim.fn.sign_define('DapBreakpoint', { text = ' ', texthl = 'DiagnosticInfo', priority = 20 })
      vim.fn.sign_define('DapBreakpointCondition', { text = ' ', texthl = 'DiagnosticInfo', priority = 20 })
      vim.fn.sign_define('DapBreakpointRejected', { text = ' ', texthl = 'DiagnosticError', priority = 20 })
      vim.fn.sign_define('DapLogPoint', { text = '.>', texthl = 'DiagnosticInfo', priority = 20 })

      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure you have the debuggers for the langs you want
          -- 'delve',
          'netcoredbg',
        },
      }

      require('dap-view').setup {
        winbar = {
          controls = {
            enabled = true,
            position = 'left',
          },
        },
      }

      -- .NET (C#) debug configuration using netcoredbg
      dap.adapters.coreclr = {
        type = 'executable',
        command = vim.fn.stdpath 'data' .. '/mason/bin/netcoredbg' .. (is_windows and '.cmd' or ''),
        args = { '--interpreter=vscode' },
        options = {
          detached = false, -- This prevents the blank terminal launch issue on Windows
          -- o build roda dentro da expansão da config, então o adapter pode
          -- ficar ocioso um bom tempo antes do primeiro request
          initialize_timeout_sec = 60,
        },
      }

      -- Alias so both 'cs' and 'fsharp' filetype work
      dap.adapters.netcoredbg = dap.adapters.coreclr

      dap.configurations.cs = {
        {
          type = 'coreclr',
          name = 'Launch (netcoredbg)',
          request = 'launch',
          -- Varre os .csproj/.fsproj do repo, lista só os assemblies executáveis
          -- já compilados (qualquer TFM: net8.0, net9.0, net10.0...) e abre um
          -- picker fuzzy com projeto, TFM, configuração e horário do build.
          program = select_dll,
          -- O cwd acompanha o assembly escolhido, para appsettings.json e
          -- arquivos relativos serem resolvidos como no `dotnet run`.
          cwd = function()
            local dll = select_dll()
            if dll == dap.ABORT then return dll end
            return vim.fs.dirname(dll)
          end,
          stopAtEntry = false,
          console = 'internalConsole',
          env = {
            ASPNETCORE_ENVIRONMENT = 'Development',
          },
        },
        {
          type = 'coreclr',
          name = 'Attach to process',
          request = 'attach',
          processId = require('dap.utils').pick_process,
        },
      }

      -- Reuse the same configs for F#
      dap.configurations.fsharp = dap.configurations.cs

      -- Setup dap config by VsCode launch.json file
      local vscode = require 'dap.ext.vscode'
      local json = require 'plenary.json'
      vscode.json_decode = function(str) return vim.json.decode(json.json_strip_comments(str)) end
    end,
  },
}
