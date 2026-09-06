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
vim.pack.add { Gh 'rose-pine/neovim' }
require('rose-pine').setup {
  variant = 'auto', -- auto, main, moon, or dawn
  dark_variant = 'main', -- main, moon, or dawn
  dim_inactive_windows = true,
  extend_background_behind_borders = true,

  enable = {
    terminal = true,
    legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
    migrations = true, -- Handle deprecated options automatically
  },

  styles = {
    bold = true,
    italic = false,
    transparency = false,
  },

  groups = {
    border = 'muted',
    link = 'iris',
    panel = 'surface',

    error = 'love',
    hint = 'iris',
    info = 'foam',
    note = 'pine',
    todo = 'rose',
    warn = 'gold',

    git_add = 'foam',
    git_change = 'rose',
    git_delete = 'love',
    git_dirty = 'rose',
    git_ignore = 'muted',
    git_merge = 'iris',
    git_rename = 'pine',
    git_stage = 'iris',
    git_text = 'rose',
    git_untracked = 'subtle',

    h1 = 'iris',
    h2 = 'foam',
    h3 = 'rose',
    h4 = 'gold',
    h5 = 'pine',
    h6 = 'foam',
  },

  palette = {
    -- Override the builtin palette per variant
    -- moon = {
    --     base = '#18191a',
    --     overlay = '#363738',
    -- },
  },

  -- NOTE: Highlight groups are extended (merged) by default. Disable this
  -- per group via `inherit = false`
  -- highlight_groups = {
  --   Comment = { fg = 'foam' },
  --   StatusLine = { fg = 'love', bg = 'love', blend = 15 },
  --   VertSplit = { fg = 'muted', bg = 'muted' },
  --   Visual = { fg = 'base', bg = 'text', inherit = false },
  -- },

  -- before_highlight = function(group, highlight, palette)
  --   -- Disable all undercurls
  --   if highlight.undercurl then
  --       highlight.undercurl = false
  --   end
  --   --
  --   -- Change palette colour
  --   -- if highlight.fg == palette.pine then
  --   --     highlight.fg = palette.foam
  --   -- end
  -- end,
}

-- Load the colorscheme
vim.cmd 'colorscheme rose-pine'
