---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
function Gh(repo) return 'https://github.com/' .. repo end

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
-- SECTION 3: AUTOCMDS & BUILD HOOKS
-- Highlight on yank, plugin build steps
-- ============================================================
require 'config.autocmd'

-- ============================================================
-- SECTION 4: PLUGIN HELPERS
-- `Later` and `On_event` are scheduling helpers used by the
-- plugin configurations in `lua/plugins/`. They are defined here,
-- before plugins load, so they are available globally.
-- ============================================================
do
  -- mini.misc is required for the `Later`/`On_event` helpers, so it is
  -- installed here rather than in `lua/plugins/mini.lua`.
  vim.pack.add { Gh 'nvim-mini/mini.misc' }
  local misc = require 'mini.misc'
  Later = function(f)
    vim.schedule(function() misc.safely('later', f) end)
  end
  On_event = function(ev, f) misc.safely('event:' .. ev, f) end
end

-- ============================================================
-- SECTION 5: PLUGINS
-- Load all plugins from `lua/plugins/`
-- ============================================================
do
  -- Load all plugins from `lua/plugins/*.lua`
  require 'plugins'
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et






