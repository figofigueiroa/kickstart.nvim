-- [[ copilot.lua ]]
vim.pack.add { Config.gh 'zbirenbaum/copilot.lua' }

Config.on_event('InsertEnter', function()
  require('copilot').setup {
    filetypes = {
      markdown = true, -- overrides default
      sh = function()
        if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
          -- disable for .env files
          return false
        end
        return true
      end,
    },
  }
end)
