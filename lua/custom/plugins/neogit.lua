vim.pack.add {
  Gh 'NeogitOrg/neogit',
}

later(function()
  require('neogit').setup {}
  vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<cr>', { desc = '[G]it Neo[g]it' })
end)
