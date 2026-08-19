-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  -- 'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
  -- 'https://github.com/leoluz/nvim-dap-go',
  'https://github.com/igorlfs/nvim-dap-view',
  -- 'https://github.com/theHamsta/nvim-dap-virtual-text'
}

-- Basic debugging keymaps, feel free to change to your liking!
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Breakpoint' })
-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
vim.keymap.set('n', '<F7>', function() require('dap-view').toggle() end, { desc = 'Debug toggle ui' })

local dap = require 'dap'
-- local dapui = require 'nvim-dap-view'

require('mason-nvim-dap').setup {
  -- Makes a best effort to setup the various debuggers with
  -- reasonable debug configurations
  automatic_installation = true,

  -- You can provide additional configuration to the handlers,
  -- see mason-nvim-dap README for more information
  handlers = {},

  -- You'll need to check that you have the required things installed
  -- online, please don't ask me how to install them :)
  ensure_installed = {
    -- Update this to ensure that you have the debuggers for the langs you want
    'delve',
    'netcoredbg'
  },
}

-- -- Dap UI setup
-- -- For more information, see |:help nvim-dap-ui|
-- ---@diagnostic disable-next-line: missing-fields
-- dapui.setup {
--   -- Set icons to characters that are more likely to work in every terminal.
--   --    Feel free to remove or use ones that you like more! :)
--   --    Don't feel like these are good choices.
--   icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
--   ---@diagnostic disable-next-line: missing-fields
--   controls = {
--     icons = {
--       pause = '⏸',
--       play = '▶',
--       step_into = '⏎',
--       step_over = '⏭',
--       step_out = '⏮',
--       step_back = 'b',
--       run_last = '▶▶',
--       terminate = '⏹',
--       disconnect = '⏏',
--     },
--   },
-- }
--
-- Change breakpoint icons
-- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
-- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
-- local breakpoint_icons = vim.g.have_nerd_font
--     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
--   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
-- for type, icon in pairs(breakpoint_icons) do
--   local tp = 'Dap' .. type
--   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
--   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
-- end

-- dap.listeners.after.event_initialized['dapui_config'] = dapui.open
-- dap.listeners.before.event_terminated['dapui_config'] = dapui.close
-- dap.listeners.before.event_exited['dapui_config'] = dapui.close

-- Install golang specific config
-- require('dap-go').setup {
--   delve = {
--     -- On Windows delve must be run attached or it crashes.
--     -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
--     detached = vim.fn.has 'win32' == 0,
--   },
-- },
-- }

-- .NET (C#) debug configuration using netcoredbg
dap.adapters.coreclr = {
  type = 'executable',
  command = vim.fn.stdpath 'data' .. '/mason/bin/netcoredbg',
  args = { '--interpreter=vscode' },
}

-- Alias so both 'cs' and 'fsharp' filetype work
dap.adapters.netcoredbg = dap.adapters.coreclr

dap.configurations.cs = {
  {
    type = 'coreclr',
    name = 'Launch (netcoredbg)',
    request = 'launch',
    -- Finds the .dll built by `dotnet build` automatically.
    -- Falls back to asking the user if it can't find one.
    program = function()
      local cwd = vim.fn.getcwd()
      -- Look for the project dll inside bin/Debug
      local dlls = vim.fn.glob(cwd .. '/bin/Debug/**/*.dll', true, true)
      -- Filter out test runners and other noise
      dlls = vim.tbl_filter(function(f)
        return not f:match 'testhost' and not f:match 'Microsoft' and not f:match 'xunit'
      end, dlls)
      if #dlls == 1 then
        return dlls[1]
      elseif #dlls > 1 then
        return vim.fn.input('Path to dll: ', dlls[1], 'file')
      end
      return vim.fn.input('Path to dll: ', cwd .. '/bin/Debug/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = false,
    console = 'internalConsole',
    env = {
      ASPNETCORE_ENVIRONMENT = 'Development',
    },
  },
  {
    type = 'coreclr',
    name = 'Attach to process',
    request = 'attach',
    processId = require('dap.utils').pick_process,
  },
}

-- Reuse the same configs for F#
dap.configurations.fsharp = dap.configurations.cs
