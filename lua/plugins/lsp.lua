-- [[ LSP Configuration ]]
--
-- This file is the SINGLE owner of every LSP keymap. snacks.lua used to
-- register a competing `LspAttach` augroup; those maps now live here so there
-- is exactly one place to look when a keybinding misbehaves.
--
-- Neovim >= 0.11 already ships these defaults, so they are deliberately NOT
-- redefined below (see `:help lsp-defaults`):
--   grn  rename            gra  code action        grr  references
--   gri  implementation    grt  type definition    gO   document symbols
--   <C-s> (insert) signature help
-- The maps below either override a default with a Snacks picker (nicer UI) or
-- add something Neovim has no default for.

--  This function gets run when an LSP attaches to a particular buffer.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    -- FIX: this used to be declared ~50 lines lower in the callback. Because
    -- `local` scope in Lua only starts at the declaration, the `vtsls` branch
    -- above it was reading the *global* `client` (always nil) and every
    -- TypeScript keymap silently never got registered.
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- ========================================================
    -- Navigation (Snacks pickers instead of the native handlers)
    -- ========================================================
    map('gd', function() Snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')
    map('gr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
    map('gI', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
    map('gy', function() Snacks.picker.lsp_type_definitions() end, 'Goto T[y]pe Definition')
    map('gai', function() Snacks.picker.lsp_incoming_calls() end, 'C[a]lls [I]ncoming')
    map('gao', function() Snacks.picker.lsp_outgoing_calls() end, 'C[a]lls [O]utgoing')

    -- WARN: Goto *Declaration*, not Definition. In C this takes you to the header.
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    map('K', function() vim.lsp.buf.hover() end, 'Hover')
    map('gK', function() vim.lsp.buf.signature_help() end, 'Signature Help')
    map('<C-k>', function() vim.lsp.buf.signature_help() end, 'Signature Help', 'i')

    -- Jump between references of the word under the cursor.
    -- Powered by Snacks.words, which also draws the highlights. This replaces
    -- the hand-rolled CursorHold/CursorMoved documentHighlight autocmds that
    -- used to live in this file (~30 lines gone).
    -- Requires `words = { enabled = true }` in snacks.lua.
    map(']]', function() Snacks.words.jump(vim.v.count1) end, 'Next Reference')
    map('[[', function() Snacks.words.jump(-vim.v.count1) end, 'Prev Reference')
    map('<a-n>', function() Snacks.words.jump(vim.v.count1, true) end, 'Next Reference (cycle)')
    map('<a-p>', function() Snacks.words.jump(-vim.v.count1, true) end, 'Prev Reference (cycle)')

    -- ========================================================
    -- Code actions / refactors
    -- ========================================================
    map('<leader>ca', vim.lsp.buf.code_action, 'Code [A]ction', { 'n', 'x' })
    map('<leader>cA', function() vim.lsp.buf.code_action { context = { only = { 'source' } } } end, 'Source [A]ction')
    map('<leader>cc', vim.lsp.codelens.run, 'Run [C]odelens', { 'n', 'x' })
    map('<leader>cr', vim.lsp.buf.rename, '[R]ename')
    map('<leader>cR', function() Snacks.rename.rename_file() end, '[R]ename File')
    map('<leader>cl', function() Snacks.picker.lsp_config() end, '[L]sp Info')
    map(
      '<leader>co',
      function() vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true } end,
      '[O]rganize Imports'
    )

    -- ========================================================
    -- TypeScript / vtsls (adapted from the LazyVim typescript extra)
    -- ========================================================
    -- Registered after the generic maps above so it overrides <leader>co / gD
    -- on TS buffers only.
    if client.name == 'vtsls' then
      -- Small helper: apply a specific code action kind without a picker.
      local function only(kind)
        return function() vim.lsp.buf.code_action { context = { only = { kind } }, apply = true } end
      end

      map('<leader>co', only 'source.organizeImports', '[O]rganize Imports')
      map('<leader>cm', only 'source.addMissingImports.ts', 'Add [M]issing Imports')
      map('<leader>cu', only 'source.removeUnused.ts', 'Remove [U]nused Imports')
      map('<leader>cd', only 'source.fixAll.ts', 'Fix All [D]iagnostics')

      -- FIX: `vim.lsp.buf.execute_command` is deprecated on 0.11+.
      -- The replacement is the client method `client:exec_cmd(cmd, ctx)`.
      map(
        '<leader>cV',
        function() client:exec_cmd({ command = 'typescript.selectTypeScriptVersion' }, { bufnr = event.buf }) end,
        'Select TS Workspace [V]ersion'
      )

      map('gD', function()
        -- FIX: make_position_params() now requires an explicit position
        -- encoding; calling it bare throws on 0.11+.
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        client:exec_cmd({
          command = 'typescript.goToSourceDefinition',
          arguments = { params.textDocument.uri, params.position },
        }, { bufnr = event.buf })
      end, 'Goto Source [D]efinition')

      map('gR', function()
        client:exec_cmd({
          command = 'typescript.findAllFileReferences',
          arguments = { vim.uri_from_bufnr(0) },
        }, { bufnr = event.buf })
      end, 'File [R]eferences')
    end

    -- ========================================================
    -- Inlay hints
    -- ========================================================
    if client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>uh', function()
        -- FIX: the old version read per-buffer state but wrote global state,
        -- so toggling in one buffer flipped hints everywhere. Pass the filter
        -- to enable() as well.
        local filter = { bufnr = event.buf }
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
      end, '[U]i Toggle Inlay [H]ints')
    end
  end,
})

