-- [[ Better Around/Inside textobjects]]
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
--  - ci'  - [C]hange [I]nside [']quote

-- [[ mini.statuscolumn ]]
On_event('VimEnter', function() require('mini.statuscolumn').setup()

-- [[ Simple and easy statusline.]]
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end
-- -- [[ mini.animate ]]
-- -- Neovim animations for scroll, resize, cursor, etc.
-- require('mini.animate').setup()

-- [[ mini.diff ]]
-- Git diff visualization
require('mini.diff').setup()
end)

-- [[ Add/delete/replace surroundings (brackets, quotes, etc.)]]
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
On_event('InsertEnter', function()

require('mini.ai').setup {
  -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}
  require('mini.surround').setup {
    mappings = {
      add = 'gsa', -- Add surrounding in Normal and Visual modes
      delete = 'gsd', -- Delete surrounding
      find = 'gsf', -- Find surrounding (to the right)
      find_left = 'gsF', -- Find surrounding (to the left)
      highlight = 'gsh', -- Highlight surrounding
      replace = 'gsr', -- Replace surrounding

      suffix_last = 'l', -- Suffix to search with "prev" method
      suffix_next = 'n', -- Suffix to search with "next" method
    },
  }

-- [[ mini.pairs ]]
-- Auto pairs for brackets, quotes, etc.
require('mini.pairs').setup()
end)
