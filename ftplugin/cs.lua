local async = vim.async
local progress = require("fidget.progress")

-- Utils: encontrar solutions e projects
local function find_dotnet_targets(project_filter)
  local cwd = vim.fn.getcwd()

  local solutions = vim.fs.find(function(name)
    return name:match("%.sln$") ~= nil
  end, { path = cwd, limit = 50, type = "file" })

  local projects = vim.fs.find(function(name)
    return name:match("%.csproj$") ~= nil
  end, { path = cwd, limit = 80, type = "file" })

  local targets = {}

  -- Solutions sempre aparecem (rodar teste via .sln descobre os projetos de teste sozinho)
  for _, sln in ipairs(solutions) do
    table.insert(targets, {
      path = sln,
      display = "󰘐 " .. vim.fn.fnamemodify(sln, ":."),
      kind = "solution",
    })
  end

  for _, proj in ipairs(projects) do
    if not project_filter or project_filter(proj) then
      table.insert(targets, {
        path = proj,
        display = "󰌛 " .. vim.fn.fnamemodify(proj, ":."),
        kind = "project",
      })
    end
  end

  return targets
end

local function select_target(project_filter, callback)
  local targets = find_dotnet_targets(project_filter)

 if #targets == 0 then
    vim.notify("Nenhum .sln/.csproj encontrado (verifique o filtro)", vim.log.levels.WARN)
    return
  end

  if #targets == 1 then
    callback(targets[1].path)
    return
  end

  vim.ui.select(targets, {
    prompt = "Selecione Solution / Project:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then callback(choice.path) end
  end)
end

-- Dedup defensivo: independente da causa (multi-targeting, restore duplicado, etc),
-- nunca deixa passar duas entradas idênticas pra mesma linha
local function dedup_items(items)
  local seen = {}
  local out = {}
  for _, item in ipairs(items) do
    local key = table.concat({ item.filename, item.lnum, item.col, item.text }, "|")
    if not seen[key] then
      seen[key] = true
      table.insert(out, item)
    end
  end
  return out
end

-- Parsers
local function parse_dotnet_build(lines)
  local items = {}
  local build_pat = "^%s*(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+([^:]+):%s*(.+)$"

  for _, line in ipairs(lines) do
    local filename, lnum, col, kind, code, text = line:match(build_pat)
    if filename and filename ~= "" then
      text = text:gsub("%s*%[.-%]%s*", ""):gsub("^%s+", ""):gsub("%s+", " ")
      table.insert(items, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = string.format("%s %s: %s", kind:lower(), code, text),
        type = (kind:lower():find("error") and "E") or "W",
      })
    end
  end

  return dedup_items(items)
end

local function parse_dotnet_test(lines)
  local items = {}
  local current_test = nil
  local current_msg = nil
  local captured = false -- já pegamos o frame relevante deste teste?

  local failed_pat = "^%s*Failed%s+(.+)%s+%["
  local stack_pat = "in%s+(.+):line%s+(%d+)"

  for _, line in ipairs(lines) do
    local test_name = line:match(failed_pat)

    if test_name then
      current_test = test_name:gsub("%s+$", "")
      current_msg = nil
      captured = false -- reseta pro próximo teste
    elseif line:match("^%s*Error Message:%s*$") then
      current_msg = true
    elseif current_msg == true and line:match("%S") then
      current_msg = line:gsub("^%s+", "")
    elseif not captured then
      local file, lnum = line:match(stack_pat)
      if file and lnum then
        local text = current_test
            and string.format("[%s] %s", current_test, current_msg or line)
          or (current_msg or line)

        table.insert(items, {
          filename = file,
          lnum = tonumber(lnum),
          col = 1,
          text = text,
          type = "E",
        })
        captured = true -- ignora os demais frames dessa mesma falha
      end
    end
  end

  return dedup_items(items)
end

-- Execução assíncrona com spinner do fidget (de verdade, agora)
local function run_dotnet(cmd, args, title, parser)
  async.run(function()
    local handle = progress.handle.create({
      title = title,
      message = "Iniciando...",
      lsp_client = { name = "dotnet" },
    })

    -- Checkpoint real: a task suspende aqui e devolve controle ao event loop,
    -- então o fidget consegue animar o spinner normalmente.
    local result = async.await(3, vim.system, { cmd, unpack(args) }, {
      text = true,
      cwd = vim.fn.getcwd(),
    })

    local output = (result.stdout or "") .. "\n" .. (result.stderr or "")
    local lines = vim.split(output, "\n", { trimempty = true })
    local items = parser(lines)

    vim.schedule(function()
      vim.fn.setqflist({}, "r", { -- "r" substitui a lista atual em vez de empilhar novas
        title = title,
        items = items,
      })

      if #items > 0 then
        handle:report({ message = string.format("%d problema(s) encontrado(s)", #items) })
        vim.cmd("copen")
        handle:finish()
        -- vim.notify(string.format("%s → %d problema(s)", title, #items), vim.log.levels.WARN)
      elseif result.code == 0 then
        handle:report({ message = "Sucesso" })
        handle:finish()
        vim.cmd("cclose")
        -- vim.notify(title .. " → sucesso", vim.log.levels.INFO)
      else
        handle:report({ message = "Falhou (sem erros parseáveis)" })
        handle:finish()
        vim.notify(title .. " → falhou", vim.log.levels.ERROR)
      end
    end)
  end)
end

-- Comandos prontos com seleção de target
local function build_selected()
  select_target(nil, function(target) -- sem filtro: qualquer .sln/.csproj
    run_dotnet(
      "dotnet",
      { "build", target, "--nologo", "-clp:NoSummary", "-p:GenerateFullPaths=true" },
      "dotnet build → " .. vim.fn.fnamemodify(target, ":t"),
      parse_dotnet_build
    )
  end)
end

local function test_selected()
  local only_test_projects = function(proj_path)
    return vim.fn.fnamemodify(proj_path, ":t"):lower():find("test", 1, true) ~= nil
  end

  select_target(only_test_projects, function(target)
    run_dotnet(
      "dotnet",
      { "test", target, "--nologo", "--logger", "console;verbosity=detailed", "-p:GenerateFullPaths=true" },
      "dotnet test → " .. vim.fn.fnamemodify(target, ":t"),
      parse_dotnet_test
    )
  end)
end

-- Atalhos
vim.keymap.set("n", "<leader>xb", build_selected, { desc = "Quickfix [B]uild" })
vim.keymap.set("n", "<leader>xt", test_selected, { desc = "Quickfix [T]est" })
