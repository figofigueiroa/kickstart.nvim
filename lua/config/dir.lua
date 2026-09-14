-- [[ config.dir ]]
--  Statuscolumn com ícones (mini.icons) para buffers de diretório nativos
--  (`:edit <dir>`). Usado por ftplugin/directory.lua.
local M = {}

local ok, icons = pcall(require, 'mini.icons')
local use_icons = ok and vim.g.have_nerd_font ~= false

--- Ícone + highlight para uma entrada do listing (pastas terminam com "/").
--- Sem nerd font ou sem mini.icons: retorna nil (coluna em branco).
---@param name string
---@return string|nil icon
---@return string|nil hl
function M.icon(name)
  if not use_icons or name == nil or name == '' then return nil end

  if name:sub(-1) == '/' then return icons.get('directory', name:sub(1, -2)) end

  return icons.get('file', vim.api.nvim_buf_get_name(0) .. name)
end

--- Item de 'statuscolumn' para a linha atual.
---@return string
function M.statuscol()
  if vim.v.virtnum ~= 0 or vim.v.lnum < 1 then return '  ' end

  local name = vim.api.nvim_buf_get_lines(0, vim.v.lnum - 1, vim.v.lnum, true)[1] or ''
  local icon, hl = M.icon(name)
  if not icon then return '  ' end

  return string.format('%%#%s#%s ', hl, icon)
end

return M
