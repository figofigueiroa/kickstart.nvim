-- -- Ações e statuscolumn com ícones para buffers de diretório nativos (:edit <dir>).
-- -- Navegação (<CR>, -, R) fica por conta do plugin builtin "dir" do Neovim.
--
-- local function entry()
--   local line = vim.api.nvim_get_current_line()
--   if line == '' then return nil end
--   local is_dir = line:sub(-1) == '/'
--   local name = is_dir and line:sub(1, -2) or line
--   if name == '' then return nil end
--   return name, is_dir
-- end
--
-- local function full_path(name)
--   -- Nome do buffer termina com "/", então %:p:h é o próprio diretório listado.
--   return vim.fn.expand '%:p:h' .. '/' .. name
-- end
--
-- local function reload() require('nvim.dir')._reload() end
--
-- local function find_buf(path)
--   for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.api.nvim_buf_get_name(bufnr) == path then return bufnr end
--   end
--   return -1
-- end
--
-- local statuscolumn = "%{%v:lua.require'config.dir'.statuscol()%}"
-- local winbar = '[dir] %.49F'
--
-- local function apply_win_opts(win)
--   win = win or vim.api.nvim_get_current_win()
--   if not vim.api.nvim_win_is_valid(win) then return end
--   if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'directory' then return end
--   -- `vim.wo[win].X = v` e `nvim_set_option_value` sem `scope` definem o valor
--   -- local E o global (semântica de `:set`), contaminando as demais janelas;
--   -- com `scope = 'local'` só o valor local da janela é definido.
--   local function wset(opt, value) vim.api.nvim_set_option_value(opt, value, { win = win, scope = 'local' }) end
--   wset('statuscolumn', statuscolumn)
--   wset('foldcolumn', '0')
--   wset('signcolumn', 'no')
--   wset('number', false)
--   wset('relativenumber', false)
--   wset('winbar', winbar)
-- end
--
-- -- Opções de janela persistem ao trocar de buffer: reverter para os valores
-- -- globais quando a janela deixa de exibir o diretório.
-- local function reset_win_opts(win)
--   win = win or vim.api.nvim_get_current_win()
--   if not vim.api.nvim_win_is_valid(win) then return end
--   if vim.wo[win].winbar ~= winbar and vim.wo[win].statuscolumn ~= statuscolumn then return end
--   vim.api.nvim_win_call(win, function() vim.cmd 'setlocal winbar< statuscolumn< signcolumn< number< relativenumber< foldcolumn<' end)
-- end
--
-- apply_win_opts()
--
-- vim.api.nvim_create_autocmd('BufWinEnter', {
--   buffer = 0,
--   callback = function() apply_win_opts() end,
--   desc = 'Winopts para janelas que exibem o diretório',
-- })
--
-- vim.api.nvim_create_autocmd('BufWinLeave', {
--   buffer = 0,
--   callback = function() reset_win_opts() end,
--   desc = 'Restaurar winopts globais ao sair do diretório',
-- })
--
-- -- Janelas criadas a partir da janela do dir (split/tab/picker) herdam as
-- -- opções locais sem que o buffer do dir saia da janela dele (não há
-- -- BufWinLeave): normalizar, em todo BufWinEnter, qualquer janela com as
-- -- winopts de dir que exiba um buffer que não seja diretório.
-- local group = vim.api.nvim_create_augroup('user-dir-winopts', { clear = true })
-- vim.api.nvim_create_autocmd('BufWinEnter', {
--   group = group,
--   callback = function()
--     for _, win in ipairs(vim.api.nvim_list_wins()) do
--       if vim.api.nvim_win_is_valid(win) and vim.wo[win].statuscolumn == statuscolumn then
--         local buf = vim.api.nvim_win_get_buf(win)
--         if vim.bo[buf].filetype ~= 'directory' then reset_win_opts(win) end
--       end
--     end
--   end,
--   desc = 'Remover winopts de dir de janelas que as herdaram',
-- })
--
-- -- mini.statuscolumn (VeryLazy) faz `vim.o.statuscolumn = …`, que sobrescreve o
-- -- valor local da janela atual: re-aplicar depois que ele carregar.
-- if package.loaded['mini.statuscolumn'] == nil then
--   vim.api.nvim_create_autocmd('User', {
--     pattern = 'VeryLazy',
--     once = true,
--     group = group,
--     callback = function()
--       for _, win in ipairs(vim.api.nvim_list_wins()) do
--         apply_win_opts(win)
--       end
--     end,
--   })
-- end
--
-- vim.keymap.set('n', 'a', function()
--   local dir = vim.fn.fnameescape(vim.fn.expand '%:p:h')
--   vim.fn.feedkeys(':edit ' .. dir .. '/', 'n')
-- end, { buffer = true, desc = 'Edit / new file' })
--
-- vim.keymap.set('n', 'm', function()
--   local name = entry()
--   if not name then return end
--
--   local escaped = vim.fn.shellescape(full_path(name))
--   local left = vim.api.nvim_replace_termcodes('<Left>', true, false, true)
--   vim.fn.feedkeys(':!mv ' .. escaped .. ' ' .. escaped .. left, 'n')
-- end, { buffer = true, desc = 'Move / Rename' })
--
-- vim.keymap.set('n', 'd', function()
--   local input_ok, dir_name = pcall(vim.fn.input, 'Directory name: ')
--   if not input_ok or dir_name == '' then return end
--
--   local path = full_path(dir_name)
--   if not pcall(vim.fn.mkdir, path, 'p') then
--     vim.notify('mkdir failed: ' .. path, vim.log.levels.ERROR)
--     return
--   end
--   reload()
-- end, { buffer = true, desc = 'New folder' })
--
-- vim.keymap.set('n', 'q', function() Snacks.bufdelete() end, { desc = 'Close dir.plugin', buffer = true })
--
-- vim.keymap.set('n', 'D', function()
--   local name, is_dir = entry()
--   if not name then return end
--
--   local path = full_path(name)
--   local input_ok, confirm = pcall(vim.fn.input, 'Delete ' .. name .. (is_dir and '/' or '') .. ' ? [y/N] ')
--   if not input_ok or confirm:lower() ~= 'y' then return end
--
--   if not is_dir then
--     local bufnr = find_buf(path)
--     if bufnr ~= -1 then vim.api.nvim_buf_delete(bufnr, { force = true }) end
--   end
--
--   -- Symlink para diretório: deleta só o link, não a árvore apontada.
--   local symlink = vim.fn.getftype(path) == 'link'
--   if vim.fn.delete(path, is_dir and not symlink and 'rf' or '') ~= 0 then
--     vim.notify('delete failed: ' .. path, vim.log.levels.ERROR)
--     return
--   end
--   reload()
-- end, { buffer = true, desc = 'Delete file / folder' })







