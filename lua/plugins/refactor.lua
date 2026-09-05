vim.pack.add { Gh 'ThePrimeagen/refactoring.nvim', Gh 'lewis6991/async.nvim' }

local map = vim.keymap.set

map({ 'n', 'x' }, '<leader>r', '', { desc = '+refactor' })
map({ 'n', 'x' }, '<leader>rs', function() return require('refactoring').select_refactor() end, { desc = 'Select Refactor' })
map({ 'n', 'x' }, '<leader>ri', function() return require('refactoring').inline_var() end, { desc = 'Inline Variable', expr = true })
map('n', '<leader>rP', function() return require('refactoring.debug').print_loc({ output_location = 'below' }) end, { desc = 'Debug Print Location', expr = true })
map({ 'n', 'x' }, '<leader>rp', function() return require('refactoring.debug').print_var({ output_location = 'below' }) .. 'iw' end, { desc = 'Debug Print Variable', expr = true })
map('n', '<leader>rc', function() return require('refactoring.debug').cleanup({ restore_view = true }) .. 'ag' end, { desc = 'Debug Cleanup', expr = true })
map({ 'n', 'x' }, '<leader>rf', function() return require('refactoring').extract_func() end, { desc = 'Extract Function', expr = true })
map({ 'n', 'x' }, '<leader>rF', function() return require('refactoring').extract_func_to_file() end, { desc = 'Extract Function To File', expr = true })
map({ 'n', 'x' }, '<leader>rx', function() return require('refactoring').extract_var() end, { desc = 'Extract Variable', expr = true })

On_event('InsertEnter', function()
  require('refactoring').setup()
end)

