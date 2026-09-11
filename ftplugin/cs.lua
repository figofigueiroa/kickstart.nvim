-- local async = vim.async
--
-- local function run_dotnet_async(cmd, args, title)
--   async.run(function()
--     -- :wait() bloqueia apenas a task async, não o editor
--     local result = vim.system(
--       { cmd, unpack(args or {}) },
--       { text = true, cwd = vim.fn.getcwd() }
--     ):wait()
--
--     -- Usa o errorformat do compiler "dotnet" (já existe no runtime do Neovim)
--     vim.cmd("compiler dotnet")
--
--     -- Popula a quickfix list
--     vim.fn.setqflist({}, " ", {
--       title = title or table.concat({ cmd, unpack(args or {}) }, " "),
--       lines = vim.split(result.stdout .. "\n" .. result.stderr, "\n"),
--       efm = vim.o.errorformat,   -- já configurado pelo :compiler dotnet
--     })
--
--     if result.code ~= 0 then
--       vim.cmd("copen")
--       vim.notify("Falha no " .. title, vim.log.levels.ERROR)
--     else
--       vim.notify(title .. " OK", vim.log.levels.INFO)
--     end
--   end)
-- end
--
-- -- Atalhos de exemplo
-- vim.keymap.set("n", "<leader>xb", function()
--   run_dotnet_async("dotnet", { "build", "--nologo", "-consoleloggerparameters:NoSummary" }, "dotnet build")
-- end, { desc = "Quickfix build" })
--
-- vim.keymap.set("n", "<leader>xt", function()
--   run_dotnet_async("dotnet", { "test", "--nologo", "--logger", "console;verbosity=detailed" }, "dotnet test")
-- end, { desc = "Quickfix test" })
local async = vim.async

-------------------------------------------------
-- Parser de erros/warnings do MSBuild / dotnet build
-------------------------------------------------
local function parse_dotnet_build(lines)
  local items = {}
  -- Formato principal:
  -- C:\path\file.cs(12,34): error CS1234: mensagem [Projeto]
  -- /path/file.cs(12,34): warning CS1234: mensagem
  local build_pat = "^%s*(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+([^:]+):%s*(.+)$"

  for _, line in ipairs(lines) do
    local filename, lnum, col, kind, code, text = line:match(build_pat)
    if filename and filename ~= "" then
      -- limpa possíveis espaços e o [Projeto] no final
      text = text:gsub("%s*%[.-%]%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
      table.insert(items, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = string.format("%s %s: %s", kind:lower(), code, text),
        type = (kind:lower():find("error") and "E") or "W",
      })
    end
  end
  return items
end

-------------------------------------------------
-- Parser de falhas de testes (dotnet test)
-- Captura o stacktrace no formato:
--    at Namespace.Class.Method() in /path/file.cs:line 42
-------------------------------------------------
local function parse_dotnet_test(lines)
  local items = {}
  local current_test = nil
  local current_msg = nil

  local failed_pat = "^%s*Failed%s+(.+)%s+%["
  local msg_pat = "^%s*Error Message:%s*$"
  local stack_pat = "in%s+(.+):line%s+(%d+)"

  for _, line in ipairs(lines) do
    local test_name = line:match(failed_pat)
    if test_name then
      current_test = test_name:gsub("%s+$", "")
      current_msg = nil
    elseif line:match(msg_pat) then
      -- próxima linha normalmente contém a mensagem
      current_msg = true
    elseif current_msg == true and line:match("%S") then
      current_msg = line:gsub("^%s+", "")
    else
      local file, lnum = line:match(stack_pat)
      if file and lnum then
        local text = current_test
            and string.format("[%s] %s", current_test, current_msg or line)
          or (current_msg or line)

        table.insert(items, {
          filename = file,
          lnum = tonumber(lnum),
          col = 1,
          text = text,
          type = "E",
        })
        -- não zeramos current_test para permitir múltiplos frames do mesmo teste
      end
    end
  end
  return items
end

-------------------------------------------------
-- Função genérica de execução assíncrona
-------------------------------------------------
local function run_dotnet(cmd, args, title, parser)
  async.run(function()
    vim.notify("Rodando: " .. title .. " ...", vim.log.levels.INFO)

    local result = vim.system(
      { cmd, unpack(args) },
      {
        text = true,
        cwd = vim.fn.getcwd(),
      }
    ):wait()

    local output = (result.stdout or "") .. "\n" .. (result.stderr or "")
    local lines = vim.split(output, "\n", { trimempty = true })

    local items = parser(lines)

    vim.fn.setqflist({}, " ", {
      title = title,
      items = items,
    })

    if #items > 0 then
      vim.cmd("copen")
      vim.notify(string.format("%s terminou com %d problema(s)", title, #items), vim.log.levels.WARN)
    else
      vim.cmd("cclose")
      if result.code == 0 then
        vim.notify(title .. " → sucesso", vim.log.levels.INFO)
      else
        vim.notify(title .. " → falhou (sem erros parseáveis)", vim.log.levels.ERROR)
      end
    end
  end)
end

-------------------------------------------------
-- Atalhos prontos
-------------------------------------------------
vim.keymap.set("n", "<leader>xb", function()
  run_dotnet(
    "dotnet",
    { "build", "--nologo", "-clp:NoSummary", "-p:GenerateFullPaths=true" },
    "dotnet build",
    parse_dotnet_build
  )
end, { desc = "Quickfix Dotnet build" })

vim.keymap.set("n", "<leader>xt", function()
  run_dotnet(
    "dotnet",
    { "test", "--nologo", "--logger", "console;verbosity=detailed", "-p:GenerateFullPaths=true" },
    "dotnet test",
    parse_dotnet_test
  )
end, { desc = "Quickfix Dotnet Test" })
