-- [[ opencode.nvim ]]
-- Terminal-based AI coding agent frontend — the AI tool on Linux
-- (CodeCompanion is Windows-only).

local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

-- Same vault as obsidian.lua: note-taking sessions don't get the coding agent.
local vault = (is_windows and vim.fn.expand '~/vault' or vim.fn.expand '~/Documents/notes/vault'):gsub('/$', '')

local function in_vault(path) return path == vault or path:sub(1, #vault + 1) == vault .. '/' end

-- Disabled on Windows and when the session starts in the vault: either the
-- cwd is inside it or a vault markdown file was opened as a command line arg.
local vault_session = in_vault(vim.fn.getcwd())
  or vim.iter(vim.fn.argv()):any(function(arg)
    local path = vim.fn.fnamemodify(tostring(arg), ':p')
    return vim.fn.fnamemodify(path, ':e') == 'md' and in_vault(path)
  end)

-- Editor keymaps at the lazy `keys` level: the handler stubs load the
-- plugin on first press and which-key sees every entry from startup.
-- `action` mirrors the plugin's own keymap resolution (opencode.commands
-- build_parsed_intent + execute_parsed_intent); `nv` keeps parity with the
-- editor default modes (n+v) the plugin applies to entries without a mode.
local function action(name, args)
  return function()
    local c = require 'opencode.commands'
    c.execute_parsed_intent(c.build_parsed_intent(name, args))
  end
end

local nv = { 'n', 'v' }

local keys = {
  { '<leader>aa', action 'toggle', desc = 'Open opencode. Close if opened', mode = nv },
  { '<leader>ai', action 'open_input', desc = 'Opens and focuses on input window on insert mode', mode = nv },
  { '<leader>aI', action 'open_input_new_session', desc = 'Opens and focuses on input window on insert mode. Creates a new session', mode = nv },
  { '<leader>ao', action 'open_output', desc = 'Opens and focuses on output window', mode = nv },
  { '<leader>at', action 'toggle_focus', desc = 'Toggle focus between opencode and last window', mode = nv },
  { '<leader>aT', action 'timeline', desc = 'Display timeline picker to navigate/undo/redo/fork sessions', mode = nv },
  { '<leader>aq', action 'close', desc = 'Close UI windows', mode = nv },
  { '<leader>as', action 'select_session', desc = 'Select and load a opencode session', mode = nv },
  { '<leader>aR', action 'rename_session', desc = 'Rename session', mode = nv },
  { '<leader>ap', action 'configure_provider', desc = 'Quick provider and model switch from predefined list', mode = nv },
  { '<leader>aV', action 'configure_variant', desc = 'Switch model variant for current model', mode = nv },
  { '<leader>ay', action 'add_visual_selection', desc = 'Add visual selection to context', mode = 'v' },
  { '<leader>aY', action 'add_visual_selection_inline', desc = 'Insert visual selection as inline code block in the input buffer', mode = 'v' },
  { '<leader>az', action 'toggle_zoom', desc = 'Zoom in/out on the Opencode panes', mode = nv },
  { '<leader>av', action 'paste_image', desc = 'Paste image from clipboard into current session', mode = nv },
  { '<leader>ad', action 'diff_open', desc = 'Opens a diff tab of a modified file since the last opencode prompt', mode = nv },
  { '<leader>a]', action 'diff_next', desc = 'Navigate to next file diff', mode = nv },
  { '<leader>a[', action 'diff_prev', desc = 'Navigate to previous file diff', mode = nv },
  { '<leader>ac', action 'diff_close', desc = 'Close diff view tab and return to normal editing', mode = nv },
  { '<leader>ara', action 'diff_revert_all_last_prompt', desc = 'Revert all file changes since the last opencode prompt', mode = nv },
  { '<leader>art', action 'diff_revert_this_last_prompt', desc = 'Revert current file changes since the last opencode prompt', mode = nv },
  { '<leader>arA', action 'diff_revert_all', desc = 'Revert all file changes since the last opencode session', mode = nv },
  { '<leader>arT', action 'diff_revert_this', desc = 'Revert current file changes since the last opencode session', mode = nv },
  { '<leader>arr', action 'diff_restore_snapshot_file', desc = 'Restore a file to a restore point', mode = nv },
  { '<leader>arR', action 'diff_restore_snapshot_all', desc = 'Restore all files to a restore point', mode = nv },
  { '<leader>ax', action 'swap_position', desc = 'Swap Opencode pane left/right', mode = nv },
  { '<leader>att', action 'toggle_tool_output', desc = 'Toggle tool output (diffs, cmd output, etc.)', mode = nv },
  { '<leader>atr', action 'toggle_reasoning_output', desc = 'Toggle reasoning output (thinking steps)', mode = nv },
  {
    '<leader>a/',
    action 'quick_chat',
    desc = 'Open quick chat input with selection context in visual mode or current line context in normal mode',
    mode = { 'n', 'x' },
  },
}

-- Vault note buffers opened later in a coding session can't unload the
-- plugin, so every keymap of the `keys` table gets a buffer-local `<nop>`
-- shadow: the key does nothing there and the `hidden` flag removes the
-- entry from the which-key tree in that buffer only.
local shadows_applied = {}
local function disable_in_vault(buf)
  if shadows_applied[buf] then return end
  shadows_applied[buf] = true
  local spec = {}
  for _, k in ipairs(keys) do
    spec[#spec + 1] = { k[1], '<nop>', mode = { 'n', 'v' }, buffer = buf, hidden = true, desc = 'opencode (vault)' }
  end
  require('which-key').add(spec)
end

return {
  'sudo-tee/opencode.nvim',
  -- `enabled` must be a function: lazier serializes the resolved specs into
  -- a startup cache, and a session-computed boolean would bake the verdict
  -- of whichever session last rebuilt it (a coding session leaks the agent
  -- into later vault sessions and vice versa). Functions become fragments
  -- that re-require this module, recomputing the gate from the current
  -- session's cwd/argv.
  enabled = function() return not is_windows and not vault_session end,
  event = { 'BufReadPre', 'BufNewFile' },
  keys = keys,
  dependencies = {
    -- render-markdown powers the tool output windows (its own spec lives in
    -- lua/plugins/render-markdown.lua)
    'MeanderingProgrammer/render-markdown.nvim',
    -- for file mentions and command completion
    'saghen/blink.cmp',
    -- for the file-mention picker
    'folke/snacks.nvim',
    -- registers the vault shadows, so it must load before this plugin
    'folke/which-key.nvim',
  },
  opts = {
    preferred_picker = 'snacks',
    preferred_completion = 'blink',
    default_mode = 'plan',
    -- Editor keymaps live in the `keys` table above; `false` also drops the
    -- plugin's default `<leader>o*` editor maps (window keymaps stay).
    default_global_keymaps = false,
  },
  config = function(_, opts)
    require('opencode').setup(opts)

    local group = vim.api.nvim_create_augroup('opencode-vault-off', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
      group = group,
      pattern = vault .. '/**.md',
      callback = function(event) disable_in_vault(event.buf) end,
    })

    -- The autocmd can't see the BufReadPre in flight when that very event
    -- loaded the plugin: cover the current buffer too when it is a note.
    local name = vim.api.nvim_buf_get_name(0)
    if in_vault(name) and vim.fn.fnamemodify(name, ':e') == 'md' then disable_in_vault(0) end
  end,
}
