local rt = require("rust-tools")

local M = {}

local function get_params()
  local params = vim.lsp.util.make_range_params()
  local range = params.range

  params.range = nil
  params.ranges = { range }

  return params
end

local function handler(_, result, ctx)
  vim.lsp.util.apply_text_edits(
    result,
    ctx.bufnr,
    vim.lsp.get_client_by_id(ctx.client_id).offset_encoding
  )
end

-- Sends the request to rust-analyzer to get the TextEdits to join the lines
-- under the cursor and applies them
function M.join_lines()
  rt.utils.request(0, "experimental/joinLines", get_params(), handler)
end

return M
