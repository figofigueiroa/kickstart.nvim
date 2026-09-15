-- [[ opencode.nvim ]]
-- Terminal-based AI coding agent frontend — the AI tool on Linux
-- (CodeCompanion is Windows-only).

local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

-- Same vault as obsidian.lua: note-taking sessions don't get the coding agent.
local vault = (is_windows and vim.fn.expand '~/vault' or vim.fn.expand '~/Documents/notes/vault'):gsub('/$', '')

local function in_vault(path) return path == vault or path:sub(1, #vault + 1) == vault .. '/' end

-- Disabled on Windows and when the session starts in the vault: either the
-- cwd is inside it or a vault markdown file was opened as a command line arg.
-- (Opening a vault note later in a coding session can't be caught here: the
-- plugin already loaded on VeryLazy.)
local vault_session = in_vault(vim.fn.getcwd())
  or vim.iter(vim.fn.argv()):any(function(arg)
    local path = vim.fn.fnamemodify(tostring(arg), ':p')
    return vim.fn.fnamemodify(path, ':e') == 'md' and in_vault(path)
  end)

return {
  'sudo-tee/opencode.nvim',
  enabled = not is_windows and not vault_session,
  event = 'LazyFile',
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
