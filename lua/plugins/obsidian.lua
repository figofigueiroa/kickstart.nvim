-- [[ obsidian.nvim ]]
-- Vault notes. Setup is gated on the cwd being the vault; the keymaps are
-- registered at VimEnter, matching the old behaviour.
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

return {
  'obsidian-nvim/obsidian.nvim',
  event = 'VimEnter',
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
    local map = vim.keymap.set
    map('n', '<leader>on', function() require('obsidian').open() end, { desc = 'Open Obsidian' })
    map('n', '<leader>ch', '<cmd>Obsidian toggle_checkbox<cr>', { buffer = true, desc = 'Toggle checkbox' })
  end,
}
