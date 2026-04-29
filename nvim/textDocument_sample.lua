---Select an item using fzf
---@param entries lsp.CompletionItem[]
local function select_fzf(entries)
  -- Need to format items before calling fzf
  local source = {} ---@type string[]
  for idx, c in ipairs(entries) do
    source[idx] = ('%d. %s'):format(idx, c.labelDetails or c.label)
  end

  local wrapped = vim.fn['fzf#wrap']('test', {
    source = source,
    options = { '--no-multi', '--prompt', 'Snippets> ' },
    sink = nil,
    ['sink*'] = 0,
  }, 0)
  wrapped['sink*'] = function(lines)
    for _, line in ipairs(lines) do
      local idx = assert(tonumber(line:match("(%d+)[.]"))) -- e.g. "1. Some action"
      local item = entries[idx]
      local exp = item.textEdit and item.textEdit.newText or (item.insertText or '')
      vim.snippet.expand(exp)
    end
  end

  vim.fn['fzf#run'](wrapped)
end


---Select an item using vim.is.select
---@param entries lsp.CompletionItem[]
local function select_vim_ui(entries)
  vim.ui.select(entries, {
    format_item = function(c)
      return ('%s'):format(c.labelDetails or c.label)
    end,
    prompt = 'Snippets> ',
  }, function (item, idx)
    ---@cast item lsp.CompletionItem
    local exp = item.textEdit and item.textEdit.newText or (item.insertText or '')
    vim.snippet.expand(exp)
  end)
end

local function get_snippets()
  local buf = vim.api.nvim_get_current_buf()
  vim.lsp.buf_request_all(buf, 'textDocument/completion', vim.lsp.util.make_position_params(0, 'utf-16'), function(results)
    ---@type lsp.CompletionItem[]
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

        return true
      end)
      :totable()

    select_fzf(entries)
    -- select_vim_ui(entries)
  end)
end
vim.api.nvim_create_user_command('Test', get_snippets, { bang = true, force = true })

