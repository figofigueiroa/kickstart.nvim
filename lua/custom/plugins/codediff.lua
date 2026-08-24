vim.pack.add{ Gh 'esmuellert/codediff.nvim' }

later(function()
  require('codediff').setup()
end)