-- ============================================================
-- Server configurations
-- ============================================================
-- Only the *overrides* go here. The base config (cmd, root_markers,
-- filetypes) comes from nvim-lspconfig's `lsp/<name>.lua` files, which
-- `vim.lsp.enable()` picks up off the runtimepath automatically.
---@type table<string, vim.lsp.Config>
local servers = {
  pyright = {},

  ruff = {
    on_init = function(client)
      -- Disable capabilities that pyright already provides (avoids duplicate hover)
      client.server_capabilities.hoverProvider = false
      client.server_capabilities.definitionProvider = false
      client.server_capabilities.referencesProvider = false
      client.server_capabilities.completionProvider = false
    end,
  },

  -- TypeScript / React Native
  vtsls = {
    filetypes = {
      'javascript',
      'javascriptreact',
      'javascript.jsx',
      'typescript',
      'typescriptreact',
      'typescript.tsx',
    },
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          maxInlayHintLength = 30,
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
      },
      typescript = {
        updateImportsOnFileMove = { enabled = 'always' },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = 'literals' },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
      javascript = {
        updateImportsOnFileMove = { enabled = 'always' },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = 'literals' },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
    },
  },

  marksman = {},
  roslyn_ls = {},

  tinymist = {
    single_file_support = true, -- Fixes LSP attachment in non-Git directories
    settings = {
      formatterMode = 'typstyle',
    },
  },

  -- lua_ls: workspace.library is intentionally omitted.
  -- lazydev.nvim (plugins/lazydev.lua) handles library injection lazily
  -- per-buffer, which avoids the slow full-workspace scan and the
  -- duplicate-loading bug from nvim_get_runtime_file('', true).
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- formatting is done by stylua via conform
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false },
      },
    },
  },

  -- NOTE: `stylua = {}` used to live in this table purely so that
  -- `vim.tbl_keys(servers)` would feed it to mason. Side effect:
  -- `vim.lsp.enable('stylua')` tried to start a language server that does not
  -- exist. Formatters/linters now live in `ensure_installed` below instead.
}

-- ============================================================
-- Tooling installation (mason)
-- ============================================================
-- These are mason PACKAGE names, not lspconfig server names.
-- Browse them with `:Mason`, or at https://mason-registry.dev/registry/list
local ensure_installed = {
  -- language servers
  'pyright',
  'ruff',
  'vtsls',
  'lua-language-server',
  'marksman',
  'roslyn-language-server',
  'tinymist',
  'jdtls',
  -- formatters / linters
  'stylua',
  'markdownlint-cli2',
}

vim.pack.add {
  -- Still required: provides the base `lsp/<server>.lua` definitions that
  -- `vim.lsp.enable()` reads. Do NOT drop this one.
  Gh 'neovim/nvim-lspconfig',
  Gh 'mason-org/mason.nvim',
  Gh 'mfussenegger/nvim-jdtls', -- consumed by ftplugin/java.lua

  -- REMOVED: 'mason-org/mason-lspconfig.nvim'
  --   It was a no-op here. `automatic_enable = false` meant it enabled
  --   nothing, and `vim.lsp.config`/`vim.lsp.enable` below already do the
  --   wiring. Its only remaining job was translating server names into
  --   mason package names for mason-tool-installer — replaced by the
  --   explicit `ensure_installed` list above.
  --
  -- REMOVED: 'WhoIsSethDaniel/mason-tool-installer.nvim'
  --   Replaced by the ~6 line auto-install loop below. If you'd rather keep
  --   the plugin, add it back and swap the loop for:
  --     require('mason-tool-installer').setup { ensure_installed = ensure_installed }
}

Later(function()
  require('mason').setup {}

  -- Auto-install anything missing, in the background.
  local registry = require 'mason-registry'
  registry.refresh(function()
    for _, name in ipairs(ensure_installed) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() then
        pkg:install()
      elseif not ok then
        vim.notify('mason: unknown package "' .. name .. '"', vim.log.levels.WARN)
      end
    end
  end)

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end)
