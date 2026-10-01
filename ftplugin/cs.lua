-- Atalhos .NET no buffer: build/teste via easy-dotnet
-- (lua/plugins/easy-dotnet.lua). O resto do tooling (Roslyn LSP, test
-- runner, debug, pacotes) o plugin registra sozinho ao carregar em
-- arquivos .cs. O require é feito dentro do callback para não depender da
-- ordem em que o lazy.nvim carrega o plugin em relação a este ftplugin.
vim.keymap.set('n', '<leader>xb', function() require('easy-dotnet').build_quickfix() end, { desc = 'Quickfix [B]uild' })
vim.keymap.set('n', '<leader>xt', function() require('easy-dotnet').test() end, { desc = 'Quickfix [T]est' })
