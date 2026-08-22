-- lazydev.nvim: Faster LuaLS setup for Neovim config editing.
-- https://github.com/folke/lazydev.nvim
--
-- Instead of indexing the entire runtime on startup, lazydev monitors open
-- Lua buffers and dynamically injects library paths into lua_ls only for
-- modules you actually `require`. This eliminates the slow full-workspace
-- scan and the duplicate-loading bug caused by nvim_get_runtime_file('', true).

vim.pack.add { Gh 'folke/lazydev.nvim' }

-- on_event('FileType lua') não suporta padrão inline no mini.misc,
-- então usamos nvim_create_autocmd diretamente com pattern = 'lua'.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'lua',
  once = true, -- setup só precisa rodar uma vez
  callback = function()
    require('lazydev').setup {
      library = {
        -- Load libuv types only when `vim.uv` is referenced in the buffer
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    }
  end,
})
