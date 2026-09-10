-- Keymaps use require() lazily — kulala only loads when a keymap fires.
vim.keymap.set('n', '<leader>Rs', function() require('kulala').run() end, { desc = 'Run request' })
vim.keymap.set('n', '<leader>Ra', function() require('kulala').run_all() end, { desc = 'Run all request' })

require('kulala').setup {
  kulala_core = {
    timeout = 0,
  },
  max_response_size = 65536, -- increases limit to 64KB
}
