-- [[ fidget.nvim ]]
-- Useful status updates for LSP.
vim.pack.add { Config.gh 'j-hui/fidget.nvim' }

Config.later(function() require('fidget').setup {} end)
