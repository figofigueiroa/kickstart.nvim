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
return {
  -- ==========================================================
  -- [[ mini.icons ]] — eager, so the nvim-web-devicons mock is
  -- registered before any plugin tries to use it.
  -- ==========================================================
  {
    'nvim-mini/mini.icons',
    lazy = false,
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
    event = 'VeryLazy',
    opts = {},
  },

  {
    'nvim-mini/mini.statusline',
    event = 'VeryLazy',
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

        return MiniStatusline.combine_groups {
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
    event = 'VeryLazy',
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
  {
    'nvim-mini/mini.ai',
    event = 'VeryLazy',
    opts = {
      -- NOTE: Avoid conflicts with the built-in incremental selection mappings
      -- on Neovim >= 0.12 (see `:help treesitter-incremental-selection`)
      mappings = {
        around_next = 'aa',
        inside_next = 'ii',
      },
      n_lines = 500,
    },
  },

  -- [[ Add/delete/replace surroundings (brackets, quotes, etc.) ]]
  --
  -- - gsaiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - gsd'   - [S]urround [D]elete [']quotes
  -- - gsr)'  - [S]urround [R]eplace [)] [']
  {
    'nvim-mini/mini.surround',
    event = 'VeryLazy',
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
  {
    'nvim-mini/mini.diff',
    event = 'VeryLazy',
    opts = {
      view = {
        style = 'sign',
        signs = {
          add = ' ▎',
          change = ' ▎',
          delete = ' ',
        },
      },
    },
    config = function(_, opts)
      require('mini.diff').setup(opts)

      vim.keymap.set('n', '<leader>go', function() require('mini.diff').toggle_overlay(0) end, { desc = 'Toggle mini.diff overlay' })

      Snacks.toggle({
        name = 'Mini Diff Signs',
        get = function() return vim.g.minidiff_disable ~= true end,
        set = function(state)
          vim.g.minidiff_disable = not state
          if state then
            require('mini.diff').enable(0)
          else
            require('mini.diff').disable(0)
          end
          vim.defer_fn(function() vim.cmd [[redraw!]] end, 200)
        end,
      }):map '<leader>uG'
    end,
  },

  -- ==========================================================
  -- [[ mini.sessions ]] — replaces persistence.nvim
  -- ==========================================================
  -- VeryLazy (not `keys`) so the VimLeavePre write hook is always active.
  {
    'nvim-mini/mini.sessions',
    event = 'VeryLazy',
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
