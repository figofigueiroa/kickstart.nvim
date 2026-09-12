local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
if not is_windows then return end

vim.pack.add { Gh 'nvim-lua/plenary.nvim' }
vim.pack.add {
  Gh 'olimorris/codecompanion.nvim',
  Gh 'ravitemer/codecompanion-history.nvim',
  Gh 'cairijun/codecompanion-agentskills.nvim',
}

On_event(
  'VimEnter',
  function()
    require('codecompanion').setup {
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
    }
  end
)

local map = vim.keymap.set

map({ 'n', 'v' }, '<leader>aa', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Action Palette' })
map({ 'n', 'v' }, '<leader>ac', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Toggle Chat' })
map('v', '<leader>as', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Add Selection to Chat' })
map('n', '<leader>af', '<cmd>CodeCompanionChat Changes<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Changed Files' })
map({ 'n', 'v' }, '<leader>ai', ':CodeCompanion ', { noremap = true, silent = false, desc = 'CodeCompanion: Inline Prompt' })
map('n', '<leader>al', '<cmd>CodeCompanionCLI<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Open CLI' })
map(
  { 'n', 'v' },
  '<leader>ax',
  function() return require('codecompanion').cli('#{this}', { focus = false }) end,
  { noremap = true, silent = true, desc = 'CodeCompanion: Add Context to CLI' }
)

vim.cmd [[cab cc CodeCompanion]]
