vim.pack.add {
  Gh 'mistweaverco/kulala.nvim'
}

-- Keymaps use require() lazily — kulala only loads when a keymap fires.
vim.keymap.set('n', '<leader>Rs', function() require('kulala').run() end, { desc = 'Run request' })
vim.keymap.set('n', '<leader>Ra', function() require('kulala').run_all() end, { desc = 'Run all request' })

later(function()
  require('kulala').setup({
    kulala_core = {
      timeout = 0
    }
  })
end)
