-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.hl_op()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.hl_op { higroup = 'Visual', timeout = 200 } end,
})

-- Build hooks for plugins after install/update are now declared per-plugin
-- in `lua/plugins/*.lua` via the lazy.nvim `build` field (LuaSnip: guarded
-- `make install_jsregexp`; nvim-treesitter: `:TSUpdate`).

-- [[ CodeCompanion <-> fidget.nvim ]]
-- Mostra um spinner do fidget e liga uma flag global (usada pelo
-- mini.statusline) enquanto o CodeCompanion está processando uma requisição.
local cc_fidget = { handles = {} }
local cc_fidget_group = vim.api.nvim_create_augroup('CodeCompanionFidgetHooks', { clear = true })

vim.api.nvim_create_autocmd('User', {
  desc = 'Inicia o spinner do fidget quando o CodeCompanion começa uma requisição',
  pattern = 'CodeCompanionRequestStarted',
  group = cc_fidget_group,
  callback = function(request)
    local progress = require 'fidget.progress'
    local handle = progress.handle.create {
      title = ' Gerando resposta...',
      lsp_client = { name = 'CodeCompanion' },
    }
    cc_fidget.handles[request.data.id] = handle

    vim.g.codecompanion_processing = true
    vim.cmd 'redrawstatus'
  end,
})

vim.api.nvim_create_autocmd('User', {
  desc = 'Encerra o spinner do fidget quando o CodeCompanion termina a requisição',
  pattern = 'CodeCompanionRequestFinished',
  group = cc_fidget_group,
  callback = function(request)
    local handle = cc_fidget.handles[request.data.id]
    if handle then
      handle.message = 'Concluído'
      handle:finish()
      cc_fidget.handles[request.data.id] = nil
    end

    if vim.tbl_isempty(cc_fidget.handles) then
      vim.g.codecompanion_processing = false
      vim.cmd 'redrawstatus'
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'directory',
  callback = function() vim.bo.bufhidden = 'delete' end,
})

-- [[ Obsidian: keymaps ao entrar em nota ]]
-- O obsidian.nvim emite `User ObsidianNoteEnter` ao entrar num buffer de nota
-- (setup ativo, cwd no vault; o `event = 'BufEnter'` do spec cobre também o
-- buffer inicial). O grupo `<leader>o` é `[O]pencode` no spec global do
-- which-key; em notas ele é sobrescrito buffer-local para `[O]bsidian`.
local function wk_obsidian_group()
  if not package.loaded['which-key'] then return false end
  -- `buffer` é campo do item do spec (não do opts) e resolve para o buffer
  -- atual no parse; assim a entrada vale só para notas e sobrescreve o
  -- `[O]pencode` global.
  require('which-key').add { { '<leader>o', group = '[O]bsidian', mode = 'n', buffer = true } }
  return true
end

vim.api.nvim_create_autocmd('User', {
  desc = 'Keymaps do Obsidian para o buffer de nota',
  pattern = 'ObsidianNoteEnter',
  group = vim.api.nvim_create_augroup('user-obsidian-note', { clear = true }),
  callback = function()
    local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc }) end

    -- map('<leader>oo', '<cmd>Obsidian open<cr>', 'Open in Obsidian app')
    map('<leader>on', '<cmd>Obsidian new<cr>', 'New note')
    map('<leader>oq', '<cmd>Obsidian quick_switch<cr>', 'Quick switch')
    map('<leader>os', '<cmd>Obsidian search<cr>', 'Search in vault')
    map('<leader>of', '<cmd>Obsidian follow_link<cr>', 'Follow link')
    map('<leader>ob', '<cmd>Obsidian backlinks<cr>', 'Backlinks')
    map('<leader>ol', '<cmd>Obsidian links<cr>', 'Links of the note')
    map('<leader>ot', '<cmd>Obsidian today<cr>', "Today's daily note")
    map('<leader>oc', '<cmd>Obsidian toggle_checkbox<cr>', 'Toggle checkbox')
    map('<leader>oT', '<cmd>Obsidian template<cr>', 'Insert template')
    map('<leader>or', '<cmd>Obsidian rename<cr>', 'Rename note')
    -- map('<leader>op', '<cmd>Obsidian paste_img<cr>', 'Paste image')

    if not wk_obsidian_group() then
      -- which-key (VeryLazy) pode carregar depois do primeiro NoteEnter:
      -- registrar quando chegar, se ainda estivermos numa nota.
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        once = true,
        group = vim.api.nvim_create_augroup('user-obsidian-wk', { clear = true }),
        callback = function()
          if vim.b.obsidian_buffer then wk_obsidian_group() end
        end,
      })
    end
  end,
})
