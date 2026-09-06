-- ftplugin/java.lua
local jdtls = require 'jdtls'

-- Workspace de dados isolado por projeto (baseado no nome do diretório raiz)
local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if not root_dir then
  return
end

local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.stdpath 'data' .. '/site/java/workspace-root/' .. project_name

-- Caminho do mason para o jar principal e a config do sistema operacional
local mason_registry = require 'mason-registry'
local jdtls_pkg = mason_registry.get_package 'jdtls'
local jdtls_path = jdtls_pkg:get_install_path()

local launcher_jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')

local sysname = vim.uv.os_uname().sysname:lower()
local config_dir = jdtls_path .. '/config_' .. (sysname:match 'darwin' and 'mac' or sysname:match 'windows' and 'win' or 'linux')

local config = {
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-jar', launcher_jar,
    '-configuration', config_dir,
    '-data', workspace_dir,
  },
  root_dir = root_dir,

  settings = {
    java = {
      -- suas settings antigas de tinymist/lua_ls não entram aqui, isso é só java
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {
          'org.junit.Assert.*',
          'org.junit.jupiter.api.Assertions.*',
          'org.mockito.Mockito.*',
        },
      },
    },
  },

  -- Habilita capacidades extras (necessário pra funcionalidades como
  -- organizar imports com prompt, extract variable/method, etc)
  init_options = {
    bundles = {}, -- aqui entrariam os bundles do java-debug/java-test se você usar depois
  },

  on_attach = function(client, bufnr)
    jdtls.setup_dap { hotcodereplace = 'auto' }

    -- Seus keymaps normais de LSP (o autocmd LspAttach do lsp.lua já cobre
    -- os genéricos, mas os específicos de java vão aqui)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Java: ' .. desc })
    end
    map('<leader>co', jdtls.organize_imports, '[C]ode [O]rganize imports')
    map('<leader>cev', jdtls.extract_variable, '[C]ode [E]xtract [V]ariable')
    map('<leader>cem', jdtls.extract_method, '[C]ode [E]xtract [M]ethod')
  end,
}

jdtls.start_or_attach(config)
