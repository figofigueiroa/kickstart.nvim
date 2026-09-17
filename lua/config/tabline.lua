local M = {}

local function icon_for(name)
  if _G.MiniIcons then
    local icon = MiniIcons.get('file', name)
    return icon .. ' '
  end
  return ''
end

local function tab_label(tabnr)
  local buflist = vim.fn.tabpagebuflist(tabnr)
  local bufnr = buflist[vim.fn.tabpagewinnr(tabnr)]

  local name = vim.fn.bufname(bufnr)
  name = name ~= '' and vim.fn.fnamemodify(name, ':t') or '[No Name]'

  local modified = false
  for _, b in ipairs(buflist) do
    if vim.bo[b].modified then
      modified = true
      break
    end
  end

  return icon_for(name) .. name:gsub('%%', '%%%%'), modified
end

function M.render()
  local parts = {}
  local current = vim.fn.tabpagenr()

  for i = 1, vim.fn.tabpagenr '$' do
    local hl = (i == current) and '%#TabLineSel#' or '%#TabLine#'
    local label, modified = tab_label(i)

    table.insert(parts, table.concat {
      hl, '%', i, 'T',
      ' ', i, ': ', label,
      modified and ' ●' or '',
      ' %', i, 'X✕%X ',
    })
  end

  table.insert(parts, '%#TabLineFill#%T')
  return table.concat(parts)
end

return M
