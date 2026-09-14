-- [[ opencode.nvim ]]
-- Terminal-based AI coding agent frontend — the AI tool on Linux
-- (CodeCompanion is Windows-only).
return {
  'sudo-tee/opencode.nvim',
  event = 'VeryLazy',
  dependencies = {
    -- render-markdown powers the tool output windows (its own spec lives in
    -- lua/plugins/render-markdown.lua)
    'MeanderingProgrammer/render-markdown.nvim',
    -- for file mentions and command completion
    'saghen/blink.cmp',
    -- for the file-mention picker
    'folke/snacks.nvim',
  },
  opts = {
    preferred_picker = 'snacks',
    preferred_completion = 'blink',
    default_mode = 'plan',
  },
}
