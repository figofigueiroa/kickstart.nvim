vim.pack.add { Gh 'sudo-tee/opencode.nvim' }

Later(function()
  require('opencode').setup {
    preferred_picker = 'snacks',
    preferred_completion = 'blink',
    default_mode = 'plan',
  }
end)
