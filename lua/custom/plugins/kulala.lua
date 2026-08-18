vim.pack.add {
	'https://github.com/mistweaverco/kulala.nvim'
}

require('kulala').setup()

-- Basic debugging keymaps, feel free to change to your liking!
vim.keymap.set('n', '<leader>Rs', function() require('kulala').run() end, { desc = 'Run request' })
vim.keymap.set('n', '<leader>Ra', function() require('kulala').run_all() end, { desc = 'Run all request' })
