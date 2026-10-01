return {
  'neogitorg/neogit',
  cmd = 'Neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'esmuellert/codediff.nvim', -- optional
  },
  keys = {
    { '<leader>gg', '<Cmd>Neogit<CR>', desc = 'Neogit' },
  },
  opts = {
    integrations = {
      codediff = true,
      snacks = true,
    },
    -- Verde/vermelho claros (família habamax) para o TEXTO dos diffs; os
    -- fundos o neogit deriva do bg de DiffAdd/DiffDelete (sobrepostos no
    -- autocmd.lua), mas os fg viriam de String/ErrorMsg escurecidos.
    highlight = {
      green = '#87d787',
      bg_green = '#87d787',
      red = '#d78787',
      bg_red = '#d78787',
    },
  },
}
