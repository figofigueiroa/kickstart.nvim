-- Iterate over all Lua files in the plugins directory and load them.
--
-- NOTE: `vim.fs.dir` yields entries in filesystem order, which is NOT stable
-- across machines or after a `git clone`. Plugin files that depend on globals
-- created by other plugin files (e.g. `Snacks.*`) would then load in a random
-- order. Collecting + sorting makes startup deterministic and alphabetical.
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'plugins')

local modules = {}
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    table.insert(modules, (file_name:gsub('%.lua$', '')))
  end
end

table.sort(modules)

for _, module in ipairs(modules) do
  require('plugins.' .. module)
end
