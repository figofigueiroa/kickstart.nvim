return {
  'folke/sidekick.nvim',
  event = 'VeryLazy', -- precisa estar ativo para gerar NES enquanto você edita
  keys = {
    {
      '<Tab>',
      function()
        if not require('sidekick').nes_jump_or_apply() then return '<Tab>' end
      end,
      expr = true,
      mode = 'n',
      desc = 'Goto/Apply Next Edit Suggestion',
    },
  },
  opts = {
    cli = { mux = { backend = 'zellij', enabled = true } },
  },
}
