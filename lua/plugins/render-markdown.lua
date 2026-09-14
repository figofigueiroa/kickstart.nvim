-- [[ render-markdown.nvim ]]
-- Only used by opencode's output buffers (regular markdown is NOT rendered,
-- matching the old ftplugin/opencode_output.lua setup).
return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'opencode_output',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  opts = {
    anti_conceal = { enabled = false },
    file_types = { 'opencode_output' },
  },
}
