local scooter_term = nil

-- Called by scooter to open the selected file at the correct line from the scooter search list
_G.EditLineFromScooter = function(file_path, line)
  if scooter_term and scooter_term:buf_valid() then scooter_term:hide() end

  local current_path = vim.fn.expand '%:p'
  local target_path = vim.fn.fnamemodify(file_path, ':p')

  if current_path ~= target_path then vim.cmd.edit(vim.fn.fnameescape(file_path)) end

  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

local function is_terminal_running(term)
  if not term or not term:buf_valid() then return false end
  local channel = vim.fn.getbufvar(term.buf, 'terminal_job_id')
  return channel and vim.fn.jobwait({ channel }, 0)[1] == -1
end

local function open_scooter()
  if is_terminal_running(scooter_term) then
    scooter_term:toggle()
  else
    scooter_term = require('snacks').terminal.open('scooter', {
      win = { position = 'float' },
    })
  end
end

local function open_scooter_with_text(search_text)
  if scooter_term and scooter_term:buf_valid() then scooter_term:close() end

  local escaped_text = vim.fn.shellescape(search_text:gsub('\r?\n', ' '))
  scooter_term = require('snacks').terminal.open('scooter --fixed-strings --search-text ' .. escaped_text, {
    win = { position = 'float' },
  })
end

local function open_scooter_with_visual_selection()
  local selection = vim.fn.getreg '"'
  vim.cmd 'normal! "ay'
  open_scooter_with_text(vim.fn.getreg 'a')
  vim.fn.setreg('"', selection)
end

