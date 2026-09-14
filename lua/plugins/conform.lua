-- [[ conform.nvim ]]
-- Formatting. Loaded before a file is read so `format_on_save` is active
-- from the first buffer; the `<leader>cf` keymap loads it on demand.
return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  keys = {
    {
      '<leader>cf',
      function() require('conform').format { async = true } end,
      mode = { 'n', 'v' },
      desc = '[C]onform [F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        lua = true,
        python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
      -- rust = { 'rustfmt' },
      -- Conform can also run multiple formatters sequentially
      python = { 'ruff_organize_imports', 'ruff_format' },
      csharp = { 'csharpier' },
      lua = { 'stylua' },
      javascript = { 'biome-organize-imports', 'biome' },
      typescript = { 'biome-organize-imports', 'biome' },
      javascriptreact = { 'biome-organize-imports', 'biome' },
      typescriptreact = { 'biome-organize-imports', 'biome' },
      json = { 'biome' },
      jsonc = { 'biome' },
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  },
}
