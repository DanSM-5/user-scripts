local function get_snippets()
  local buf = vim.api.nvim_get_current_buf()
  vim.lsp.buf_request_all(buf, 'textDocument/completion', vim.lsp.util.make_position_params(0, 'utf-16'), function(results)
    local source = {} ---@type string[]
    local entries = vim.iter(vim.tbl_values(results))
      :filter(function (res)
        ---@cast res { err: lsp.ResponseError; result: lsp.CompletionItem[]|lsp.CompletionList }
        return not (res.err or not res.result)
      end)
      :map(function(res)
        ---@cast res { result: lsp.CompletionItem[]|lsp.CompletionList }
        return res.result.items and res.result.items or res.result
      end)
      :flatten(1)
      :filter(function(c)
        ---@cast c lsp.CompletionItem
        if c.kind ~= 15 then return false end

        local idx = #source+1
        source[idx] = ('%d. %s'):format(idx, c.labelDetails or c.label)
        return true
      end)
      :totable()

    local wrapped = vim.fn['fzf#wrap']('test', {
      source = source,
      options = { '--no-multi' },
      sink = nil,
      ['sink*'] = 0,
    }, 0)
    wrapped['sink*'] = function(lines)
      for _, line in ipairs(lines) do
        local idx = assert(tonumber(line:match("(%d+)[.]"))) -- e.g. "1. Some action"
        local exp = entries[idx].textEdit and entries[idx].textEdit.newText or (entries[idx].insertText or '')
        vim.snippet.expand(exp)
      end
    end

    vim.fn['fzf#run'](wrapped)
  end)
end
vim.api.nvim_create_user_command('Test', get_snippets, { bang = true, force = true })
