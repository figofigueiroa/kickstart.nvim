vim.pack.add {
	'https://github.com/mistweaverco/kulala.nvim'
}

require('kulala').setup({
	kulala_core = {
		timeout = 0
	}
})

-- Basic debugging keymaps, feel free to change to your liking!
vim.keymap.set('n', '<leader>Rs', function() require('kulala').run() end, { desc = 'Run request' })
vim.keymap.set('n', '<leader>Ra', function() require('kulala').run_all() end, { desc = 'Run all request' })
