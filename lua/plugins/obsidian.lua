vim.pack.add {
  {
    src = "https://github.com/obsidian-nvim/obsidian.nvim",
  },
}

On_event('VimEnter', function()
  local cwd = vim.fn.getcwd()
  local vault = vim.fn.expand('~/Documents/notes/vault'):gsub('/$', '')
  if cwd == vault or cwd:sub(1, #vault + 1) == vault .. '/' then
    require("obsidian").setup {
      legacy_commands = false, -- this will be removed in 4.0.0
      workspaces = {
        {
          name = "notas",
          path = "~/Documents/notes/vault",
        },
      },
    }
  end
end)

