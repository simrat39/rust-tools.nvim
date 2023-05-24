local rt = require("rust-tools")

local M = {}

local function pos_to_lsp_pos(vim_pos)
  return {
    line = vim_pos[2] - 1,
    character = vim_pos[3]
  }
end

local function get_opts()
  local range = vim.lsp.util.make_range_params()

  local start_pos = pos_to_lsp_pos(vim.fn.getpos("v"))
  local end_pos = pos_to_lsp_pos(vim.fn.getpos("."))
  -- vim.notify("start_pos: " .. vim.inspect(start_pos), vim.log.levels.INFO)
  -- vim.notify("end_pos: " .. vim.inspect(end_pos), vim.log.levels.INFO)

  local params = {}
  params.textDocument = range.textDocument
  if start_pos == end_pos then
    params.position = start_pos
  else
    params.position = {
      start = start_pos,
      ["end"] = end_pos,
    }
  end

  return params
end

function M.hover_range()
  -- rt.utils.request(0, "textDocument/hover", get_opts(), function(...)
  --   vim.print("Callback:")
  --   vim.print(...)
  --   vim.print("End of callback")
  -- end)
  -- vim.notify(vim.inspect(get_opts()), vim.log.levels.INFO)
  rt.utils.request(0, "textDocument/hover", get_opts(), function(...)
    -- vim.print(...)
    require("rust-tools.hover_actions").handler(...)
  end)
end

return M