-- Ações e statuscolumn com ícones para buffers de diretório nativos (:edit <dir>).
-- Navegação (<CR>, -, R) fica por conta do plugin builtin "dir" do Neovim.

local function parse_line(line)
  if line == '' then return nil end
  local is_dir = line:sub(-1) == '/'
  local name = is_dir and line:sub(1, -2) or line
  if name == '' then return nil end
  return name, is_dir
end

local function entry() return parse_line(vim.api.nvim_get_current_line()) end

-- Entradas entre as linhas `first` e `last` (1-based, inclusivas, em qualquer ordem).
local function entries_in_range(first, last)
  if first > last then first, last = last, first end
  local items = {}
  -- strict_indexing = false: `last` além do fim do buffer é truncado.
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, first - 1, last, false)) do
    local name, is_dir = parse_line(line)
    if name then table.insert(items, { name = name, is_dir = is_dir }) end
  end
  return items
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

-- Posiciona o cursor na linha da listagem que corresponde a `target`.
local function focus_entry(target)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line == target then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
  end
end

-- Foca a linha do primeiro componente de `rel`: "sub/arquivo.txt" → "sub/".
local function focus_rel(rel, is_dir)
  local first, sep = rel:match '^([^/]+)(/?)'
  if first then focus_entry(first .. ((sep ~= '' or is_dir) and '/' or '')) end
end

vim.keymap.set('n', 'a', function()
  local input_ok, name = pcall(vim.fn.input, 'New file (termine com / para pasta): ')
  if not input_ok or name == '' then return end

  -- normalize: no Windows converte "\" em "/"; no Linux "\" é um caractere válido de nome.
  local rel = vim.fs.normalize(name)
  local wants_dir = name:match '[/\\]$' ~= nil
  local path = vim.fs.normalize(full_path(rel))

  -- Cria as pastas intermediárias ("sub/outra/arquivo.txt"), ou a própria pasta.
  local dir_to_make = wants_dir and path or vim.fs.dirname(path)
  if vim.fn.isdirectory(dir_to_make) == 0 and not pcall(vim.fn.mkdir, dir_to_make, 'p') then
    vim.notify('mkdir failed: ' .. dir_to_make, vim.log.levels.ERROR)
    return
  end

  if not wants_dir then
    -- 'wx' = O_CREAT | O_EXCL: falha se o arquivo já existir, em vez de truncá-lo.
    local fd, err, err_name = vim.uv.fs_open(path, 'wx', tonumber('644', 8))
    if not fd then
      if err_name == 'EEXIST' then
        vim.notify('already exists: ' .. path, vim.log.levels.WARN)
      else
        vim.notify('create failed: ' .. path .. ' (' .. tostring(err) .. ')', vim.log.levels.ERROR)
      end
      return
    end
    vim.uv.fs_close(fd)
  end

  reload()
  focus_rel(rel, wants_dir)
end, { buffer = true, desc = 'New file / folder' })

local is_win = vim.fn.has 'win32' == 1

