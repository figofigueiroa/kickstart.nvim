-- [[ CodeCompanion ]]
-- AI assistant — Windows only. On Linux, opencode.nvim is the AI tool
-- (see lua/plugins/opencode-sudotee.lua).
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

return {
  'olimorris/codecompanion.nvim',
  enabled = is_windows,
  lazy = true,
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'ravitemer/codecompanion-history.nvim',
    'cairijun/codecompanion-agentskills.nvim',
  },
  opts = {
    interactions = {
      cli = {
        agent = 'copilot',
      },
      chat = {
        adapter = 'copilot',
        slash_commands = {
          ['file'] = { opts = { provider = 'snacks' } },
          ['buffer'] = { opts = { provider = 'snacks' } },
          ['help'] = { opts = { provider = 'snacks' } },
          ['symbols'] = { opts = { provider = 'snacks' } },
          ['workspace'] = { opts = { provider = 'snacks' } },
          ['image'] = { opts = { provider = 'snacks' } },
          ['mcp'] = { opts = { provider = 'snacks' } },
        },
      },
    },
    display = {
      action_palette = {
        provider = 'snacks',
      },
    },
    extensions = {
      history = {
        enabled = true,
        opts = {
          dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion_chats.json',
          auto_generate_title = true,
          title_generation_opts = {
            adapter = 'copilot',
          },
        },
      },
      agentskills = {
        opts = {
          paths = {
            { '~/.config/nvim/skills', recursive = true },
          },
        },
      },
    },
  },
  keys = {
    { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'CodeCompanion: Action Palette' },
    { '<leader>ac', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = 'CodeCompanion: Toggle Chat' },
    { '<leader>as', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = 'CodeCompanion: Add Selection to Chat' },
    { '<leader>af', '<cmd>CodeCompanionChat Changes<cr>', mode = 'n', desc = 'CodeCompanion: Changed Files' },
    { '<leader>ai', ':CodeCompanion ', mode = { 'n', 'v' }, silent = false, desc = 'CodeCompanion: Inline Prompt' },
    { '<leader>al', '<cmd>CodeCompanionCLI<cr>', mode = 'n', desc = 'CodeCompanion: Open CLI' },
    {
      '<leader>ax',
      function() return require('codecompanion').cli('#{this}', { focus = false }) end,
      mode = { 'n', 'v' },
      desc = 'CodeCompanion: Add Context to CLI',
    },
  },
  config = function(_, opts)
    require('codecompanion').setup(opts)
    vim.cmd [[cab cc CodeCompanion]]
  end,
}
