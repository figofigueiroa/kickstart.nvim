-- [[ obsidian.nvim ]]
-- Vault notes. Setup is gated on the cwd being the vault; note keymaps are
-- registered on `ObsidianNoteEnter` in lua/config/autocmd.lua.
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
-- local is_vault = vim.fn.getcwd() == (is_windows and vim.fn.expand '~/vault' or vim.fn.expand '~/Documents/notes/vault')

return {
  'obsidian-nvim/obsidian.nvim',
  ft = "markdown",
  lazy = true,
  cmd = "Obsidian",
  event = {
    -- só dispara quando editar um .md dentro de um vault
    "BufReadPre *.md",
    "BufNewFile *.md",
  },
  cond = function()
    local vault = vim.fn.getcwd() .. "/.obsidian"
    return vim.fn.isdirectory(vault) == 1
  end,
  keys = {
    -- grupo principal
    { "<leader>o", group = "obsidian" },

    -- navegação / busca
    { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "follow link" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "backlinks" },
    { "<leader>oo", "<cmd>Obsidian open<cr>", desc = "open in app" },

    -- notas
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "new note" },
    { "<leader>oN", "<cmd>Obsidian new_from_template<cr>", desc = "new from template" },
    { "<leader>oln", "<cmd>Obsidian link_new <cr>", desc = "link to new note", mode = "v" },

    -- busca
    { "<leader>os", "<cmd>Obsidian search<cr>", desc = "search" },
    { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "quick switch" },

    -- tags / links
    { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "tags" },
    { "<leader>ols", "<cmd>Obsidian links<cr>", desc = "links" },

    -- visual selection commands
    { "<leader>oen", "<cmd>Obsidiand extract_note", desc = "extract note", mode = "v" },
    { "<leader>oL", "<cmd>Obsidian link<cr>", desc = "link to note", mode = "v" },
  },
  dependencies = { 'nvim-lua/plenary.nvim' },
  -- enabled = is_vault,
  config = function()
    local cwd = vim.fn.getcwd()
    local vault = is_windows and vim.fn.expand('~/vault'):gsub('/$', '') or vim.fn.expand('~/Documents/notes/vault'):gsub('/$', '')
    if cwd == vault or cwd:sub(1, #vault + 1) == vault .. '/' then
      require('obsidian').setup {
        legacy_commands = false, -- this will be removed in 4.0.0
        workspaces = {
          {
            name = 'notas',
            path = is_windows and '~/vault' or '~/Documents/notes/vault',
          },
        },
      }
    end
  end,
}
