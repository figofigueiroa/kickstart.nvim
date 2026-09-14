-- [[ Colorscheme: alabaster ]]
-- You can easily change to a different colorscheme:
-- swap the plugin below and the `colorscheme` command in its config.
--
-- If you want to see what colorschemes are already installed, you can use `:lua Snacks.picker.colorschemes()`.
return {
  'dchinmay2/alabaster.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    -- Load the colorscheme
    vim.g.alabaster_floatborder = true
    vim.cmd 'colorscheme alabaster'
  end,
}
