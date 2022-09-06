local rt = require("rust-tools")

local M = {}

local function get_opts()
  local params = vim.lsp.util.make_range_params()
  -- set start and end of selection
  local start_m = vim.api.nvim_buf_get_mark(0, "<")
  local end_m = vim.api.nvim_buf_get_mark(0, ">")
  params.range.start = {
    character = start_m[2],
    line = start_m[1] - 1, -- vim starts counting at 1, but lsp at 0
  }
  params.range["end"] = {
    character = end_m[2],
    line = end_m[1] - 1, -- vim starts counting at 1, but lsp at 0
  }
  params.position = params.range
  params.range = nil
  --print(vim.inspect(params))

  return params
end

function M.hover_range()
  rt.utils.request(0, "textDocument/hover", get_opts())
end

return M
