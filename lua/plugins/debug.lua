-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for .NET (C#/F#),
-- but can be extended to other languages as well.
--
-- Everything loads lazily: the first <F5> / <leader>d* keypress loads
-- nvim-dap and its UI/management stack.

-- Used by `<leader>da` (Run with Args).
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

return {
  { 'nvim-lua/plenary.nvim', lazy = true },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neotest/nvim-nio',
      'mason-org/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
      'igorlfs/nvim-dap-view',
    },
    -- Basic debugging keymaps (function keys)
    keys = {
      { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
      { '<F1>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
      { '<F2>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
      { '<F3>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
      { '<F7>', function() require('dap-view').toggle() end, desc = 'Debug: Toggle UI' },

      -- LazyVim-style debug keymaps (<leader>d prefix)
      { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Breakpoint Condition' },
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
      { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Run/Continue' },
      { '<leader>da', function() require('dap').continue { before = get_args } end, desc = 'Debug: Run with Args' },
      { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Debug: Run to Cursor' },
      { '<leader>dg', function() require('dap').goto_() end, desc = 'Debug: Go to Line (No Execute)' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
      { '<leader>dj', function() require('dap').down() end, desc = 'Debug: Down' },
      { '<leader>dk', function() require('dap').up() end, desc = 'Debug: Up' },
      { '<leader>dl', function() require('dap').run_last() end, desc = 'Debug: Run Last' },
      { '<leader>do', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
      { '<leader>dO', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
      { '<leader>dP', function() require('dap').pause() end, desc = 'Debug: Pause' },
      { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Debug: Toggle REPL' },
      { '<leader>ds', function() require('dap').session() end, desc = 'Debug: Session' },
      { '<leader>dt', function() require('dap').terminate() end, desc = 'Debug: Terminate' },
      { '<leader>dw', function() require('dap.ui.widgets').hover() end, desc = 'Debug: Widgets' },
      { '<leader>du', function() require('dap-view').toggle() end, desc = 'Debug: Toggle Debug View' },
    },
    config = function()
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
          -- Update this to ensure you have the debuggers for the langs you want
          -- 'delve',
          'netcoredbg',
        },
      }

      require('dap-view').setup {
        winbar = {
          controls = {
            enabled = true,
            position = 'left',
          },
        },
      }

      -- .NET (C#) debug configuration using netcoredbg
      dap.adapters.coreclr = {
        type = 'executable',
        command = vim.fn.stdpath 'data' .. '/mason/bin/netcoredbg.cmd',
        args = { '--interpreter=vscode' },
        options = {
          detached = false, -- This prevents the blank terminal launch issue on Windows
        },
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
            dlls = vim.tbl_filter(function(f) return not f:match 'testhost' and not f:match 'Microsoft' and not f:match 'xunit' end, dlls)
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
      vscode.json_decode = function(str) return vim.json.decode(json.json_strip_comments(str)) end
    end,
  },
}
