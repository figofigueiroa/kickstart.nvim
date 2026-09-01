vim.pack.add { Gh 'nvim-lua/plenary.nvim' }
vim.pack.add {
  Gh 'olimorris/codecompanion.nvim',
  Gh 'ravitemer/codecompanion-history.nvim',
  Gh 'cairijun/codecompanion-agentskills.nvim',
}

On_event('VimEnter', function()
  require('codecompanion').setup {
    interactions = {
      chat = {
        adapter = 'opencode',
      },
      cli = {
        agent = 'opencode',
        agents = {
          opencode = {
            cmd = 'opencode',
            args = {},
            description = 'OpenCode CLI',
            provider = 'terminal',
          },
        },
      },
    },
    extensions = {
      history = {
        enabled = true, -- defaults to true
        opts = {
          dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion_chats.json',
        },
      },
      agentskills = {
        opts = {
          paths = {
            { '~/.config/nvim/skills', recursive = true }, -- Recursive search
          },
        },
      },
    },
  }
end)

local map = vim.keymap.set

-- Action Palette (lista de ações/prompts disponíveis)
map({ 'n', 'v' }, '<leader>aa', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Action Palette' })

-- Toggle do chat
map({ 'n', 'v' }, '<leader>ac', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Toggle Chat' })

-- Adicionar seleção visual ao chat atual
map('v', '<leader>as', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Add Selection to Chat' })

-- Abrir quickfix com arquivos alterados pelo LLM
map('n', '<leader>af', '<cmd>CodeCompanionChat Changes<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Changed Files' })

-- Inline assistant (edição direta no buffer, pede prompt)
map({ 'n', 'v' }, '<leader>ai', ':CodeCompanion ', { noremap = true, silent = false, desc = 'CodeCompanion: Inline Prompt' })

-- CLI interativo
map('n', '<leader>al', '<cmd>CodeCompanionCLI<cr>', { noremap = true, silent = true, desc = 'CodeCompanion: Open CLI' })

-- Enviar buffer/seleção atual pro CLI como contexto rápido
map(
  { 'n', 'v' },
  '<leader>ax',
  function() return require('codecompanion').cli('#{this}', { focus = false }) end,
  { noremap = true, silent = true, desc = 'CodeCompanion: Add Context to CLI' }
)

-- Expande "cc" em "CodeCompanion" na linha de comando (opcional, mas útil)
vim.cmd [[cab cc CodeCompanion]]

