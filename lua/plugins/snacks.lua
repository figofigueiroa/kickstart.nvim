-- snacks.nvim — fuzzy finder, toggles, LSP pickers
--
-- snacks.picker is the fuzzy finder replacing Telescope,
-- with no external dependencies.
-- Two important keymaps in a picker:
--  - Insert mode: <c-/>
--  - Normal mode: ?

vim.pack.add { Gh 'folke/snacks.nvim' }
vim.g.snacks_animate = true
-- See `:help snacks.nvim` and `:help snacks-picker`
require('snacks').setup {
  -- snacks.picker overrides vim.ui.select automatically
  picker = { enabled = true },

  bigfile = { enabled = true },
  dashboard = {
    preset = {
      pick = nil,
      ---@type snacks.dashboard.Item[]
      keys = {
        { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
        { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
      header = [[
                                                                             
               ████ ██████           █████      ██                     
              ███████████             █████                             
              █████████ ███████████████████ ███   ███████████   
             █████████  ███    █████████████ █████ ██████████████   
            █████████ ██████████ █████████ █████ █████ ████ █████   
          ███████████ ███    ███ █████████ █████ █████ ████ █████  
         ██████  █████████████████████ ████ █████ █████ ████ ██████ 
      ]],
    },
    sections = {
      { section = 'header' },
      {
        section = 'keys',
        indent = 1,
        padding = 1,
      },
      { section = 'recent_files', icon = ' ', title = 'Recent Files', indent = 3, padding = 2 },
      {
        text = (function()
          if not vim.g.start_time then return { { 'Startup: n/a', hl = 'SnacksDashboardFooter' } } end
          local elapsed = vim.fn.reltimefloat(vim.fn.reltime(vim.g.start_time)) * 1000
          return {
            { '⚡ ', hl = 'SnacksDashboardIcon' },
            { string.format('Startup: %.2fms', elapsed), hl = 'SnacksDashboardFooter' },
          }
        end)(),
        padding = 1,
      },
    },
  },
  explorer = { enabled = false },
  indent = { enabled = true, scope = { char = '╎' } },
  input = { enabled = false },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = false },
  statuscolumn = { enabled = false },
  words = { enabled = false },
}

-- ============================================================
-- Picker keymaps
-- ============================================================
vim.keymap.set('n', '<leader>sh', function() Snacks.picker.help() end, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', function() Snacks.picker.keymaps() end, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', function() Snacks.picker.files() end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', function() Snacks.picker.lsp_symbols() end, { desc = 'LSP Symbols' })
vim.keymap.set('n', '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, { desc = 'LSP Workspace Symbols' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', function() Snacks.picker.grep_word() end, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', function() Snacks.picker.grep() end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', function() Snacks.picker.diagnostics() end, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', function() Snacks.picker.resume() end, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', function() Snacks.picker.recent() end, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', function() Snacks.picker.commands() end, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader>sp', function() Snacks.picker.projects() end, { desc = 'Projects' })
vim.keymap.set('n', '<leader><leader>', function() Snacks.picker.buffers() end, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>sm', function() Snacks.picker.marks() end, { desc = '[S]earch [M]arks' })
vim.keymap.set('n', '<leader>sl', function() Snacks.picker.loclist() end, { desc = '[S]earch [L]ocation List' })
vim.keymap.set('n', '<leader>sq', function() Snacks.picker.qflist() end, { desc = '[S]earch [Q]uickfix List' })
vim.keymap.set('n', '<leader>s"', function() Snacks.picker.registers() end, { desc = '[S]earch [R]egisters' })
vim.keymap.set('n', '<leader>st', function() Snacks.picker.todo_comments() end, { desc = '[S]earch [T]odo Comments' })
vim.keymap.set('n', '<leader>sT', function() Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME', 'NOTE' } } end, { desc = 'Todo/Fix/Fixme' })
vim.keymap.set("n", "<leader>sn", function()
  Snacks.picker.notifications()
end, { desc = "Search Notification History" })
vim.keymap.set('n', '<leader>gL', function() Snacks.picker.git_log() end, { desc = 'Git Log (cwd)' })
vim.keymap.set('n', '<leader>gb', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' })
vim.keymap.set('n', '<leader>gf', function() Snacks.picker.git_log_file() end, { desc = 'Git Current File History' })
vim.keymap.set('n', '<leader>gd', function() Snacks.picker.git_diff() end, { desc = 'Git Current File History' })

-- Fuzzily search lines in the current buffer
vim.keymap.set('n', '<leader>/', function() Snacks.picker.lines() end, { desc = '[/] Fuzzily search in current buffer' })

-- Search by grep only in open buffers
vim.keymap.set(
  'n',
  '<leader>s/',
  function() Snacks.picker.grep { open_buffers = true, title = 'Live Grep in Open Files' } end,
  { desc = '[S]earch [/] in Open Files' }
)

-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>snc', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim [C]onfig files' })

-- ============================================================
-- Toggles
-- ============================================================
Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
Snacks.toggle.diagnostics():map '<leader>ud'
Snacks.toggle.line_number():map '<leader>ul'
Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = 'Conceal Level' }):map '<leader>uc'
Snacks.toggle.treesitter():map '<leader>uT'
Snacks.toggle.dim():map '<leader>uD'
Snacks.toggle.indent():map '<leader>ug'
Snacks.toggle.scroll():map '<leader>uS'
Snacks.toggle.profiler():map '<leader>dpp'
Snacks.toggle.profiler_highlights():map '<leader>dph'
Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
Snacks.toggle.zen():map("<leader>uz")
-- Snacks.toggle.animate():map '<leader>ua'

-- ============================================================
-- LSP picker keymaps (buffer-local, on LspAttach)
-- ============================================================
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('snacks-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    vim.keymap.set('n', '<leader>cl', function() Snacks.picker.lsp_config() end, { buffer = buf, desc = 'Lsp Info' })
    vim.keymap.set('n', 'gr', function() Snacks.picker.lsp_references() end, { buffer = buf, desc = '[G]oto [R]eferences' })
    vim.keymap.set('n', 'gI', function() Snacks.picker.lsp_implementations() end, { buffer = buf, desc = '[G]oto [I]mplementation' })
    vim.keymap.set('n', 'gd', function() Snacks.picker.lsp_definitions() end, { buffer = buf, desc = '[G]oto [D]efinition' })
    -- vim.keymap.set('n', 'gO', function() Snacks.picker.lsp_symbols() end, { buffer = buf, desc = 'Open Document Symbols' })
    -- vim.keymap.set('n', 'gW', function() Snacks.picker.lsp_workspace_symbols() end, { buffer = buf, desc = 'Open Workspace Symbols' })
    vim.keymap.set('n', 'gy', function() Snacks.picker.lsp_type_definitions() end, { buffer = buf, desc = '[G]oto T[y]pe Definition' })
    vim.keymap.set('n', 'gai', function() Snacks.picker.lsp_incoming_calls() end, { buffer = buf, desc = 'C[a]lls Incoming' })
    vim.keymap.set('n', 'gao', function() Snacks.picker.lsp_outgoing_calls() end, { buffer = buf, desc = 'C[a]lls Outgoing' })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = 'Goto Declaration' })
    vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, { desc = 'Hover' })
    vim.keymap.set('n', 'gK', function() vim.lsp.buf.signature_help() end, { desc = 'Signature Help' })
    vim.keymap.set('i', '<C-k>', function() vim.lsp.buf.signature_help() end, { desc = 'Signature Help' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action' })
    vim.keymap.set({ 'n', 'x' }, '<leader>cc', vim.lsp.codelens.run, { desc = 'Run Codelens' })
    -- vim.keymap.set('n', '<leader>cC', vim.lsp.codelens.refresh, { desc = 'Refresh & Display Codelens' })
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename' })
    vim.keymap.set('n', '<leader>cR', function() Snacks.rename.rename_file() end, { desc = 'Rename File' })
    vim.keymap.set('n', '<leader>cA', function() vim.lsp.buf.code_action { context = { only = { 'source' } } } end, { desc = 'Source Action' })
    vim.keymap.set(
      'n',
      '<leader>co',
      function() vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } } } end,
      { desc = 'Organize Imports', buffer = buf }
    )
    vim.keymap.set('n', ']]', function() Snacks.words.jump(vim.v.count1) end, { desc = 'Next Reference' })
    vim.keymap.set('n', '[[', function() Snacks.words.jump(-vim.v.count1) end, { desc = 'Prev Reference' })
    vim.keymap.set('n', '<a-n>', function() Snacks.words.jump(vim.v.count1, true) end, { desc = 'Next Reference' })
    vim.keymap.set('n', '<a-p>', function() Snacks.words.jump(-vim.v.count1, true) end, { desc = 'Prev Reference' })
  end,
})
