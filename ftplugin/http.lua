-- Keymaps are lazy closures; kulala.nvim is loaded by the `ft = 'http'`
-- trigger in lua/plugins/kulala.lua (its setup lives there too).
vim.keymap.set('n', '<leader>Rs', function() require('kulala').run() end, { desc = 'Run request' })
vim.keymap.set('n', '<leader>Ra', function() require('kulala').run_all() end, { desc = 'Run all request' })
