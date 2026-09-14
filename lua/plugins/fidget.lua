-- [[ fidget.nvim ]]
-- Useful status updates for LSP.
-- Kept eager: ftplugin/cs.lua and the CodeCompanion autocmds in
-- lua/config/autocmd.lua `require` it at any moment.
-- The `opts` field is what makes lazy.nvim call `setup()`; fidget v1
-- registers nothing (not even the LspProgress autocmd) without it.
return { 'j-hui/fidget.nvim', opts = {} }
