-- [[ Snippet Engine + Autocomplete Engine ]]
-- Loaded on first InsertEnter (or with opencode.nvim, whichever comes first)
-- — nothing here is needed before the user starts typing.
return {
  -- `friendly-snippets` contains a variety of premade snippets.
  --    See the README about individual language/framework/plugin snippets:
  --    https://github.com/rafamadriz/friendly-snippets

  -- { 'fang2hou/blink-copilot', event = 'InsertEnter' },

  {
    'L3MON4D3/LuaSnip',
    lazy = true,
    build = function(plugin)
      -- `make install_jsregexp` is unavailable on Windows and requires make.
      if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then vim.fn.system { 'make', '-C', plugin.dir, 'install_jsregexp' } end
    end,
    dependencies = {
      {
        'rafamadriz/friendly-snippets',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load()
          require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snippets' } }
        end,
      },
    },
    opts = {
      history = true,
      delete_check_events = 'TextChanged',
    },
  },

  -- [[ Autocomplete Engine ]]
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'L3MON4D3/LuaSnip',
      'rafamadriz/friendly-snippets',
      'fang2hou/blink-copilot',
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = {
        preset = 'default',

        ['<Tab>'] = {
          'snippet_forward', -- 1. placeholder do LuaSnip
          function() -- 2. aplica a Next Edit Suggestion do copilot-lsp
            if vim.b[vim.api.nvim_get_current_buf()].nes_state then
              require('blink.cmp').hide()
              return require('copilot-lsp.nes').apply_pending_nes()
                and require('copilot-lsp.nes').walk_cursor_end_edit()
            end
          end,
          'fallback', -- 3. Tab normal
        },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = true, auto_show_delay_ms = 250 },
      },

      sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'copilot' },
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100, -- above lsp, for require("...") completions
          },
          copilot = {
            name = 'copilot',
            module = 'blink-copilot',
            score_offset = 100,
            async = true,
          },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See `:help blink-cmp-config-fuzzy` for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },
}
