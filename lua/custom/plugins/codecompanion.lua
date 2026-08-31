vim.pack.add { 'https://www.github.com/nvim-lua/plenary.nvim' }
vim.pack.add { {
  src = 'https://www.github.com/olimorris/codecompanion.nvim',
  version = vim.version.range '^19.0.0',
} }

On_event('VimEnter', function()
  require('codecompanion').setup {
    strategies = {
      chat = {
        adapter = 'opencode',
      },
    },
    display = {
      action_palette = {
        provider = 'snacks', -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
      },
    },
  }
end)
