-- [[ Colorscheme: rose-pine ]]
-- You can easily change to a different colorscheme.
-- Change the name of the colorscheme plugin below, and then
-- change the command under that to load whatever the name of that colorscheme is.
--
-- If you want to see what colorschemes are already installed, you can use `:lua Snacks.picker.colorschemes()`.
-- vim.pack.add { gh 'folke/tokyonight.nvim' }
-- ---@diagnostic disable-next-line: missing-fields
-- require('tokyonight').setup {
--   styles = {
--     comments = { italic = false }, -- Disable italics in comments
--   },
-- }
-- vim.pack.add { Gh 'rose-pine/neovim' }
-- require('rose-pine').setup {
--   dim_inactive_windows = true,
--   extend_background_behind_borders = true,
--   styles = {
--     bold = true,
--     italic = false,
--     transparency = true,
--   },
-- }
--
-- -- Load the colorscheme
-- vim.cmd 'colorscheme rose-pine'

vim.pack.add { Gh 'dchinmay2/alabaster.nvim' }

-- Load the colorscheme
vim.g.alabaster_floatborder = true
vim.cmd 'colorscheme alabaster'
