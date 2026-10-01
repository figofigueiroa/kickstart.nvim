-- easy-dotnet.lua
--
-- Tooling .NET no Neovim: Roslyn LSP, build/run/test, test runner (estilo
-- Rider), workspace diagnostics, pacotes/EF e debug.
--
-- Substitui:
--   * a descoberta de assemblies + `dotnet build` pré-launch que vivia em
--     lua/plugins/debug.lua (o plugin auto-registra o adapter coreclr no
--     nvim-dap: <F5> abre o picker de projeto e cuida de build/env)
--   * o build/teste com quickfix do ftplugin/cs.lua
--   * o lazydotnet.nvim (<leader>ld agora abre os comandos :Dotnet)
--   * o roslyn_ls manual do nvim-lspconfig (o LSP vem daqui)
--
-- Requer o servidor global `dotnet tool install -g EasyDotnet`
-- (o plugin avisa quando estiver desatualizado; `:Dotnet _server update`).
return {
  'GustavEikaas/easy-dotnet.nvim',
  cmd = 'Dotnet',
  ft = { 'cs', 'fsharp', 'razor', 'cshtml' },
  keys = {
    -- herda o atalho do antigo lazydotnet
    { '<leader>ld', '<cmd>Dotnet<cr>', desc = 'Dotnet: comandos' },
    -- toggle do code lens de referências; `<leader>uc` minúsculo já é o
    -- Conceal Level do snacks, daí o C maiúsculo
    { '<leader>uC', '<cmd>DotnetCodelens<cr>', desc = '[U]i Toggle [C]ode Lens (refs)' },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'mfussenegger/nvim-dap',
    'folke/snacks.nvim',
  },
  config = function()
    require('easy-dotnet').setup {
      picker = 'snacks',
      debugger = {
        -- Engine do debugger empacotado no easy-dotnet-server:
        -- 'netcoredbg' (default) | 'dncdbg' | 'sharpdbg'
        engine = 'dncdbg',
      },
      test_runner = {
        -- Defaults do plugin usam <leader>r/t/e/p/d direto no buffer de
        -- testes, colidindo com os grupos globais <leader>r (refactor),
        -- <leader>p (p5) e <leader>d (debug). Remapeados para o prefixo
        -- <leader>t, como o nvim-jdtls faz para Java.
        mappings = {
          run_test_from_buffer = { lhs = '<leader>tr', desc = 'run test from buffer' },
          run_all_tests_from_buffer = { lhs = '<leader>ta', desc = 'Run all tests in file' },
          get_build_errors = { lhs = '<leader>te', desc = 'get build errors' },
          peek_stack_trace_from_buffer = { lhs = '<leader>tp', desc = 'peek stack trace from buffer' },
          debug_test_from_buffer = { lhs = '<leader>td', desc = 'debug test from buffer' },
        },
      },
      outdated = {
        mappings = {
          -- <leader>pu/pa sombreariam os atalhos do p5 dentro de .csproj
          -- (N = NuGet)
          upgrade = { lhs = '<leader>nu', desc = 'upgrade package under cursor' },
          upgrade_all = { lhs = '<leader>na', desc = 'upgrade all outdated packages' },
        },
      },
    }

    -- =========================================================================
    -- Toggle do code lens de referências do Roslyn
    -- =========================================================================
    -- O contador de referências acima dos símbolos polui diffs lado a lado.
    -- Alterna via `<leader>uC` (família dos [U]i toggles) ou `:DotnetCodelens`.
    --
    -- Desligar de verdade exige os dois lados:
    --   * `client.settings`: é daqui que o nvim responde o pull
    --     `workspace/configuration` que o Roslyn faz ao receber o notify; sem
    --     mutar aqui ele re-puxa a config antiga e as lens voltam no próximo
    --     refresh (os autocmds de refresh do easy-dotnet continuam rodando);
    --   * roundtrip em `vim.lsp.codelens`: enable(false) limpa o virtual text
    --     renderizado na hora e enable(true) pede as lens de novo (vazias
    --     quando off, cheias quando on).
    local codelens_on = true -- default do Roslyn (o plugin não mexe nele)

    ---@param on boolean
    local function apply_codelens(on)
      for _, client in ipairs(vim.lsp.get_clients { name = 'easy_dotnet' }) do
        ---@type table
        local section = client.settings['csharp|code_lens']
        if type(section) ~= 'table' then section = {} end
        client.settings['csharp|code_lens'] = vim.tbl_deep_extend('force', section, {
          dotnet_enable_references_code_lens = on,
        })
        client:notify('workspace/didChangeConfiguration', {
          settings = { ['csharp|code_lens'] = { dotnet_enable_references_code_lens = on } },
        })
        vim.lsp.codelens.enable(false, { client_id = client.id })
        vim.lsp.codelens.enable(true, { client_id = client.id })
      end
    end

    ---Alterna o code lens de referências (todos os clients easy_dotnet).
    local function toggle_codelens()
      codelens_on = not codelens_on
      apply_codelens(codelens_on)
      if #vim.lsp.get_clients { name = 'easy_dotnet' } == 0 then
        vim.notify('Roslyn ainda não está ativo; o estado vale para quando anexar', vim.log.levels.WARN)
      else
        vim.notify('Code lens de referências: ' .. (codelens_on and 'ligado' or 'desligado'))
      end
    end

    vim.api.nvim_create_user_command('DotnetCodelens', toggle_codelens, {
      desc = 'Alterna o code lens de referências do Roslyn (easy-dotnet)',
    })

    -- Roslyn que anexar depois (outra solution, restart do LSP) herda o
    -- estado atual: o client novo nasce com o default (lens ligada).
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('user-dotnet-codelens', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == 'easy_dotnet' and not codelens_on then apply_codelens(false) end
      end,
    })
  end,
}
