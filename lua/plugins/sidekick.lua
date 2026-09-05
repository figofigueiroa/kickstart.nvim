vim.pack.add {
  Gh 'folke/sidekick.nvim',
}

vim.keymap.set('n', '<tab>', function()
  if not require('sidekick').nes_jump_or_apply() then
    return '<Tab>'
  end
end, { expr = true, desc = 'Goto/Apply Next Edit Suggestion' })


On_event('InsertEnter', function()
  require('sidekick').setup {
    cli = {
      mux = {
        backend = 'zellij',
        enabled = true,
      },
    },
  }
end)
