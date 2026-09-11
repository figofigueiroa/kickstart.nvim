-- [[ neogit ]]
vim.pack.add { Config.gh 'NeogitOrg/neogit' }

Config.on_event('VimEnter', function()
  require('neogit').setup {}
  vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<cr>', { desc = '[G]it Neo[g]it' })
end)
