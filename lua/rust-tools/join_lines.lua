-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params()
    local params = vim.lsp.util.make_range_params()
    local range = params.range

    params.range = nil
    params.ranges = {range}

    return params
end

local function handler(_, _, result, _, bufnr, _)
    vim.lsp.util.apply_text_edits(result, bufnr)
end

-- Sends the request to rust-analyzer to get the TextEdits to join the lines
-- under the cursor and applies them
function M.join_lines()
    vim.lsp.buf_request(0, "experimental/joinLines", get_params(), handler)
end

return M
