-- [[ todo-comments ]]
-- Highlight todo, notes, etc in comments
-- VeryLazy (not LazyFile) because the `<leader>st` snacks picker reads its
-- keyword patterns, matching the old deferred setup.
return {
  'folke/todo-comments.nvim',
  event = 'VeryLazy',
  opts = { signs = false },
}
