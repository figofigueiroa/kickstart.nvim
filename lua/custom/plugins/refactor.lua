vim.pack.add { Gh 'ThePrimeagen/refactoring.nvim', Gh 'lewis6991/async.nvim' }

local map = vim.keymap.set

-- Keymap uses require() lazily — refactoring only loads when the keymap fires.
map({ 'n', 'x' }, '<leader>rs', function() return require('refactoring').select_refactor() end, { desc = 'Select Refactor' })

later(function()
  require('refactoring').setup()
end)
