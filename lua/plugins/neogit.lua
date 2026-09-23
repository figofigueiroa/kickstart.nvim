return {
  "neogitorg/neogit",
  cmd = "Neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "esmuellert/codediff.nvim",      -- optional
  },
  keys = {
    { "<leader>gg", "<Cmd>Neogit<CR>", desc = "Neogit" },
  },
  opts = {
    integrations = {
      codediff = true,
      snacks = true
    },
  },
}
