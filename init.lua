-- ============================================================
-- SECTION 0: BOOTSTRAP LAZY.NVIM
-- Clone lazy.nvim on first run and add it to the runtimepath.
-- ============================================================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...', 'MoreMsg' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options
-- ============================================================
require 'config.options'

-- ============================================================
-- SECTION 2: KEYMAPS
-- basic keymaps, moved to lua/config/keymaps.lua
-- ============================================================
require 'config.keymaps'

-- ============================================================
-- SECTION 3: AUTOCMDS
-- Highlight on yank, CodeCompanion <-> fidget hooks
-- ============================================================
require 'config.autocmd'

-- ============================================================
-- SECTION 4: PLUGINS
-- lazy.nvim imports every `lua/plugins/*.lua` module as a spec
-- and lazy-loads plugins via the `event`/`keys`/`ft`/`cmd`
-- handlers.
-- ============================================================
require('lazy').setup {
  spec = {

    { 'bwpge/lazy-events.nvim', import = 'lazy-events.import', lazy = false },
    { import = 'plugins' },
  },
  install = { colorscheme = { 'alabaster', 'habamax' } },
  checker = { enabled = false },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
        'netrwPlugin',
      },
    },
  },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
