-- vim.pack.add {
--   Gh 'zbirenbaum/copilot.lua'
-- }
--
-- On_event('InsertEnter', function()
-- require("copilot").setup {
--   filetypes = {
--     markdown = true, -- overrides default
--     sh = function ()
--       if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
--         -- disable for .env files
--         return false
--       end
--       return true
--     end,
--   },
-- }
-- end)
vim.pack.add {
  Gh 'zbirenbaum/copilot.lua'
}

On_event('InsertEnter', function()
require("copilot").setup {
  filetypes = {
    markdown = true, -- overrides default
    sh = function ()
      if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
        -- disable for .env files
        return false
      end
      return true
    end,
  },
}
end)
