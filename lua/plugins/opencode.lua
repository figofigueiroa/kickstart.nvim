if vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1 then return {} end

vim.pack.add {
  {
    src = 'https://github.com/nickjvandyke/opencode.nvim',
    version = vim.version.range '*', -- Latest stable release
  },
}


local ocv_cmd = "bash -c 'exec -a opencode ocv --port'"

local snacks_opts = {
  win = {
    position = 'right',
    enter = false,
  },
}

vim.g.opencode_opts = {
  server = {
    start = function() require('snacks.terminal').open(ocv_cmd, snacks_opts) end,
  },
}

-- Recommended/example keymaps
---- toggle separado
vim.keymap.set({ 'n', 't' }, '<C-.>', function() require('snacks.terminal').toggle(ocv_cmd, snacks_opts) end, { desc = 'Toggle OpenCode (ocv)' })
vim.keymap.set({ 'n', 'x' }, '<C-a>', function() require('opencode').ask '@this: ' end, { desc = 'Ask OpenCode…' })
vim.keymap.set({ 'n', 'x' }, '<C-x>', function() require('opencode').select() end, { desc = 'Select OpenCode…' })
vim.keymap.set({ 'n', 'x' }, 'go', function() return require('opencode').operator '@this ' end, { desc = 'Append range to OpenCode', expr = true })
vim.keymap.set({ 'n' }, 'goo', function() return require('opencode').operator '@this ' .. '_' end, { desc = 'Append line to OpenCode', expr = true })
vim.keymap.set({ 'n' }, '<S-C-u>', function() require('opencode').command 'session.half.page.up' end, { desc = 'Scroll OpenCode up' })
vim.keymap.set({ 'n' }, '<S-C-d>', function() require('opencode').command 'session.half.page.down' end, { desc = 'Scroll OpenCode down' })

-- Leader-a keymaps (CodeCompanion equivalents for Linux)
local map = vim.keymap.set

-- Action Palette → Select menu
map({ 'n', 'v' }, '<leader>aa', function() require('opencode').select() end, { noremap = true, silent = true, desc = 'OpenCode: Select' })

-- Toggle Chat → Toggle terminal
map(
  { 'n', 'v' },
  '<leader>ac',
  function() require('snacks.terminal').toggle(ocv_cmd, snacks_opts) end,
  { noremap = true, silent = true, desc = 'OpenCode: Toggle' }
)

-- Add Selection to Chat → Ask with selection
map('v', '<leader>as', function() require('opencode').ask '@this: ' end, { noremap = true, silent = true, desc = 'OpenCode: Ask Selection' })

-- Inline Prompt → Ask with prompt input
map({ 'n', 'v' }, '<leader>ai', function() require('opencode').ask '' end, { noremap = true, silent = false, desc = 'OpenCode: Ask' })

-- Open CLI → Toggle terminal
map('n', '<leader>al', function() require('snacks.terminal').toggle(ocv_cmd, snacks_opts) end, { noremap = true, silent = true, desc = 'OpenCode: Toggle CLI' })

-- Add Context to CLI → Ask with buffer context
map({ 'n', 'v' }, '<leader>ax', function() require('opencode').ask '@this ' end, { noremap = true, silent = true, desc = 'OpenCode: Ask with Context' })
