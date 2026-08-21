vim.pack.add { 'https://github.com/ThePrimeagen/refactoring.nvim', 'https://github.com/lewis6991/async.nvim' }

require('refactoring').setup()

local map = vim.keymap.set

map({ 'n', 'x' }, '<leader>rs', function() return require('refactoring').select_refactor() end, { desc = 'Select Refactor' })
