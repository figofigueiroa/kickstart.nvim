-- [[ mini.nvim ]]
--  Individual mini modules loaded separately instead of the full library.
vim.pack.add {
  Gh 'nvim-mini/mini.icons',
  Gh 'nvim-mini/mini.ai',
  Gh 'nvim-mini/mini.statuscolumn',
  Gh 'nvim-mini/mini.surround',
  Gh 'nvim-mini/mini.pairs',
  Gh 'nvim-mini/mini.diff',
  Gh 'nvim-mini/mini.align',
  Gh 'nvim-mini/mini.animate',
  Gh 'nvim-mini/mini.statusline',
}

-- If a nerd font is available, load the icons module for pretty icons in various plugins.
if vim.g.have_nerd_font then
  require('mini.icons').setup()
  -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
  MiniIcons.mock_nvim_web_devicons()
end

-- [[ Better Around/Inside textobjects]]
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
--  - ci'  - [C]hange [I]nside [']quote

-- [[ mini.statuscolumn ]]
On_event('VimEnter', function()
  require('mini.statuscolumn').setup()

  -- [[ Simple and easy statusline.]]
  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }

  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end
  -- -- [[ mini.animate ]]
  -- -- Neovim animations for scroll, resize, cursor, etc.
  -- instala o plugin (ajuste conforme seu gerenciamento de vim.pack)

  -- só carrega/configura se não estiver no neovide
  if vim.g.neovide == nil then
    -- don't use animate when scrolling with the mouse
    local mouse_scrolled = false
    for _, scroll in ipairs { 'Up', 'Down' } do
      local key = '<ScrollWheel' .. scroll .. '>'
      vim.keymap.set({ '', 'i' }, key, function()
        mouse_scrolled = true
        return key
      end, { expr = true })
    end

    -- vim.api.nvim_create_autocmd("FileType", {
    --   pattern = "grug-far",
    --   callback = function()
    --     vim.b.minianimate_disable = true
    --   end,
    -- })

    local animate = require 'mini.animate'
    animate.setup {
      resize = {
        timing = animate.gen_timing.linear { duration = 50, unit = 'total' },
      },
      scroll = {
        timing = animate.gen_timing.linear { duration = 150, unit = 'total' },
        subscroll = animate.gen_subscroll.equal {
          predicate = function(total_scroll)
            if mouse_scrolled then
              mouse_scrolled = false
              return false
            end
            return total_scroll > 1
          end,
        },
      },
    }

    -- mapeamento de toggle, sem depender de VeryLazy/keymaps.lua do LazyVim
    Snacks.toggle({
      name = 'Mini Animate',
      get = function() return not vim.g.minianimate_disable end,
      set = function(state) vim.g.minianimate_disable = not state end,
    }):map '<leader>ua'
  end

  -- [[ mini.diff ]]
  -- Git diff visualization
  require('mini.diff').setup {
    view = {
      style = 'sign',
      signs = {
        add = ' ▎',
        change = ' ▎',
        delete = ' ',
      },
    },
  }
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

-- vim.keymap.set('n', '<leader>go', function() require('mini.diff').toggle_overlay(0) end, { desc = 'Toggle mini.diff overlay' })
