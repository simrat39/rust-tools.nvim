local rt = require("rust-tools")

local M = {}

local function get_params()
  return vim.lsp.util.make_range_params()
end

local latest_buf_id = nil

local function parse_lines(result)
  local ret = {}

  for line in string.gmatch(result, "([^\n]+)") do
    table.insert(ret, line)
  end

  return ret
end

local function handler(_, result)
  -- check if a buffer with the latest id is already open, if it is then
  -- delete it and continue
  rt.utils.delete_buf(latest_buf_id)

  -- create a new buffer
  latest_buf_id = vim.api.nvim_create_buf(false, true) -- not listed and scratch

  -- split the window to create a new buffer and set it to our window
  rt.utils.split(true, latest_buf_id)

  vim.api.nvim_buf_set_name(latest_buf_id, "syntax.rust")
  vim.api.nvim_buf_set_text(latest_buf_id, 0, 0, 0, 0, parse_lines(result))

  rt.utils.resize(true, "-25")
end

function M.syntax_tree()
  rt.utils.request(0, "rust-analyzer/syntaxTree", get_params(), handler)
end

return M
