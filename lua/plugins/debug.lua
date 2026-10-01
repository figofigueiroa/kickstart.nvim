-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Only the GENERIC side of DAP lives here: keymaps, arrow keys as step
-- controls during a session, signs and the UI (dap-view).
--
-- The .NET side (adapter coreclr, project/assembly discovery, build before
-- launch and launchSettings.json env) is owned by easy-dotnet
-- (lua/plugins/easy-dotnet.lua): it auto-registers the adapter and its
-- configurations in nvim-dap when a C#/F# buffer is opened, so <F5> just
-- works and opens the project picker. Engine: dncdbg.
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
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-neotest/nvim-nio',
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
      -- Setas como controles de step, ativas apenas durante uma sessão DAP
      local arrow_maps = {
        ['<Down>'] = { dap.step_over, 'Debug: Step Over' },
        ['<Right>'] = { dap.step_into, 'Debug: Step Into' },
        ['<Left>'] = { dap.step_out, 'Debug: Step Out' },
        ['<Up>'] = { dap.continue, 'Debug: Continue' },
      }
      local saved_maps = {}
      local arrows_active = false

      local function enable_arrows()
        if arrows_active then return end
        arrows_active = true
        for lhs, map in pairs(arrow_maps) do
          -- Guarda o mapeamento global que existia antes (se houver)
          saved_maps[lhs] = vim.fn.maparg(lhs, 'n', false, true)
          vim.keymap.set('n', lhs, function() map[1]() end, { desc = map[2] })
        end
      end

      local function disable_arrows()
        if not arrows_active then return end
        arrows_active = false
        for lhs in pairs(arrow_maps) do
          pcall(vim.keymap.del, 'n', lhs)
          local prev = saved_maps[lhs]
          -- Restaura só mapeamentos globais (buffer == 0)
          if prev and not vim.tbl_isempty(prev) and prev.buffer == 0 then vim.fn.mapset('n', false, prev) end
        end
        saved_maps = {}
      end

      dap.listeners.after.event_initialized['arrow_keys'] = enable_arrows
      dap.listeners.before.event_terminated['arrow_keys'] = disable_arrows
      dap.listeners.before.event_exited['arrow_keys'] = disable_arrows
      dap.listeners.before.disconnect['arrow_keys'] = disable_arrows

      vim.fn.sign_define('DapStopped', { text = '󰁕 ', texthl = 'DiagnosticWarn', linehl = 'DapStoppedLine', priority = 20 })
      vim.fn.sign_define('DapBreakpoint', { text = " ", texthl = 'DiagnosticInfo', priority = 20 })
      vim.fn.sign_define('DapBreakpointCondition', { text = " ", texthl = 'DiagnosticInfo', priority = 20 })
      vim.fn.sign_define('DapBreakpointRejected', { text = " ", texthl = 'DiagnosticError', priority = 20 })
      vim.fn.sign_define('DapLogPoint', { text = '.>', texthl = 'DiagnosticInfo', priority = 20 })


      require('dap-view').setup {
        winbar = {
          controls = {
            enabled = true,
            position = 'left',
          },
        },
      }
    end,
  },
}
