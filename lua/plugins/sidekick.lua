-- [[ sidekick.nvim ]]
-- Next-edit-suggestion jumps. Loads on the first <Tab> press.
return {
  'folke/sidekick.nvim',
  keys = {
    {
      '<tab>',
      function()
        if not require('sidekick').nes_jump_or_apply() then return '<Tab>' end
      end,
      expr = true,
      desc = 'Goto/Apply Next Edit Suggestion',
    },
  },
  opts = {
    cli = {
      mux = {
        backend = 'zellij',
        enabled = true,
      },
    },
  },
}
