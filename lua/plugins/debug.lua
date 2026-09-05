-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

vim.pack.add {
  Gh 'mfussenegger/nvim-dap',
  Gh 'nvim-neotest/nvim-nio',
  Gh 'mason-org/mason.nvim',
  Gh 'jay-babu/mason-nvim-dap.nvim',
  Gh 'igorlfs/nvim-dap-view',
}

-- Basic debugging keymaps (function keys)
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F7>', function() require('dap-view').toggle() end, { desc = 'Debug toggle ui' })

-- LazyVim-style debug keymaps (<leader>d prefix)
local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
  local args_str = type(args) == 'table' and table.concat(args, ' ') or args
  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.expand(vim.fn.input('Run with args: ', args_str))
    return require('dap.utils').splitstr(new_args)
  end
  return config
end

local leader_d_keymaps = {
  { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = 'Breakpoint Condition' },
  { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle Breakpoint' },
  { '<leader>dc', function() require('dap').continue() end, desc = 'Run/Continue' },
  { '<leader>da', function() require('dap').continue({ before = get_args }) end, desc = 'Run with Args' },
  { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Run to Cursor' },
  { '<leader>dg', function() require('dap').goto_() end, desc = 'Go to Line (No Execute)' },
  { '<leader>di', function() require('dap').step_into() end, desc = 'Step Into' },
  { '<leader>dj', function() require('dap').down() end, desc = 'Down' },
  { '<leader>dk', function() require('dap').up() end, desc = 'Up' },
  { '<leader>dl', function() require('dap').run_last() end, desc = 'Run Last' },
  { '<leader>do', function() require('dap').step_out() end, desc = 'Step Out' },
  { '<leader>dO', function() require('dap').step_over() end, desc = 'Step Over' },
  { '<leader>dP', function() require('dap').pause() end, desc = 'Pause' },
  { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Toggle REPL' },
  { '<leader>ds', function() require('dap').session() end, desc = 'Session' },
  { '<leader>dt', function() require('dap').terminate() end, desc = 'Terminate' },
  { '<leader>dw', function() require('dap.ui.widgets').hover() end, desc = 'Widgets' },
  { '<leader>du', function() require('dap-view').toggle() end, desc = 'Toggle Debug View' },
}

for _, km in ipairs(leader_d_keymaps) do
  vim.keymap.set('n', km[1], km[2], { desc = 'Debug: ' .. km.desc })
end

Later(function()
  local dap = require 'dap'

  vim.fn.sign_define('DapStopped', { text = '󰁕 ', texthl = 'DiagnosticWarn', linehl = 'DapStoppedLine', priority = 20 })
  vim.fn.sign_define('DapBreakpoint', { text = ' ', texthl = 'DiagnosticInfo', priority = 20 })
  vim.fn.sign_define('DapBreakpointCondition', { text = ' ', texthl = 'DiagnosticInfo', priority = 20 })
  vim.fn.sign_define('DapBreakpointRejected', { text = ' ', texthl = 'DiagnosticError', priority = 20 })
  vim.fn.sign_define('DapLogPoint', { text = '.>', texthl = 'DiagnosticInfo', priority = 20 })

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

  require('dap-view').setup {
    winbar = {
      controls = {
        enabled = true,
        position = "left",
      },
    },
  }

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

  -- Setup dap config by VsCode launch.json file
  local vscode = require 'dap.ext.vscode'
  local json = require 'plenary.json'
  vscode.json_decode = function(str)
    return vim.json.decode(json.json_strip_comments(str))
  end
end)
