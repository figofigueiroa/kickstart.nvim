-- [[ mini.nvim modules ]]
--  Individual modules as separate specs for per-module lazy loading.
--  https://github.com/nvim-mini/mini.nvim
--
--  Modules in use: icons, statuscolumn, statusline, jump, diff, sessions, ai,
--  surround, pairs.
--
--  mini.diff is the ONLY owner of git signs / hunk actions
--  (gitsigns.nvim was cut — it computed the same diff twice, and
--  MiniStatusline.section_diff was already reading minidiff_summary anyway).
--
--  mini.sessions is the ONLY owner of sessions (persistence.nvim was cut).

local function is_loaded(name)
  local plugin = require('lazy.core.config').plugins[name]
  return plugin and plugin._.loaded
end

local function on_load(name, fn)
  if is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'LazyLoad',
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

local function ai_whichkey(opts)
  local objects = {
    { ' ', desc = 'whitespace' },
    { '"', desc = '" string' },
    { "'", desc = "' string" },
    { '(', desc = '() block' },
    { ')', desc = '() block with ws' },
    { '<', desc = '<> block' },
    { '>', desc = '<> block with ws' },
    { '?', desc = 'user prompt' },
    { 'U', desc = 'use/call without dot' },
    { '[', desc = '[] block' },
    { ']', desc = '[] block with ws' },
    { '_', desc = 'underscore' },
    { '`', desc = '` string' },
    { 'a', desc = 'argument' },
    { 'b', desc = ')]} block' },
    { 'c', desc = 'class' },
    { 'd', desc = 'digit(s)' },
    { 'e', desc = 'CamelCase / snake_case' },
    { 'f', desc = 'function' },
    { 'g', desc = 'entire file' },
    { 'i', desc = 'indent' },
    { 'o', desc = 'block, conditional, loop' },
    { 'q', desc = 'quote `"\'' },
    { 't', desc = 'tag' },
    { 'u', desc = 'use/call' },
    { '{', desc = '{} block' },
    { '}', desc = '{} with ws' },
  }

  ---@type wk.Spec[]
  local ret = { mode = { 'o', 'x' } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend('force', {}, {
    around = 'a',
    inside = 'i',
    around_next = 'an',
    inside_next = 'in',
    around_last = 'al',
    inside_last = 'il',
  }, opts.mappings or {})
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub('^around_', ''):gsub('^inside_', '')
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == 'i' then desc = desc:gsub(' with ws', '') end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end
  require('which-key').add(ret, { notify = false })
end
return {
  -- ==========================================================
  -- [[ mini.icons ]] — eager, so the nvim-web-devicons mock is
  -- registered before any plugin tries to use it.
  -- ==========================================================
  { 'nvim-mini/mini.extra', version = false, lazy = true },
  {
    'nvim-mini/mini.icons',
    -- lazy = false,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      if vim.g.have_nerd_font then
        require('mini.icons').setup()
        -- Backwards compatibility with plugins that require `nvim-web-devicons`
        MiniIcons.mock_nvim_web_devicons()
      end
    end,
  },

  -- ==========================================================
  -- Statuscolumn + statusline
  -- ==========================================================
  {
    'nvim-mini/mini.statuscolumn',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
  },

  {
    'nvim-mini/mini.statusline',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'nvim-mini/mini.icons' },
    config = function()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      -- Generic "AI assistant is working" indicator.
      -- Set `vim.g.ai_processing` from whichever assistant you keep; the
      -- codecompanion-specific global is still read for compatibility.
      statusline.section_ai = function()
        if not (vim.g.ai_processing or vim.g.codecompanion_processing) then return '' end
        return (vim.g.have_nerd_font and '󱙺 ' or '[AI] ') .. 'thinking'
      end

      -- ==========================================================
      -- Mode colors: insert -> roxo pastel, visual -> amarelo,
      -- v-block -> verde claro (mini links them to the theme's
      -- diff groups by default). mini.statusline (re)creates its
      -- default groups on every ColorScheme with `default = true`,
      -- so these plain sets win, but a colorscheme switch wipes
      -- them — re-applied in the ColorScheme autocmd below.
      -- ==========================================================
      local function define_mode_hl()
        -- fg escuro (bg do habamax) para o bloco ler como preenchimento pastel
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeInsert', { fg = '#1c1c1c', bg = '#c8a8e8' })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeVisual', { fg = '#1c1c1c', bg = '#ffe066' })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeVBlock', { fg = '#1c1c1c', bg = '#87d787' })
        vim.api.nvim_set_hl(0, 'MiniStatuslineModeOther', { fg = '#1c1c1c', bg = '#e39e6f' })
        vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = '#1c1c1c', bg = '#e6daf0' })
      end

      -- Na tabela de modos do mini, `^V` (V-Block) compartilha
      -- `MiniStatuslineModeVisual` com `v`/`V`; dar ao blockwise visual
      -- o seu próprio grupo. Guarda o original ANTES de sobrescrever
      -- (`statusline` é a mesma tabela que `MiniStatusline`).
      local section_mode_orig = statusline.section_mode
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_mode = function(args)
        local mode, mode_hl = section_mode_orig(args)
        if mode == 'V-Block' or mode == 'V-B' then mode_hl = 'MiniStatuslineModeVBlock' end
        return mode, mode_hl
      end

      -- ========================================================
      -- Blocos "flutuantes": cada grupo da linha ganha arcos
      -- (U+E0B6 / U+E0B4) desenhados com a cor do bloco.
      -- ========================================================
      -- Os hl do mini são links para grupos do tema (Cursor, DiffAdd, …),
      -- então as cores dos arcos são resolvidas em runtime e re-derivadas
      -- em ColorScheme (após o create_default_hl do próprio mini).
      local sep_sources = {
        'MiniStatuslineModeNormal',
        'MiniStatuslineModeInsert',
        'MiniStatuslineModeVisual',
        'MiniStatuslineModeVBlock',
        'MiniStatuslineModeReplace',
        'MiniStatuslineModeCommand',
        'MiniStatuslineModeOther',
        'MiniStatuslineDevinfo',
        'MiniStatuslineFilename',
        'MiniStatuslineFileinfo',
        'DiagnosticWarn',
      }

      -- `nvim_get_hl` com `link = false` resolve os links do tema e devolve
      -- as cores como número (`synIDattr` vem devolvendo vazio aqui).
      local function color_of(name, attr)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        if not ok or hl[attr] == nil then return '' end
        return string.format('#%06x', hl[attr])
      end

      local function define_sep_hl()
        for _, src in ipairs(sep_sources) do
          local sep = 'UserMSep' .. src:gsub('^MiniStatusline', '')
          -- Arco usa o BG do bloco como cor; se o tema não resolver, tenta o
          -- FG; se ainda assim não houver cor, o arco fica invisível.
          local fg = color_of(src, 'bg')
          if fg == '' then fg = color_of(src, 'fg') end
          if fg == '' then fg = 'NONE' end
          vim.api.nvim_set_hl(0, sep, { fg = fg, bg = 'none' })
        end
      end

      -- Modos primeiro: define_sep_hl deriva a cor dos arcos do bg dos
      -- grupos de modo, então as cores precisam estar definidas antes.
      define_mode_hl()
      define_sep_hl()

      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('user-statusline-sep', { clear = true }),
        callback = function()
          vim.schedule(function()
            define_mode_hl()
            define_sep_hl()
          end)
        end,
      })

      local sep_left = '\238\130\182' -- U+E0B6: arco esquerdo do bloco
      local sep_right = '\238\130\180' -- U+E0B4: arco direito do bloco

      -- Como `MiniStatusline.combine_groups`, mas grupos vazios não
      -- renderizam (sem arcos órfãos quando a seção truncada some) e cada
      -- bloco ganha arcos com o hl derivado `UserMSep*`.
      local function combine(groups)
        local parts = {}
        for _, group in ipairs(groups) do
          if type(group) == 'string' then
            parts[#parts + 1] = group
          elseif type(group) == 'table' then
            local strings = vim.tbl_filter(function(s) return type(s) == 'string' and s ~= '' end, group.strings or {})
            if #strings > 0 then
              if group.hl == nil then
                parts[#parts + 1] = ' ' .. table.concat(strings, ' ') .. ' '
              else
                -- section_mode pode devolver o hl já formatado no fallback
                -- de modo desconhecido ('%#…#'): normalizar para o nome puro.
                local hl = group.hl:gsub('^%%#', ''):gsub('#$', '')
                local str = table.concat(strings, ' ')
                local sep = 'UserMSep' .. hl:gsub('^MiniStatusline', '')
                if vim.fn.hlexists(sep) == 1 then
                  parts[#parts + 1] = string.format('%%#%s#%s%%#%s# %s %%#%s#%s', sep, sep_left, hl, str, sep, sep_right)
                else
                  parts[#parts + 1] = string.format('%%#%s# %s ', hl, str)
                end
              end
            end
          end
        end
        return table.concat(parts, ' ')
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.config.content.active = function()
        local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
        local git = MiniStatusline.section_git { trunc_width = 40 }
        local diff = MiniStatusline.section_diff { trunc_width = 75 }
        local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
        local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
        local filename = MiniStatusline.section_filename { trunc_width = 140 }
        local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
        local location = MiniStatusline.section_location { trunc_width = 75 }
        local search = MiniStatusline.section_searchcount { trunc_width = 75 }
        local ai = MiniStatusline.section_ai { trunc_width = 75 }

        return combine {
          { hl = mode_hl, strings = { mode } },
          { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
          '%<',
          { hl = 'MiniStatuslineFilename', strings = { filename } },
          '%=',
          { hl = 'DiagnosticWarn', strings = { ai } },
          { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
          { hl = mode_hl, strings = { search, location } },
        }
      end
    end,
  },

  -- ==========================================================
  -- Motions
  -- ==========================================================
  {
    'nvim-mini/mini.jump',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
  },

  -- [[ Better Around/Inside textobjects ]]
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --
  -- FIX: mini.ai and mini.surround used to load on `InsertEnter`, but they are
  -- normal-mode operators. Opening a file and immediately typing `va)` or
  -- `gsaiw)` did nothing until you had entered insert mode at least once.
  -- {
  --   'nvim-mini/mini.ai',
  --   event = 'VeryLazy',
  --   opts = {
  --     -- NOTE: Avoid conflicts with the built-in incremental selection mappings
  --     -- on Neovim >= 0.12 (see `:help treesitter-incremental-selection`)
  --     mappings = {
  --       -- Main textobject prefixes
  --       around = 'a',
  --       inside = 'i',
  --
  --       -- Next/last variants
  --       -- NOTE: This (deliberately) overrides Neovim>=0.12 built-in incremental
  --       -- selection mappings. See `:h MiniAi-default-an-in` for more details.
  --       around_next = 'an',
  --       inside_next = 'in',
  --       around_last = 'al',
  --       inside_last = 'il',
  --
  --       -- Move cursor to corresponding edge of `a` textobject
  --       goto_left = 'g[',
  --       goto_right = 'g]',
  --     },
  --     n_lines = 500,
  --   },
  -- },
  {
    'nvim-mini/mini.ai',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = function()
      local ai = require 'mini.ai'
      local mx = require 'mini.extra'
      return {
        n_lines = 500,
        mappings = {
            around_next = 'aN',  -- ou qualquer outra combinação livre
            inside_next = 'iN',
            around_last = 'aL',
            inside_last = 'iL',
          },
        custom_textobjects = {
          o = ai.gen_spec.treesitter { -- code block
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          },
          -- B = mx.gen_ai_spec.buffer(),
          -- L = mx.gen_ai_spec.line(),
          E = mx.gen_ai_spec.diagnostic("ERROR"),
          W =  mx.gen_ai_spec.diagnostic("WARN"),
          I = mx.gen_ai_spec.indent(),
          f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }, -- function
          c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }, -- class
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
          d = { '%f[%d]%d+' }, -- digits
          e = { -- Word with case
            { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
            '^().*()$',
          },
          -- g = LazyVim.mini.ai_buffer, -- buffer
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call { name_pattern = '[%w_]' }, -- without dot in function name
        },
      }
    end,
    config = function(_, opts)
      require('mini.ai').setup(opts)
      on_load('which-key.nvim', function()
        vim.schedule(function() ai_whichkey(opts) end)
      end)
    end,
  },
  -- [[ Add/delete/replace surroundings (brackets, quotes, etc.) ]]
  --
  -- - gsaiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - gsd'   - [S]urround [D]elete [']quotes
  -- - gsr)'  - [S]urround [R]eplace [)] [']
  {
    'nvim-mini/mini.surround',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      mappings = {
        add = 'gsa',
        delete = 'gsd',
        find = 'gsf',
        find_left = 'gsF',
        highlight = 'gsh',
        replace = 'gsr',

        suffix_last = 'l',
        suffix_next = 'n',
      },
    },
  },

  -- ==========================================================
  -- [[ mini.diff ]] — git signs, hunk textobjects, diff overlay
  -- ==========================================================
  -- {
  --   'nvim-mini/mini.diff',
  --   event = { 'BufReadPre', 'BufNewFile' },
  --   opts = {
  --     view = {
  --       style = 'sign',
  --       signs = {
  --         add = ' ▎',
  --         change = ' ▎',
  --         delete = ' ',
  --       },
  --     },
  --   },
  --   config = function(_, opts)
  --     require('mini.diff').setup(opts)
  --
  --     vim.keymap.set('n', '<leader>go', function() require('mini.diff').toggle_overlay(0) end, { desc = 'Toggle mini.diff overlay' })
  --
  --     Snacks.toggle({
  --       name = 'Mini Diff Signs',
  --       get = function() return vim.g.minidiff_disable ~= true end,
  --       set = function(state)
  --         vim.g.minidiff_disable = not state
  --         if state then
  --           require('mini.diff').enable(0)
  --         else
  --           require('mini.diff').disable(0)
  --         end
  --         vim.defer_fn(function() vim.cmd [[redraw!]] end, 200)
  --       end,
  --     }):map '<leader>uG'
  --   end,
  -- },

  -- ==========================================================
  -- [[ mini.sessions ]] — replaces persistence.nvim
  -- ==========================================================
  -- VeryLazy (not `keys`) so the VimLeavePre write hook is always active.
  {
    'nvim-mini/mini.sessions',
    event = { 'BufReadPre', 'BufNewFile', 'VeryLazy' },
    config = function()
      local sessions = require 'mini.sessions'
      sessions.setup {
        autoread = false,
        -- We write the session ourselves on exit (see the autocmd below) so that
        -- the very first exit in a new directory also creates a session, matching
        -- persistence.nvim's behaviour.
        autowrite = false,
        -- Empty string disables the "local Session.vim in cwd" detection; we only
        -- use global sessions keyed by cwd.
        file = '',
      }

      -- Encode the cwd into a single filename, e.g. /home/figo/dev/api -> %home%figo%dev%api.vim
      local function cwd_session() return (vim.fn.getcwd():gsub('[\\/:]+', '%%')) .. '.vim' end

      local function load_session()
        local name = cwd_session()
        if sessions.detected[name] then
          sessions.read(name)
        else
          vim.notify('No session for ' .. vim.fn.getcwd(), vim.log.levels.INFO)
        end
      end

      vim.keymap.set('n', '<leader>qs', load_session, { desc = 'Load Session for current directory' })
      vim.keymap.set('n', '<leader>qS', function() sessions.select() end, { desc = 'Select Session to load' })
      vim.keymap.set('n', '<leader>qw', function() sessions.write(cwd_session(), { force = true }) end, { desc = 'Write Session for current directory' })
      vim.keymap.set('n', '<leader>ql', function()
        local latest = sessions.get_latest()
        if latest then sessions.read(latest) end
      end, { desc = 'Load last Session' })
      vim.keymap.set('n', '<leader>qd', function()
        vim.g.minisessions_disable = true
        vim.notify('Session saving disabled for this run', vim.log.levels.INFO)
      end, { desc = "Don't save Session on exit" })

      -- Expose the loader so snacks.lua's dashboard can call it.
      _G.LoadCwdSession = load_session

      vim.api.nvim_create_autocmd('VimLeavePre', {
        group = vim.api.nvim_create_augroup('user-session-write', { clear = true }),
        callback = function()
          if vim.g.minisessions_disable then return end
          -- Don't litter session files for `nvim` with nothing open.
          local has_real_buf = false
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= '' then
              has_real_buf = true
              break
            end
          end
          if not has_real_buf then return end
          pcall(sessions.write, cwd_session(), { force = true, verbose = false })
        end,
      })
    end,
  },

  -- ==========================================================
  -- [[ mini.pairs ]] — auto pairs. Genuinely insert-mode, so it stays lazy.
  -- ==========================================================
  {
    'nvim-mini/mini.pairs',
    event = 'InsertEnter',
    opts = {},
  },

  -- REMOVED: mini.animate
  --   The only module in the config that provided zero capability — pure
  --   cosmetics, and the most expensive thing in the redraw path. It was also
  --   already disabled under Neovide. If you miss animated scrolling, snacks is
  --   already installed: flip `scroll = { enabled = true }` in snacks.lua and
  --   use the existing `<leader>uS` toggle.
}
