vim.pack.add {
  {
    src = "https://github.com/obsidian-nvim/obsidian.nvim",
  },
}

local is_windows = vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1

On_event('VimEnter', function()
  local cwd = vim.fn.getcwd()
  local vault = is_windows and vim.fn.expand('~/vault'):gsub('/$', '') or vim.fn.expand('~/Documents/notes/vault'):gsub('/$', '')
  if cwd == vault or cwd:sub(1, #vault + 1) == vault .. '/' then
    require("obsidian").setup {
      legacy_commands = false, -- this will be removed in 4.0.0
      workspaces = {
        {
          name = "notas",
          path = is_windows and "~/vault" or "~/Documents/notes/vault",
        },
      },
    }
  end
end)

