-- lua/plugins/p5.lua
local function is_p5_project(path)
  path = path or vim.uv.cwd()

  -- Sobe na árvore de diretórios até achar a raiz do projeto
  local root = vim.fs.root(path, { '.p5', 'package.json', 'index.html', '.git' })
  if not root then return false end

  -- 1. Marcador explícito
  if vim.uv.fs_stat(root .. '/.p5') then return true end

  -- 2. p5 baixado localmente
  for _, f in ipairs { 'p5.js', 'p5.min.js', 'libraries/p5.js', 'libraries/p5.min.js', 'p5.json' } do
    if vim.uv.fs_stat(root .. '/' .. f) then return true end
  end

  -- 3. p5 como dependência npm
  local pkg = root .. '/package.json'
  if vim.uv.fs_stat(pkg) then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), '\n'))
    if ok and type(data) == 'table' then
      local deps = vim.tbl_extend('force', data.dependencies or {}, data.devDependencies or {})
      if deps.p5 or deps['@types/p5'] then return true end
    end
  end

  return false
end

return {
  'prjctimg/p5.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  event = 'User P5Project',
  cmd = 'P5',
  init = function()
    local fired = false

    local function check(path)
      if fired or not is_p5_project(path) then return end
      fired = true
      vim.api.nvim_exec_autocmds('User', { pattern = 'P5Project' })
    end

    -- Abriu o nvim direto dentro do projeto (ex: `nvim .`)
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function() check(vim.uv.cwd()) end,
    })

    -- Abriu um arquivo que pertence a um projeto p5
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      pattern = { '*.js', '*.ts', '*.html' },
      callback = function(ev) check(ev.file) end,
    })

    -- Deu :cd para um projeto p5
    vim.api.nvim_create_autocmd('DirChanged', {
      callback = function() check(vim.uv.cwd()) end,
    })
  end,
}
