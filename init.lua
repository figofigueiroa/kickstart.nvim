-- ============================================================
-- SECTION 0: BOOTSTRAP LAZIER.NVIM
-- Clone lazier.nvim on first run and add it to the runtimepath.
-- lazier.nvim wraps lazy.nvim (specs/lockfile/UI stay the same)
-- and bootstraps lazy.nvim itself on the usual data path.
-- ============================================================
local lazierpath = vim.fn.stdpath 'data' .. '/lazier/lazier.nvim'
if not (vim.uv or vim.loop).fs_stat(lazierpath) then
  local lazyrepo = 'https://github.com/jake-stewart/lazier.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable-v2', lazyrepo, lazierpath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazier.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...', 'MoreMsg' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazierpath)

-- ============================================================
-- SECTION 1: CONFIG
-- options + autocmds run before the first frame (lazier.before);
-- keymaps run after it (lazier.after).
-- ============================================================

-- ============================================================
-- SECTION 2: PLUGINS
-- lazier.nvim imports every `lua/plugins/*.lua` module as a spec
-- and lazy-loads plugins via the `event`/`keys`/`ft`/`cmd`
-- handlers.
-- ============================================================
require('lazier').setup('plugins', {
  lazier = {
    -- specs stay fully explicit: no keymap/autocmd codegen from profile runs
    generate_lazy_mappings = false,
    before = function()
      require 'config.options'
      require 'config.autocmd'
    end,
    after = function() require 'config.keymaps' end,
  },
  install = { colorscheme = { 'habamax' } },
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
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
