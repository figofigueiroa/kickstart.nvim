vim.pack.add {
  Gh 'zbirenbaum/copilot.lua'
}

on_event('InsertEnter', function()
  require('copilot').setup()
end)
