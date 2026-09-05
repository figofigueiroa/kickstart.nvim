vim.pack.add {
  Gh 'barrettruth/diffs.nvim',
}
vim.g.diffs = {
  integrations = {
    neogit = true,
    gitsigns = true,
    difftastic = true,
  },

  intra = {
    algorithm = 'vscode',
  },
}

-- Later(function() require('diffs').setup() end)

-- On_event('VimEnter', function()
--   require('diffs').setup()
-- end)
