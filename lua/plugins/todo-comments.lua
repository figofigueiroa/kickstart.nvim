-- [[ todo-comments ]]
-- Highlight todo, notes, etc in comments
-- Real file events (not the lazy.nvim-synthetic LazyFile) so loading also
-- works under lazier.nvim; the `<leader>st` snacks picker reads its keyword
-- patterns.
return {
  'folke/todo-comments.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = { signs = false },
}
