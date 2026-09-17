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
  group = augroup 'directory_bufhidden',
  pattern = 'directory',
  callback = function(event) vim.bo[event.buf].bufhidden = 'delete' end,
})

-- -- [[ Obsidian: keymaps ao entrar em nota ]]
-- -- O obsidian.nvim emite `User ObsidianNoteEnter` ao entrar num buffer de nota
-- -- (setup ativo, cwd no vault; o `event = 'BufEnter'` do spec cobre também o
-- -- buffer inicial). O grupo `<leader>o` é `[O]pencode` no spec global do
-- -- which-key; em notas ele é sobrescrito buffer-local para `[O]bsidian`.
-- local function wk_obsidian_group()
--   if not package.loaded['which-key'] then return false end
--   -- `buffer` é campo do item do spec (não do opts) e resolve para o buffer
--   -- atual no parse; assim a entrada vale só para notas e sobrescreve o
--   -- `[O]pencode` global.
--   require('which-key').add { { '<leader>o', group = '[O]bsidian', mode = 'n', buffer = true } }
--   return true
-- end

-- Grupos de keyword do treesitter + grupos legados (syntax regex)
local keyword_groups = {
  '@keyword',
  '@keyword.coroutine',
  '@keyword.function',
  '@keyword.operator',
  '@keyword.import',
  '@keyword.type',
  '@keyword.modifier',
  '@keyword.repeat',
  '@keyword.return',
  '@keyword.debug',
  '@keyword.exception',
  '@keyword.conditional',
  '@keyword.conditional.ternary',
  '@keyword.directive',
  '@keyword.directive.define',
  'Keyword',
  'Statement',
  'Conditional',
  'Repeat',
  'Exception',
  'Include',
}

-- Definição efetiva do grupo, subindo na hierarquia se não existir
-- (@keyword.return -> @keyword), como o fallback do treesitter faz
local function resolve_hl(name)
  while name do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false, create = false })
    if next(hl) then return hl end
    name = name:match '^(.*)%.[^.]+$'
  end
  return {}
end

-- nvim_set_hl SUBSTITUI o grupo inteiro; isto mescla só o que você passar
local function extend_hl(name, attrs) vim.api.nvim_set_hl(0, name, vim.tbl_deep_extend('force', resolve_hl(name), attrs)) end

local function habamax_overrides()
  -- Fundo transparente, preservando o fg do habamax
  extend_hl('Normal', { bg = 'NONE', ctermbg = 'NONE' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#767676', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'VertSplit', { fg = '#767676', bg = 'NONE' })

  vim.api.nvim_set_hl(0, 'TabLineSel', { link = 'PmenuSel' })
  vim.api.nvim_set_hl(0, 'TabLine', { link = 'StatusLineNC' })
  vim.api.nvim_set_hl(0, 'TabLineFill', { link = 'StatusLineNC' })

  -- Keywords em negrito (gui e cterm)
  for _, group in ipairs(keyword_groups) do
    extend_hl(group, { bold = true, cterm = { bold = true } })
  end
end

if vim.g.colors_name == 'habamax' then habamax_overrides() end

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'habamax',
  group = augroup 'habamax_overrides',
  callback = habamax_overrides,
})
