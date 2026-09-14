-- [[ kulala.nvim ]]
-- REST client for `.http` files. Setup lives here; the keymaps stay in
-- ftplugin/http.lua (they are lazy closures, so kulala is guaranteed
-- loaded by the time they fire).
return {
  'mistweaverco/kulala.nvim',
  ft = 'http',
  opts = {
    kulala_core = {
      timeout = 0,
    },
    max_response_size = 65536, -- increases limit to 64KB
  },
}
