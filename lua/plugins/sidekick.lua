-- NES sempre; CLI de AI só no Linux (no Windows não há opencode/tmux)
local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

local cli_keys = {
  {
    '<a-.>',
    function() require('sidekick.cli').focus() end,
    desc = 'Sidekick Focus',
    mode = { 'n', 't', 'i', 'x' },
  },
  {
    '<leader>aa',
    function() require('sidekick.cli').toggle() end,
    desc = 'Sidekick Toggle CLI',
  },
  {
    '<leader>as',
    function() require('sidekick.cli').select() end,
    -- Or to select only installed tools:
    -- require("sidekick.cli").select({ filter = { installed = true } })
    desc = 'Select CLI',
  },
  {
    '<leader>ad',
    function() require('sidekick.cli').close() end,
    desc = 'Detach a CLI Session',
  },
  {
    '<leader>at',
    function() require('sidekick.cli').send { msg = '{this}' } end,
    mode = { 'x', 'n' },
    desc = 'Send This',
  },
  {
    '<leader>af',
    function() require('sidekick.cli').send { msg = '{file}' } end,
    desc = 'Send File',
  },
  {
    '<leader>av',
    function() require('sidekick.cli').send { msg = '{selection}' } end,
    mode = { 'x' },
    desc = 'Send Visual Selection',
  },
  {
    '<leader>ap',
    function() require('sidekick.cli').prompt() end,
    mode = { 'n', 'x' },
    desc = 'Sidekick Select Prompt',
  },
  -- Example of a keybinding to open Claude directly
  {
    '<leader>ac',
    function() require('sidekick.cli').toggle { name = 'claude', focus = true } end,
    desc = 'Sidekick Toggle Claude',
  },
}

return {
  'folke/sidekick.nvim',
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = 'tmux',
        enabled = not is_windows, -- tmux não existe no Windows
      },
      win = {
        keys = {
          -- c-b/c-f conflitam com prefix do tmux e fullscreen do opencode
          buffers = { '<a-b>', 'buffers', mode = 'nt', desc = 'open buffer picker' },
          files = { '<a-f>', 'files', mode = 'nt', desc = 'open file picker' },
        },
      },
    },
  },
  keys = vim.list_extend({
    {
      '<tab>',
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require('sidekick').nes_jump_or_apply() then
          return '<Tab>' -- fallback to normal tab
        end
      end,
      expr = true,
      desc = 'Goto/Apply Next Edit Suggestion',
    },
  }, is_windows and {} or cli_keys),
}