-- [[ snacks.nvim ]]
-- Picker, dashboard, notifier, toggles, terminal, ... Eager (priority 1000)
-- so `Snacks` and `vim.ui.select` are available from the start, like before.
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  init = function() vim.g.snacks_animate = false end,
  -- See `:help snacks.nvim` and `:help snacks-picker`
  opts = {
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
          { icon = ' ', key = 's', desc = 'Restore Session', action = function() LoadCwdSession() end },
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
        { section = 'recent_files', icon = ' ', title = 'Recent Files', indent = 3, padding = 2 },
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
    indent = {
      indent = {
        enabled = false, -- enable indent guides
      },
      scope = {
        enabled = true, -- enable highlighting the current scope
        priority = 200,
        char = '╎',
        underline = false,
        only_current = true,
        hl = 'SnacksIndentScope', ---@type string|string[] hl group for scopes
      },
    },
    input = { enabled = false },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false }, -- owned by mini.statuscolumn
    words = { enabled = true },
  },

  -- ============================================================
  -- Picker keymaps
  -- ============================================================
  keys = {
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sf', function() Snacks.picker.files() end, desc = '[S]earch [F]iles' },
    { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, mode = { 'n', 'v' }, desc = '[S]earch current [W]ord' },
    { '<leader>sg', function() Snacks.picker.grep() end, desc = '[S]earch by [G]rep' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sR', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent Files ("." for repeat)' },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
    { '<leader>sp', function() Snacks.picker.projects() end, desc = 'Projects' },
    { '<leader><leader>', function() Snacks.picker.buffers() end, desc = ' Find existing buffers' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = '[S]earch [M]arks' },
    { '<leader>sl', function() Snacks.picker.loclist() end, desc = '[S]earch [L]ocation List' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = '[S]earch [Q]uickfix List' },
    { '<leader>s"', function() Snacks.picker.registers() end, desc = '[S]earch [R]egisters' },
    { '<leader>sr', function() open_scooter() end, desc = '[S]earch [R]eplace Scooter', mode = { 'x', 'n' } },
    { '<leader>sv', function() open_scooter_with_visual_selection() end, desc = '[S]earch Replace [V]isual Selection', mode = { 'x' } },
    { '<leader>si', function() open_scooter_with_text(vim.fn.input 'Search text: ') end, desc = '[S]arch [T]ext in Scooter', mode = { 'x', 'n' } },
    -- NOTE: these two need todo-comments.nvim installed — the snacks source reads
    -- its keyword patterns. That is why todo-comments stays in the config.
    { '<leader>st', function() Snacks.picker.todo_comments() end, desc = '[S]earch [T]odo Comments' },
    { '<leader>sT', function() Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME', 'NOTE' } } end, desc = 'Todo/Fix/Fixme' },
    { '<leader>sn', function() Snacks.picker.notifications() end, desc = 'Search Notification History' },

    -- Git (mini.diff owns the signs; these are the history/blame pickers that
    -- replaced gitsigns' blame and neogit/diffview)
    { '<leader>gL', function() Snacks.picker.git_log() end, desc = 'Git Log (cwd)' },
    { '<leader>gb', function() Snacks.picker.git_log_line() end, desc = 'Git Blame Line' },
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Current File History' },
    { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (hunks)' },

    -- Fuzzily search lines in the current buffer
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },

    -- Search by grep only in open buffers
    {
      '<leader>s/',
      function() Snacks.picker.grep { open_buffers = true, title = 'Live Grep in Open Files' } end,
      desc = '[S]earch [/] in Open Files',
    },

    -- Shortcut for searching your Neovim configuration files
    {
      '<leader>snc',
      function() Snacks.picker.files { cwd = vim.fn.stdpath 'config', follow = true } end,
      desc = '[S]earch [N]eovim [C]onfig files',
    },

    -- ============================================================
    -- Obsidian vault tags picker (search only in tags)
    -- ============================================================
    {
      '<leader>s#',
      function()
        local vault = vim.fn.expand '~/Documents/notes/vault'
        Snacks.picker.pick {
          title = 'Vault Tags',
          prompt = 'Tag? ',
          finder = function()
            local items, seen = {}, {}
            local add = function(file, tag)
              tag = tag:gsub('^#', ''):gsub('[%]%,]', '')
              if tag ~= '' and not seen[tag] then
                seen[tag] = true
                table.insert(items, { text = '# ' .. tag, search = tag, file = file })
              end
            end

            local inline = 'rg --no-heading -o -N "#[A-Za-z0-9_/+%.-]+" ' .. vim.fn.fnameescape(vault)
            for line in io.popen(inline):lines() do
              local file, tag = line:match '^(.-):#([A-Za-z0-9_/+%.-]+)'
              if file then add(file, tag) end
            end

            local fm = 'rg --no-heading -n -A 40 "^tags:" ' .. vim.fn.fnameescape(vault)
            local cur
            for line in io.popen(fm):lines() do
              local file, rest = line:match '^(.-):%d+:tags:%s*(.*)$'
              if file then
                cur = file
                local arr = rest:gsub('[%[%]]', '')
                for tag in (arr .. ' '):gmatch '[%w_/+-]+' do
                  add(cur, tag)
                end
              elseif cur then
                local content = line:match '^.-%d+%-(.*)$'
                if content and content:match '^%s*%-%-%-' then
                  cur = nil
                elseif content then
                  local bullet = content:match '^%s*%-%s*(.-)%s*[,]?$'
                  if bullet then add(cur, bullet) end
                end
              end
            end

            return items
          end,
        }
      end,
      desc = 'Search Vault Tags',
    },
  },

  -- ============================================================
  -- Toggles
  -- ============================================================
  config = function(_, opts)
    require('snacks').setup(opts)

    Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
    Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
    Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
    Snacks.toggle.diagnostics():map '<leader>ud'
    Snacks.toggle.line_number():map '<leader>ul'
    Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = 'Conceal Level' }):map '<leader>uc'
    Snacks.toggle.treesitter():map '<leader>uT'
    Snacks.toggle.dim():map '<leader>uD'
    Snacks.toggle.indent():map '<leader>ug'
    Snacks.toggle.words():map '<leader>uk'
    Snacks.toggle.profiler():map '<leader>dpp'
    Snacks.toggle.profiler_highlights():map '<leader>dph'
    Snacks.toggle.zoom():map('<leader>wz'):map '<leader>uZ'
    Snacks.toggle.zen():map '<leader>uz'

    -- NOTE: `Snacks.toggle.scroll():map '<leader>uS'` was removed along with
    -- mini.animate — `scroll = { enabled = false }` above means there is nothing
    -- to toggle. Flip it to `true` and add the mapping back if you want animated
    -- scrolling.
  end,
}
