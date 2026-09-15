-- [[ obsidian.nvim ]]
-- Vault notes. Setup is gated on the cwd being the vault; note keymaps are
-- registered on `ObsidianNoteEnter` in lua/config/autocmd.lua.
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
-- local is_vault = vim.fn.getcwd() == (is_windows and vim.fn.expand '~/vault' or vim.fn.expand '~/Documents/notes/vault')

return {
  'obsidian-nvim/obsidian.nvim',
  event = 'LazyProject:obsidian',
  keys = {
    { 'n', '<leader>on', '<cmd>ObsidianNew<cr>', desc = 'Nova nota' },
    { 'n', '<leader>of', '<cmd>ObsidianFollowLink<cr>', desc = 'Seguir link' },
    { 'n', '<leader>os', '<cmd>ObsidianSearch<cr>', desc = 'Pesquisar notas' },
    { 'n', '<leader>ot', '<cmd>ObsidianToday<cr>', desc = 'Nota de hoje' },
    { 'n', '<leader>oy', '<cmd>ObsidianYesterday<cr>', desc = 'Nota de ontem' },
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
