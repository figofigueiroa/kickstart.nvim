-- [[ obsidian.nvim ]]
-- Vault notes. Loads only on vault markdown files; setup is gated on the
-- cwd being the vault. Keymaps are buffer-local, registered on
-- `User ObsidianNoteEnter` (emitido pelo obsidian.nvim ao entrar num
-- buffer de nota com o setup ativo) — fora das notas eles não existem e
-- `<leader>o` continua sendo o grupo `[O]pencode` do spec global.
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
local vault = vim.fn.expand(is_windows and '~/vault' or '~/Documents/notes/vault')

return {
  'obsidian-nvim/obsidian.nvim',
  cmd = 'Obsidian',
  event = {
    'BufReadPre ' .. vault .. '/**.md',
    'BufNewFile ' .. vault .. '/**.md',
  },
  dependencies = { 'nvim-lua/plenary.nvim', 'folke/which-key.nvim' },
  config = function()
    local cwd = vim.fn.getcwd()
    local vault = is_windows and vim.fn.expand('~/vault'):gsub('/$', '') or vim.fn.expand('~/Documents/notes/vault'):gsub('/$', '')
    if cwd == vault or cwd:sub(1, #vault + 1) == vault .. '/' then
      require('obsidian').setup {
        legacy_commands = false, -- this will be removed in 4.0.0
        workspaces = {
          {
            name = 'notas',
            path = is_windows and '~/vault' or '~/Documents/notes/vault',
          },
        },
      }

      -- `buffer = buf` faz cada entrada valer só para a nota atual,
      -- sobrescrevendo o grupo `[O]pencode` global apenas ali.
      local group = vim.api.nvim_create_augroup('obsidian-note-keymaps', { clear = true })
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'ObsidianNoteEnter',
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          require('which-key').add {
            {
              mode = { 'n', 'v' },
              buffer = buf,
              { '<leader>o', group = 'obsidian' },

              -- navegação / busca
              { '<leader>of', '<cmd>Obsidian follow_link<cr>', desc = 'follow link' },
              { '<leader>ob', '<cmd>Obsidian backlinks<cr>', desc = 'backlinks' },
              { '<leader>oo', '<cmd>Obsidian open<cr>', desc = 'open in app' },

              -- notas
              { '<leader>on', '<cmd>Obsidian new<cr>', desc = 'new note' },
              { '<leader>oN', '<cmd>Obsidian new_from_template<cr>', desc = 'new from template' },
              { '<leader>oln', '<cmd>Obsidian link_new<cr>', desc = 'link to new note', mode = 'v' },

              -- busca
              { '<leader>os', '<cmd>Obsidian search<cr>', desc = 'search' },
              { '<leader>oq', '<cmd>Obsidian quick_switch<cr>', desc = 'quick switch' },

              -- tags / links
              { '<leader>ot', '<cmd>Obsidian tags<cr>', desc = 'tags' },
              { '<leader>ols', '<cmd>Obsidian links<cr>', desc = 'links' },

              -- visual selection commands
              { '<leader>oen', '<cmd>Obsidian extract_note<cr>', desc = 'extract note', mode = 'v' },
              { '<leader>oL', '<cmd>Obsidian link<cr>', desc = 'link to note', mode = 'v' },
            },
          }
        end,
      })
    end
  end,
}
