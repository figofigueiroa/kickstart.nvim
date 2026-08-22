-- avante.nvim is used as the AI coding assistant on Windows,
-- where OpenCode is not available.
if vim.fn.has 'win32' ~= 1 then return end

vim.pack.add {
  Gh 'nvim-lua/plenary.nvim',
  Gh 'MunifTanjim/nui.nvim',
  Gh 'MeanderingProgrammer/render-markdown.nvim',
  { src = Gh 'yetone/avante.nvim', version = vim.version.range '*',
    build = 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false' },
}

later(function()
  require('render-markdown').setup { file_types = { 'markdown', 'Avante' } }

  require('avante').setup {
    -- Default AI provider; change to 'copilot', 'openai', etc. as needed.
    provider = 'copilot',

    -- Keymaps follow the same <leader>a group defined in which-key.
    mappings = {
      ask            = '<leader>aa', -- [A]i [A]sk
      edit           = '<leader>ae', -- [A]i [E]dit
      refresh        = '<leader>ar', -- [A]i [R]efresh
      focus          = '<leader>af', -- [A]i [F]ocus
      toggle = {
        default      = '<leader>at', -- [A]i [T]oggle
        debug        = '<leader>ad', -- [A]i [D]ebug
        hint         = '<leader>ah', -- [A]i [H]int
        suggestion   = '<leader>as', -- [A]i [S]uggest
        repomap      = '<leader>aR', -- [A]i [R]epomap
      },
      diff = {
        ours         = 'co',
        theirs       = 'ct',
        all_theirs   = 'ca',
        both         = 'cb',
        cursor       = 'cc',
        next         = ']x',
        prev         = '[x',
      },
      suggestion = {
        accept       = '<M-l>',
        next         = '<M-]>',
        prev         = '<M-[>',
        dismiss      = '<C-]>',
      },
      jump = {
        next         = ']]',
        prev         = '[[',
      },
      submit = {
        normal       = '<CR>',
        insert       = '<C-s>',
      },
      sidebar = {
        apply_all    = 'A',
        apply_cursor = 'a',
        switch_windows = '<Tab>',
        reverse_switch_windows = '<S-Tab>',
      },
    },
  }
end)
