-- Autocommands shared across the config (all in the 'custom-config' group)

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.hl_op()`
Config.new_autocmd('TextYankPost', '*', function()
  vim.hl.hl_op { higroup = 'Visual', timeout = 200 }
end, 'Highlight when yanking (copying) text')

-- [[ CodeCompanion <-> fidget.nvim ]]
-- Mostra um spinner do fidget e liga uma flag global (usada pelo
-- mini.statusline) enquanto o CodeCompanion está processando uma requisição.
local cc_fidget = { handles = {} }

Config.new_autocmd('User', 'CodeCompanionRequestStarted', function(request)
  local progress = require 'fidget.progress'
  local handle = progress.handle.create {
    title = ' Gerando resposta...',
    lsp_client = { name = 'CodeCompanion' },
  }
  cc_fidget.handles[request.data.id] = handle

  vim.g.codecompanion_processing = true
  vim.cmd 'redrawstatus'
end, 'Inicia o spinner do fidget quando o CodeCompanion começa uma requisição')

Config.new_autocmd('User', 'CodeCompanionRequestFinished', function(request)
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
end, 'Encerra o spinner do fidget quando o CodeCompanion termina a requisição')
