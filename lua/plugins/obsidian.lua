-- [[ obsidian.nvim ]]
-- Vault notes. Setup is gated on the cwd being the vault; note keymaps are
-- registered on `ObsidianNoteEnter` in lua/config/autocmd.lua.
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

return {
  'obsidian-nvim/obsidian.nvim',
  ft = 'markdown',
  event = 'BufEnter',
  dependencies = { 'nvim-lua/plenary.nvim' },
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
