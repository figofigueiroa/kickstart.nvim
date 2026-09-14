-- lazydev.nvim: Faster LuaLS setup for Neovim config editing.
-- https://github.com/folke/lazydev.nvim
--
-- Instead of indexing the entire runtime on startup, lazydev monitors open
-- Lua buffers and dynamically injects library paths into lua_ls only for
-- modules you actually `require`. This eliminates the slow full-workspace
-- scan and the duplicate-loading bug caused by nvim_get_runtime_file('', true).
return {
  'folke/lazydev.nvim',
  ft = 'lua',
  cmd = 'LazyDev',
  opts = {
    library = {
      -- Load libuv types only when `vim.uv` is referenced in the buffer
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      -- Load snacks.nvim types only when `Snacks` is referenced in the buffer
      { path = 'snacks.nvim', words = { 'Snacks' } },
    },
  },
}
