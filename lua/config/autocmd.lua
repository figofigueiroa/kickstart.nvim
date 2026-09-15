-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.hl_op()`
--
-- Highlight on yank
local function augroup(name) return vim.api.nvim_create_augroup('figo_' .. name, { clear = true }) end

vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup 'highlight_yank',
  callback = function()
    if vim.fn.has 'nvim-0.13' == 1 then
      vim.hl.hl_op()
    else
      (vim.hl or vim.highlight).on_yank()
    end
  end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup 'checktime',
  callback = function()
    if vim.o.buftype ~= 'nofile' then vim.cmd 'checktime' end
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup 'last_loc',
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then return end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'close_with_q',
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dap-float',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ 'VimResized' }, {
  group = augroup 'resize_splits',
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'man_unlisted',
  pattern = { 'man' },
  callback = function(event) vim.bo[event.buf].buflisted = false end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'wrap_spell',
  pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})
-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = augroup 'json_conceal',
  pattern = { 'json', 'jsonc', 'json5' },
  callback = function() vim.opt_local.conceallevel = 0 end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = augroup 'auto_create_dir',
  callback = function(event)
    if event.match:match '^%w%w+:[\\/][\\/]' then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
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

-- vim.api.nvim_create_autocmd('User', {
--   desc = 'Keymaps do Obsidian para o buffer de nota',
--   pattern = 'ObsidianNoteEnter',
--   group = vim.api.nvim_create_augroup('user-obsidian-note', { clear = true }),
--   callback = function()
--     local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc }) end
--
--     -- map('<leader>oo', '<cmd>Obsidian open<cr>', 'Open in Obsidian app')
--     map({ 'n', 'x' }, '<leader>on', '<cmd>Obsidian new<cr>', 'New note')
--     map({ 'n', 'x' }, '<leader>oq', '<cmd>Obsidian quick_switch<cr>', 'Quick switch')
--     map({ 'n', 'x' }, '<leader>os', '<cmd>Obsidian search<cr>', 'Search in vault')
--     map({ 'n', 'x' }, '<leader>of', '<cmd>Obsidian follow_link<cr>', 'Follow link')
--     map('<leader>ob', '<cmd>Obsidian backlinks<cr>', 'Backlinks')
--     map('<leader>ol', '<cmd>Obsidian links<cr>', 'Links of the note')
--     map('<leader>ot', '<cmd>Obsidian today<cr>', "Today's daily note")
--     map('<leader>oc', '<cmd>Obsidian toggle_checkbox<cr>', 'Toggle checkbox')
--     map('<leader>oT', '<cmd>Obsidian template<cr>', 'Insert template')
--     map('<leader>or', '<cmd>Obsidian rename<cr>', 'Rename note')
--     -- map('<leader>op', '<cmd>Obsidian paste_img<cr>', 'Paste image')
--
--     if not wk_obsidian_group() then
--       -- which-key (VeryLazy) pode carregar depois do primeiro NoteEnter:
--       -- registrar quando chegar, se ainda estivermos numa nota.
--       vim.api.nvim_create_autocmd('User', {
--         pattern = 'VeryLazy',
--         once = true,
--         group = vim.api.nvim_create_augroup('user-obsidian-wk', { clear = true }),
--         callback = function()
--           if vim.b.obsidian_buffer then wk_obsidian_group() end
--         end,
--       })
--     end
--   end,
-- })
