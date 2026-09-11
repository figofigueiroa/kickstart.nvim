-- [[ diffs.nvim ]]
vim.pack.add { Config.gh 'barrettruth/diffs.nvim' }

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
