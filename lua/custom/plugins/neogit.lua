vim.pack.add {
  Gh 'NeogitOrg/neogit',
}

-- Later(function()
--   require('neogit').setup {}
--   vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<cr>', { desc = '[G]it Neo[g]it' })
-- end)

On_event('VimEnter', function()
  require('neogit').setup {}
  vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<cr>', { desc = '[G]it Neo[g]it' })
end)
