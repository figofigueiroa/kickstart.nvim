-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = Gh 'nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  Gh 'nvim-lua/plenary.nvim',
  Gh 'MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

local events = require 'neo-tree.events'

local function on_move(data)
  Snacks.rename.on_rename_file(data.source, data.destination)
end

require('neo-tree').setup {
  event_handlers = {
    { event = events.FILE_MOVED,   handler = on_move },
    { event = events.FILE_RENAMED, handler = on_move },
  },
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}
