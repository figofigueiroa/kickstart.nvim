local diagnostic_icons = {
  Error = " ",
  Warn  = " ",
  Hint  = " ",
  Info  = " ",
}
-- Lê a cor de um highlight group, seguindo links (ex.: Function -> Identifier)
local function hl_color(group, attr, fallback)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  local value = ok and hl[attr] or nil
  return value and string.format("#%06x", value) or fallback
end

-- Mistura duas cores hex. alpha = 1 -> só `a`; alpha = 0 -> só `b`
local function blend(a, b, alpha)
  local function channels(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  end
  local ar, ag, ab = channels(a)
  local br, bg, bb = channels(b)
  local function mix(x, y)
    return math.floor(x * alpha + y * (1 - alpha) + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(ar, br), mix(ag, bg), mix(ab, bb))
end

local function bufferline_highlights()
  local normal_bg = hl_color("Normal", "bg", "#1c1c1c")

  local c = {
    fill = blend("#000000", normal_bg, 0.35), -- faixa atrás das abas (mais escura)
    inactive = blend("#000000", normal_bg, 0.15), -- abas não focadas
    selected = normal_bg, -- aba ativa tem o mesmo fundo da janela
    fg = hl_color("Normal", "fg", "#bcbcbc"),
    dim = hl_color("Comment", "fg", "#767676"),
    accent = hl_color("Function", "fg", "#87afd7"),
    modified = hl_color("String", "fg", "#87af87"),
    error = hl_color("DiagnosticError", "fg", "#d75f5f"),
    warn = hl_color("DiagnosticWarn", "fg", "#d7af5f"),
    info = hl_color("DiagnosticInfo", "fg", "#5fafd7"),
    hint = hl_color("DiagnosticHint", "fg", "#afafaf"),
  }

  local hl = {
    fill = { bg = c.fill },
    trunc_marker = { fg = c.dim, bg = c.fill },
    offset_separator = { fg = c.fill, bg = c.fill },
    tab = { fg = c.dim, bg = c.inactive },
    tab_selected = { fg = c.fg, bg = c.selected, bold = true },
    tab_close = { fg = c.error, bg = c.fill },
    tab_separator = { fg = c.fill, bg = c.inactive },
    tab_separator_selected = { fg = c.fill, bg = c.selected },
    indicator_visible = { fg = c.inactive, bg = c.inactive },
    indicator_selected = { fg = c.accent, bg = c.selected },
  }

  -- Cada grupo do bufferline existe em 3 estados:
  -- inativo, visible (aberto em outra janela) e selected (janela focada)
  local function family(name, fg_inactive, fg_selected, style)
    style = style or {}
    local inactive_name = name == "buffer" and "background" or name
    hl[inactive_name] = { fg = fg_inactive, bg = c.inactive, italic = style.italic }
    hl[name .. "_visible"] = {
      fg = blend(fg_selected, fg_inactive, 0.5),
      bg = c.inactive,
      italic = style.italic,
    }
    hl[name .. "_selected"] = { fg = fg_selected, bg = c.selected, bold = true, italic = style.italic }
  end

  family("buffer", c.dim, c.fg)
  family("numbers", c.dim, c.fg)
  family("close_button", c.dim, c.error)
  family("modified", c.modified, c.modified)
  family("duplicate", c.dim, c.dim, { italic = true })
  family("separator", c.fill, c.fill)
  family("diagnostic", c.dim, c.fg)
  family("pick", c.error, c.error, { italic = true })

  for _, d in ipairs({
    { "error", c.error },
    { "warning", c.warn },
    { "info", c.info },
    { "hint", c.hint },
  }) do
    local name, color = d[1], d[2]
    family(name, blend(color, c.inactive, 0.6), color) -- nome do arquivo
    family(name .. "_diagnostic", color, color) -- ícone + contador
  end

  return hl
end

return {
  "akinsho/bufferline.nvim",
  event = {"BufReadPost", "BufAdd", "BufNewFile" },
  dependencies = { "nvim-mini/mini.icons" },
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
  },
  opts = {

    highlights = bufferline_highlights(),
    options = {
      -- stylua: ignore
      close_command = function(n) Snacks.bufdelete(n) end,
      -- stylua: ignore
      right_mouse_command = function(n) Snacks.bufdelete(n) end,
      diagnostics = "nvim_lsp",
      always_show_bufferline = false,
      diagnostics_indicator = function(_, _, diag)
        local ret = (diag.error and diagnostic_icons.Error .. diag.error .. " " or "")
          .. (diag.warning and diagnostic_icons.Warn .. diag.warning or "")
        return vim.trim(ret)
      end,
      offsets = {
        {
          filetype = "neo-tree",
          text = "Neo-tree",
          highlight = "Directory",
          text_align = "left",
        },
        {
          filetype = "snacks_layout_box",
        },
      },
      ---@param element bufferline.IconFetcherOpts
      get_element_icon = function(element)
        local MiniIcons = require("mini.icons")
        if element.directory then
          return MiniIcons.get("directory", element.path)
        end
        return MiniIcons.get("file", element.path)
      end,
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)
    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })
  end,
}
