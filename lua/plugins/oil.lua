return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    'JezerM/oil-lsp-diagnostics.nvim',
    dependencies = { 'stevearc/oil.nvim' },
    opts = {},
  },
  { 'malewicz1337/oil-git.nvim', dependencies = { 'stevearc/oil.nvim' } },
}
