-- autopairs
-- https://github.com/windwp/nvim-autopairs

vim.pack.add { Gh 'windwp/nvim-autopairs' }

on_event('InsertEnter', function()
  require('nvim-autopairs').setup {}
end)
