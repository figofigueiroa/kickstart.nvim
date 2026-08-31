vim.pack.add {
  Gh 'zbirenbaum/copilot.lua'
}

On_event('InsertEnter', function()
  require('copilot').setup()
end)
