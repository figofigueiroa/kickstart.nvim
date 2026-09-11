-- [[ Snippet Engine + Autocomplete Engine ]]
-- Loaded after startup — nothing here is needed before the user starts typing.

-- NOTE: You can also specify plugin using a version range for its git tag.
--  See `:help vim.version.range()` for more info
vim.pack.add {
  { src = Config.gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' },
  Config.gh 'rafamadriz/friendly-snippets',
  { src = Config.gh 'saghen/blink.cmp', version = vim.version.range '1.*' },
}

-- `friendly-snippets` contains a variety of premade snippets.
--    See the README about individual language/framework/plugin snippets:
--    https://github.com/rafamadriz/friendly-snippets
Config.on_event('InsertEnter', function()
  require('luasnip').setup {}
  require('luasnip.loaders.from_vscode').lazy_load()
end)

Config.later(function()
  require('blink.cmp').setup {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   `<c-y>` to accept ([y]es) the completion.
      -- 'super-tab' for tab to accept, 'enter' for enter to accept, 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'default',
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lazydev', 'lsp', 'path', 'snippets' },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100, -- above lsp, for require("...") completions
        },
      },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    -- By default, we use the Lua implementation instead.
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end)

-- Build LuaSnip's `jsregexp` after install/update
Config.on_packchanged('LuaSnip', { 'install', 'update' }, function(data)
  if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
    local result = vim.system({ 'make', 'install_jsregexp' }, { cwd = data.path }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for LuaSnip:\n%s'):format(output), vim.log.levels.ERROR)
    end
  end
end, 'Build LuaSnip jsregexp')
