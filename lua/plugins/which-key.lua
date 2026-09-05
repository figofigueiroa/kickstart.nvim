-- [[ which-key.nvim ]]
-- Useful plugin to show you pending keybinds.
vim.pack.add { Gh 'folke/which-key.nvim' }
Later(function()
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>a', group = '[A]i', mode = { 'n', 'v' } },
      { '<leader>b', group = '[B]uffer', mode = { 'n', 'v' } },
      { '<leader>x', group = 'Quickfi[X]', mode = { 'n', 'v' } },
      { '<leader>d', group = '[D]ebugger', mode = { 'n', 'v' } },
      { '<leader>u', group = '[U]i Toggles', mode = { 'n', 'v' } },
      { '<leader>c', group = '[C]ode Actions', mode = { 'n', 'v' } },
      { '<leader>co', desc = '[C]ode [O]rganize Imports' },
      { '<leader>R', group = '[R]est', mode = { 'n', 'v' } },
      { '<leader>r', group = '[R]efactor', mode = { 'n', 'v' } },
      { '<leader>T', group = '[T]erminal', mode = { 'n', 'v' } },
      { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
      { '<leader>gr', group = 'Lsp Actions', mode = { 'n', 'v' } },
      { '<leader>q', group = 'Session Manager', mode = { 'n', 'v' } },
    },
  }
end)
