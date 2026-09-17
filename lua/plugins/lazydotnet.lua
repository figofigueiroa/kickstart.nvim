
local has_lazydotnet = vim.fn.executable('lazydotnet') == 1

return {
  'ckob/lazydotnet.nvim',
  ft = { 'cs', 'csharp' },
  cmd = 'LazyDotnet',
  enable = has_lazydotnet,
  init = function()
    -- Toggle the UI in both normal and terminal modes
    vim.keymap.set({ 'n', 't' }, '<leader>ld', '<Cmd>LazyDotnet<CR>', { desc = 'Toggle LazyDotnet' })
  end,
}
