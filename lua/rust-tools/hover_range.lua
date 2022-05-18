local M = {}

-- Converts a tuple of range coordinates into LSP's position argument
local function make_lsp_position(row1, col1, row2, col2)
  -- Note: vim's lines are 1-indexed, but LSP's are 0-indexed
  return {
    ["start"] = {
      line = row1 - 1,
      character = col1,
    },
    ["end"] = {
      line = row2 - 1,
      character = col2,
    },
  }
end

local function get_visual_selected_range()
  -- Taken from https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
  local p1 = vim.fn.getpos("v")
  local row1 = p1[2]
  local col1 = p1[3]
  local p2 = vim.api.nvim_win_get_cursor(0)
  local row2 = p2[1]
  local col2 = p2[2]

  if row1 < row2 then
    return make_lsp_position(row1, col1, row2, col2)
  elseif row2 < row1 then
    return make_lsp_position(row2, col2, row1, col1)
  end

  return make_lsp_position(
    row1,
    math.min(col1, col2),
    row1,
    math.max(col1, col2)
  )
end

local function get_opts()
  local params = vim.lsp.util.make_range_params()
  params.position = get_visual_selected_range()
  params.range = nil
  return params
end

function M.hover_range()
  vim.lsp.buf_request(0, "textDocument/hover", get_opts())
end

return M
