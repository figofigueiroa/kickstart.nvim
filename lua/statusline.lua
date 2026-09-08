-- ============================================================
-- Statusline nativa do Neovim (sem plugins)
-- Coloque este arquivo em: ~/.config/nvim/lua/statusline.lua
-- E no seu init.lua adicione: require("statusline")
-- ============================================================

local M = {}

-- ------------------------------------------------------------
-- 1) Mapa de modos -> texto + highlight
-- ------------------------------------------------------------
local modes = {
  ["n"]      = { "NORMAL",   "StatuslineNormal" },
  ["no"]     = { "NORMAL",   "StatuslineNormal" },
  ["i"]      = { "INSERT",   "StatuslineInsert" },
  ["ic"]     = { "INSERT",   "StatuslineInsert" },
  ["v"]      = { "VISUAL",   "StatuslineVisual" },
  ["V"]      = { "V-LINE",   "StatuslineVisual" },
  ["\22"]    = { "V-BLOCK",  "StatuslineVisual" }, -- Ctrl-V
  ["R"]      = { "REPLACE",  "StatuslineReplace" },
  ["Rv"]     = { "V-REPLACE",  "StatuslineReplace" },
  ["c"]      = { "COMMAND",  "StatuslineCommand" },
  ["t"]      = { "TERMINAL", "StatuslineTerminal" },
  ["s"]      = { "SELECT",   "StatuslineVisual" },
  ["S"]      = { "S-LINE",   "StatuslineVisual" },
}

function M.mode()
  local m = vim.api.nvim_get_mode().mode
  local entry = modes[m] or { m:upper(), "StatuslineNormal" }
  local label, hl = entry[1], entry[2]
  return string.format("%%#%s# %s %%*", hl, label)
end

-- ------------------------------------------------------------
-- 2) Git branch (lendo .git/HEAD, sem plugin nenhum)
-- ------------------------------------------------------------
local git_branch_cache = { branch = "", dir = "" }

local function get_git_branch()
  local dir = vim.fn.expand("%:p:h")
  if dir == git_branch_cache.dir and git_branch_cache.branch ~= "" then
    return git_branch_cache.branch
  end

  local git_dir = vim.fn.finddir(".git", dir .. ";")
  if git_dir == "" then
    git_branch_cache = { branch = "", dir = dir }
    return ""
  end

  local head_file = git_dir .. "/HEAD"
  local ok, lines = pcall(vim.fn.readfile, head_file)
  if not ok or not lines or #lines == 0 then
    return ""
  end

  local head = lines[1]
  local branch = head:match("ref: refs/heads/(.+)") or head:sub(1, 7) -- fallback: hash curto (detached HEAD)

  git_branch_cache = { branch = branch, dir = dir }
  return branch
end

function M.git()
  local branch = get_git_branch()
  if branch == "" then
    return ""
  end
  return " branch: " .. branch .. " " -- ícone git_branch (Nerd Font)
end

-- ------------------------------------------------------------
-- 3) Indicador de alteração (arquivo modificado)
-- ------------------------------------------------------------
function M.modified()
  if vim.bo.modified then
    return "%#StatuslineModified#  ●%*" -- bolinha indicando "sujo"
  elseif not vim.bo.modifiable or vim.bo.readonly then
    return "  " -- cadeado, arquivo readonly
  end
  return ""
end

-- ------------------------------------------------------------
-- 4) Caminho do arquivo (relativo) + nome
-- ------------------------------------------------------------
function M.filepath()
  local path = vim.fn.expand("%:~:.")
  if path == "" then
    return "[Sem Nome]"
  end
  return "  " .. path
end

-- ------------------------------------------------------------
-- 5) Filetype com ícone básico (sem depender de nvim-web-devicons)
-- ------------------------------------------------------------
local ft_icons = {
  lua = "", python = "", javascript = "", typescript = "",
  go = "", rust = "", sh = "", markdown = "", json = "",
  yaml = "", html = "", css = "", c = "", cpp = "",
  cs = "", dockerfile = "", terraform = "", vim = "",
}

function M.filetype()
  local ft = vim.bo.filetype
  if ft == "" then
    return "sem filetype"
  end
  local icon = ft_icons[ft]
  if icon then
    return icon .. " " .. ft
  end
  return ft
end

-- ------------------------------------------------------------
-- 6) "Sistema" -> aqui interpretado como fileformat (unix/dos/mac)
--    + encoding do buffer
-- ------------------------------------------------------------
function M.system()
  local ff = vim.bo.fileformat   -- unix / dos / mac
  local enc = vim.o.encoding     -- utf-8, etc
  return string.format(" %s[%s]", enc, ff)
end

-- ------------------------------------------------------------
-- 7) Posição do cursor: linha:coluna + porcentagem
-- ------------------------------------------------------------
function M.position()
  return " %l:%c  %p%%"
end

-- ------------------------------------------------------------
-- 8) Highlights (cores) - ajuste os valores hex ao seu colorscheme
-- ------------------------------------------------------------
local function set_highlights()
  local set = vim.api.nvim_set_hl
  set(0, "StatuslineNormal",   { fg = "#1e1e2e", bg = "#89b4fa", bold = true })
  set(0, "StatuslineInsert",   { fg = "#1e1e2e", bg = "#a6e3a1", bold = true })
  set(0, "StatuslineVisual",   { fg = "#1e1e2e", bg = "#f9e2af", bold = true })
  set(0, "StatuslineReplace",  { fg = "#1e1e2e", bg = "#f38ba8", bold = true })
  set(0, "StatuslineCommand",  { fg = "#1e1e2e", bg = "#cba6f7", bold = true })
  set(0, "StatuslineTerminal", { fg = "#1e1e2e", bg = "#94e2d5", bold = true })
  set(0, "StatuslineModified", { fg = "#f38ba8", bold = true })
end

-- ------------------------------------------------------------
-- 9) Monta a statusline final
-- ------------------------------------------------------------
-- buftypes onde não faz sentido mostrar a statusline completa
local ignored_buftypes = {
  nofile = true,
  quickfix = true,
  prompt = true,
  help = false, -- mude pra true se quiser ignorar help também
}

function M.active()
  if ignored_buftypes[vim.bo.buftype] then
    return M.inactive()
  end

  return table.concat({
    M.mode(),
    M.git(),
    M.modified(),
    M.filepath(),
    "%=",                 -- separador: empurra o resto pra direita
    M.filetype(),
    M.system(),
    M.position(),
  })
end

function M.inactive()
  return "  %f"
end

-- ------------------------------------------------------------
-- 10) Setup: aplica highlights e liga a statusline via autocmd
-- ------------------------------------------------------------
function M.setup()
  set_highlights()
  vim.o.laststatus = 2 -- 2 = statusline sempre visível em toda janela ativa
                        -- (use 3 se preferir UMA statusline global pro nvim inteiro)

  vim.api.nvim_create_augroup("CustomStatusline", { clear = true })

  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "ModeChanged", "VimResized" }, {
    group = "CustomStatusline",
    callback = function()
      vim.wo.statusline = "%!v:lua.require'statusline'.active()"
    end,
  })

  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    group = "CustomStatusline",
    callback = function()
      vim.wo.statusline = "%!v:lua.require'statusline'.inactive()"
    end,
  })

  -- recarrega highlights quando o colorscheme mudar
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "CustomStatusline",
    callback = set_highlights,
  })
end

return M
