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

-- Vault note buffers opened later in a coding session can't unload the
-- plugin, so every global keymap of its resolved config gets a buffer-local
-- `<nop>` shadow: the key does nothing there and the `hidden` flag removes
-- the entry from the which-key tree in that buffer only.
local shadows_applied = {}
local function disable_in_vault(buf)
  if shadows_applied[buf] then return end
  shadows_applied[buf] = true
  local spec = {}
  for lhs, entry in pairs(require('opencode.config').keymap.editor) do
    if entry ~= false then spec[#spec + 1] = { lhs, '<nop>', mode = { 'n', 'v' }, buffer = buf, hidden = true, desc = 'opencode (vault)' } end
  end
  require('which-key').add(spec)
end

return {
  'sudo-tee/opencode.nvim',
  enabled = not is_windows and not vault_session,
  event = { 'BufReadPre', 'BufNewFile' },
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
