-- Ações e statuscolumn com ícones para buffers de diretório nativos (:edit <dir>).
-- Navegação (<CR>, -, R) fica por conta do plugin builtin "dir" do Neovim.

local function entry()
  local line = vim.api.nvim_get_current_line()
  if line == '' then return nil end
  local is_dir = line:sub(-1) == '/'
  local name = is_dir and line:sub(1, -2) or line
  if name == '' then return nil end
  return name, is_dir
end

local function full_path(name)
  -- Nome do buffer termina com "/", então %:p:h é o próprio diretório listado.
  return vim.fn.expand '%:p:h' .. '/' .. name
end

local function reload() require('nvim.dir')._reload() end

local function find_buf(path)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == path then return bufnr end
  end
  return -1
end

local statuscolumn = "%{%v:lua.require'config.dir'.statuscol()%}"
local winbar = '[dir] %.49F'

local function apply_win_opts(win)
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then return end
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'directory' then return end
  -- `vim.wo[win].X = v` e `nvim_set_option_value` sem `scope` definem o valor
  -- local E o global (semântica de `:set`), contaminando as demais janelas;
  -- com `scope = 'local'` só o valor local da janela é definido.
  local function wset(opt, value) vim.api.nvim_set_option_value(opt, value, { win = win, scope = 'local' }) end
  wset('statuscolumn', statuscolumn)
  wset('foldcolumn', '0')
  wset('signcolumn', 'no')
  wset('number', false)
  wset('relativenumber', false)
  wset('winbar', winbar)
end

-- Opções de janela persistem ao trocar de buffer: reverter para os valores
-- globais quando a janela deixa de exibir o diretório.
local function reset_win_opts(win)
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then return end
  if vim.wo[win].winbar ~= winbar and vim.wo[win].statuscolumn ~= statuscolumn then return end
  vim.api.nvim_win_call(win, function() vim.cmd 'setlocal winbar< statuscolumn< signcolumn< number< relativenumber< foldcolumn<' end)
end

apply_win_opts()

vim.api.nvim_create_autocmd('BufWinEnter', {
  buffer = 0,
  callback = function() apply_win_opts() end,
  desc = 'Winopts para janelas que exibem o diretório',
})

vim.api.nvim_create_autocmd('BufWinLeave', {
  buffer = 0,
  callback = function() reset_win_opts() end,
  desc = 'Restaurar winopts globais ao sair do diretório',
})

-- Janelas criadas a partir da janela do dir (split/tab/picker) herdam as
-- opções locais sem que o buffer do dir saia da janela dele (não há
-- BufWinLeave): normalizar, em todo BufWinEnter, qualquer janela com as
-- winopts de dir que exiba um buffer que não seja diretório.
local group = vim.api.nvim_create_augroup('user-dir-winopts', { clear = true })
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) and vim.wo[win].statuscolumn == statuscolumn then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype ~= 'directory' then reset_win_opts(win) end
      end
    end
  end,
  desc = 'Remover winopts de dir de janelas que as herdaram',
})

-- mini.statuscolumn (VeryLazy) faz `vim.o.statuscolumn = …`, que sobrescreve o
-- valor local da janela atual: re-aplicar depois que ele carregar.
if package.loaded['mini.statuscolumn'] == nil then
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    once = true,
    group = group,
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        apply_win_opts(win)
      end
    end,
  })
end

vim.keymap.set('n', 'a', function()
  local dir = vim.fn.fnameescape(vim.fn.expand '%:p:h')
  vim.fn.feedkeys(':edit ' .. dir .. '/', 'n')
end, { buffer = true, desc = 'Edit / new file' })

vim.keymap.set('n', 'm', function()
  local name = entry()
  if not name then return end

  local escaped = vim.fn.shellescape(full_path(name))
  local left = vim.api.nvim_replace_termcodes('<Left>', true, false, true)
  vim.fn.feedkeys(':!mv ' .. escaped .. ' ' .. escaped .. left, 'n')
end, { buffer = true, desc = 'Move / Rename' })

vim.keymap.set('n', 'd', function()
  local input_ok, dir_name = pcall(vim.fn.input, 'Directory name: ')
  if not input_ok or dir_name == '' then return end

  local path = full_path(dir_name)
  if not pcall(vim.fn.mkdir, path, 'p') then
    vim.notify('mkdir failed: ' .. path, vim.log.levels.ERROR)
    return
  end
  reload()
end, { buffer = true, desc = 'New folder' })

vim.keymap.set('n', 'q', function() Snacks.bufdelete() end, { desc = 'Close dir.plugin', buffer = true })

vim.keymap.set('n', 'D', function()
  local name, is_dir = entry()
  if not name then return end

  local path = full_path(name)
  local input_ok, confirm = pcall(vim.fn.input, 'Delete ' .. name .. (is_dir and '/' or '') .. ' ? [y/N] ')
  if not input_ok or confirm:lower() ~= 'y' then return end

  if not is_dir then
    local bufnr = find_buf(path)
    if bufnr ~= -1 then vim.api.nvim_buf_delete(bufnr, { force = true }) end
  end

  -- Symlink para diretório: deleta só o link, não a árvore apontada.
  local symlink = vim.fn.getftype(path) == 'link'
  if vim.fn.delete(path, is_dir and not symlink and 'rf' or '') ~= 0 then
    vim.notify('delete failed: ' .. path, vim.log.levels.ERROR)
    return
  end
  reload()
end, { buffer = true, desc = 'Delete file / folder' })
