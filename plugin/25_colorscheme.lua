-- [[ Colorscheme: alabaster ]]
-- To try other installed colorschemes: `:lua Snacks.picker.colorschemes()`
vim.pack.add { Config.gh 'dchinmay2/alabaster.nvim' }

Config.now(function()
  vim.g.alabaster_floatborder = true
  vim.cmd 'colorscheme alabaster'
end)
