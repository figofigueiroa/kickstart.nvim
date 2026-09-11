-- [[ todo-comments.nvim ]]
-- Highlight todo, notes, etc in comments
vim.pack.add { Config.gh 'folke/todo-comments.nvim' }

Config.later(function() require('todo-comments').setup { signs = false } end)
