vim.pack.add { Gh 'folke/persistence.nvim' }

On_event('BufReadPre', function() require('persistence').setup() end)

-- load the session for the current directory
vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end, {desc = 'Load Session for current directory'})

-- select a session to load
vim.keymap.set("n", "<leader>qS", function() require("persistence").select() end, {desc = 'Select Session to load'})

-- load the last session
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end, {desc = 'Load last Session'})

-- stop Persistence => session won't be saved on exit
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end, { desc = 'Stop persistence.nvim'})