-- Buffers abertos continuam apontando para o caminho antigo depois do rename:
-- atualizar os que apontam para `src` ou para algo dentro dele (pastas).
local function rename_buffers(src, dest)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buftype == '' then
      local bname = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
      local new
      if bname == src then
        new = dest
      elseif bname:sub(1, #src + 1) == src .. '/' then
        new = dest .. bname:sub(#src + 1)
      end

      if new and pcall(vim.api.nvim_buf_set_name, bufnr, new) and not vim.bo[bufnr].modified then
        -- Após set_name o buffer é marcado como "não editado" nesse caminho, e o
        -- próximo :w daria E13 (File exists). `:edit!` relê do disco e limpa isso.
        pcall(vim.api.nvim_buf_call, bufnr, function() vim.cmd 'silent edit!' end)
      end
    end
  end
end

vim.keymap.set('n', 'm', function()
  local name, is_dir = entry()
  if not name then return end

  local input_ok, input = pcall(vim.fn.input, {
    prompt = 'Move / rename (termine com / para mover para dentro): ',
    default = name,
  })
  if not input_ok or input == '' or input == name then return end

  local src = vim.fs.normalize(full_path(name))
  local into_dir = input:match '[/\\]$' ~= nil
  local rel = vim.fs.normalize(input)
  local dest = vim.fs.normalize(full_path(rel))
  if into_dir then dest = vim.fs.joinpath(dest, name) end
  if dest == src then return end

  -- fs_rename sobrescreve o destino sem perguntar (rename(2) no Linux,
  -- MoveFileEx com REPLACE_EXISTING no Windows): checar antes.
  -- Exceção: no Windows (case-insensitive) "foo" → "Foo" "já existe", mas é o próprio arquivo.
  local case_only = is_win and dest:lower() == src:lower()
  if not case_only and vim.uv.fs_lstat(dest) then
    vim.notify('already exists: ' .. dest, vim.log.levels.WARN)
    return
  end

  local parent = vim.fs.dirname(dest)
  if vim.fn.isdirectory(parent) == 0 and not pcall(vim.fn.mkdir, parent, 'p') then
    vim.notify('mkdir failed: ' .. parent, vim.log.levels.ERROR)
    return
  end

  local ok, err, err_name = vim.uv.fs_rename(src, dest)
  if not ok then
    local hint = err_name == 'EXDEV' and ' — destino em outro disco/sistema de arquivos' or ''
    vim.notify('rename failed: ' .. tostring(err) .. hint, vim.log.levels.ERROR)
    return
  end

  rename_buffers(src, dest)
  reload()
  focus_rel(rel, into_dir or is_dir)
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

local MAX_LISTED = 10

local function delete_entries(items)
  if #items == 0 then return end

  -- Resolver os caminhos antes de qualquer efeito colateral (buf_delete etc.).
  for _, item in ipairs(items) do
    item.path = full_path(item.name)
    item.label = item.name .. (item.is_dir and '/' or '')
  end

  local prompt
  if #items == 1 then
    prompt = 'Delete ' .. items[1].label .. ' ? [y/N] '
  else
    local lines = { 'Delete ' .. #items .. ' items:' }
    for i = 1, math.min(#items, MAX_LISTED) do
      table.insert(lines, '  ' .. items[i].label)
    end
    if #items > MAX_LISTED then table.insert(lines, ('  … e mais %d'):format(#items - MAX_LISTED)) end
    table.insert(lines, '? [y/N] ')
    prompt = table.concat(lines, '\n')
  end

  local input_ok, confirm = pcall(vim.fn.input, prompt)
  if not input_ok or confirm:lower() ~= 'y' then return end

  local failed = {}
  for _, item in ipairs(items) do
    if not item.is_dir then
      local bufnr = find_buf(item.path)
      if bufnr ~= -1 then vim.api.nvim_buf_delete(bufnr, { force = true }) end
    end

    -- Symlink para diretório: deleta só o link, não a árvore apontada.
    local symlink = vim.fn.getftype(item.path) == 'link'
    if vim.fn.delete(item.path, item.is_dir and not symlink and 'rf' or '') ~= 0 then
      table.insert(failed, item.path)
    end
  end

  if #failed > 0 then
    vim.notify('delete failed:\n' .. table.concat(failed, '\n'), vim.log.levels.ERROR)
  end
  -- Recarregar mesmo com falhas parciais: o que foi deletado precisa sumir da listagem.
  reload()
end

vim.keymap.set('n', 'D', function()
  -- `3D` deleta a linha atual e as 2 seguintes.
  local lnum = vim.fn.line '.'
  delete_entries(entries_in_range(lnum, lnum + vim.v.count1 - 1))
end, { buffer = true, desc = 'Delete file / folder' })

vim.keymap.set('x', 'D', function()
  -- Dentro do callback ainda estamos no modo visual: as marcas '< e '> só
  -- são atualizadas ao sair dele. `line('v')` é a outra ponta da seleção.
  local first, last = vim.fn.line 'v', vim.fn.line '.'
  -- Sair do visual antes do input(), executando o <Esc> imediatamente ('x').
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  delete_entries(entries_in_range(first, last))
end, { buffer = true, desc = 'Delete selected files / folders' })
