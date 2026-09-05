-- [[ todo-comments ]]
-- Highlight todo, notes, etc in comments
vim.pack.add { Gh 'folke/todo-comments.nvim' }
Later(function() require('todo-comments').setup { signs = false } end)
