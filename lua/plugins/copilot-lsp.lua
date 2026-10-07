return {
  'copilotlsp-nvim/copilot-lsp',
  event = 'VeryLazy', -- precisa estar ativo para gerar NES enquanto você edita
  init = function()
    vim.g.copilot_nes_debounce = 500
  end,
  opts = { nes = { move_count_threshold = 3 } },
  config = function(_, opts)
    require('copilot-lsp').setup(opts)
    vim.lsp.enable('copilot_ls') -- usa o lsp/copilot_ls.lua que o plugin entrega
  end,
  keys = {
    { -- normal: pula pro início do edit; já estando nele, aplica e vai pro fim
      '<Tab>',
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.b[bufnr].nes_state then
          local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
            or (require('copilot-lsp.nes').apply_pending_nes()
              and require('copilot-lsp.nes').walk_cursor_end_edit())
          return nil
        end
        return '<C-i>' -- Tab == C-i no terminal (jumplist forward)
      end,
      expr = true,
      mode = 'n',
      desc = 'Copilot NES: goto/apply next edit',
    },
    { -- limpa a NES; senão preserva o nohlsearch do config/keymaps.lua
      '<Esc>',
      function()
        if not require('copilot-lsp.nes').clear() then
          return '<cmd>nohlsearch<CR>'
        end
      end,
      expr = true,
      mode = 'n',
      desc = 'Clear Copilot NES (fallback: nohlsearch)',
    },
  },
}
