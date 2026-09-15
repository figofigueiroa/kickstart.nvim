return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      -- Mapeamentos buffer-local (extensão do LazyVim mantida)
      keys = {
        goto_next_start = {
          [']f'] = '@function.outer',
          [']c'] = '@class.outer',
          [']a'] = '@parameter.inner',
          [']o'] = { '@block.outer', '@conditional.outer', '@loop.outer' }, -- bl[o]ck (mini.ai)
          [']u'] = '@call.outer', -- [u]sage (mini.ai)
          [']r'] = '@return.outer',
          [']s'] = '@statement.outer',
          [']n'] = '@number.inner',
          [']/'] = '@comment.outer',
          [']@'] = '@attribute.outer',
          [']='] = '@assignment.outer',
        },
        goto_next_end = {
          [']F'] = '@function.outer',
          [']C'] = '@class.outer',
          [']A'] = '@parameter.inner',
          [']O'] = { '@block.outer', '@conditional.outer', '@loop.outer' },
          [']U'] = '@call.outer',
          [']R'] = '@return.outer',
          [']S'] = '@statement.outer',
          [']N'] = '@number.inner',
        },
        goto_previous_start = {
          ['[f'] = '@function.outer',
          ['[c'] = '@class.outer',
          ['[a'] = '@parameter.inner',
          ['[o'] = { '@block.outer', '@conditional.outer', '@loop.outer' },
          ['[u'] = '@call.outer',
          ['[r'] = '@return.outer',
          ['[s'] = '@statement.outer',
          ['[n'] = '@number.inner',
          ['[/'] = '@comment.outer',
          ['[@'] = '@attribute.outer',
          ['[='] = '@assignment.outer',
        },
        goto_previous_end = {
          ['[F'] = '@function.outer',
          ['[C'] = '@class.outer',
          ['[A'] = '@parameter.inner',
          ['[O'] = { '@block.outer', '@conditional.outer', '@loop.outer' },
          ['[U'] = '@call.outer',
          ['[R'] = '@return.outer',
          ['[S'] = '@statement.outer',
          ['[N'] = '@number.inner',
        },
      },
    },
  },
  config = function(_, opts)
    local TS = require 'nvim-treesitter-textobjects'
    if not TS.setup then
      vim.notify('nvim-treesitter-textobjects: atualize o nvim-treesitter com :Lazy', vim.log.levels.ERROR)
      return
    end
    TS.setup(opts)

    local function attach(buf)
      local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype or '')
      if not (vim.tbl_get(opts, 'move', 'enable') and lang) then return end
      -- Só anexa se houver parser carregável e queries de textobjects
      -- (equivalente nativo do LazyVim.treesitter.have(ft, 'textobjects')).
      if not vim.treesitter.language.add(lang) then return end
      if not vim.treesitter.query.get(lang, 'textobjects') then return end

      ---@type table<string, table<string, string>>
      local moves = vim.tbl_get(opts, 'move', 'keys') or {}

      for method, keymaps in pairs(moves) do
        for key, query in pairs(keymaps) do
          local queries = type(query) == 'table' and query or { query }
          local parts = {}
          for _, q in ipairs(queries) do
            local part = q:gsub('@', ''):gsub('%..*', '')
            part = part:sub(1, 1):upper() .. part:sub(2)
            table.insert(parts, part)
          end
          local desc = table.concat(parts, ' or ')
          desc = (key:sub(1, 1) == '[' and 'Prev ' or 'Next ') .. desc
          local second = key:sub(2, 2)
          desc = desc .. (second:match '%l' and ' Start' or second:match '%u' and ' End' or '')
          vim.keymap.set({ 'n', 'x', 'o' }, key, function()
            -- ]c/[c continuam sendo os jumps de diff quando em diff
            if vim.wo.diff and key:find '[cC]' then return vim.cmd('normal! ' .. key) end
            require('nvim-treesitter-textobjects.move')[method](query, 'textobjects')
          end, {
            buffer = buf,
            desc = desc,
            silent = true,
          })
        end
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('user-ts-textobjects', { clear = true }),
      callback = function(ev) attach(ev.buf) end,
    })
    vim.tbl_map(attach, vim.api.nvim_list_bufs())
  end,
}
