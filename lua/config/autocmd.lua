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
