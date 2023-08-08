local rt = require("rust-tools")

local M = {}

local function get_opts(query)
  local opts = vim.lsp.util.make_position_params()
  opts.query = query
  opts.parseOnly = false
  opts.selections = { vim.lsp.util.make_range_params().range }
  return opts
end

local function handler(err, result, ctx)
  if err then
    error("Could not execute request to server: " .. err.message)
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client then
    return
  end

  vim.lsp.util.apply_workspace_edit(result, client.offset_encoding)
end

function M.ssr(query)
  if not query then
    vim.ui.input({ prompt = "Enter query: " }, function(input)
      query = input
      if query then
        M.ssr(query)
      end
    end)
  end

  if query then
    rt.utils.request(0, "experimental/ssr", get_opts(query), handler)
  end
end

return M
