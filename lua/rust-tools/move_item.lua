-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params(up)
    local direction = up and "Up" or "Down"
    local params = vim.lsp.util.make_range_params()
    params.direction = direction

    return params
end

-- move it baby
local function handler(_, _, result, _, _, _)
    if result == nil then return end
    vim.lsp.util.apply_text_document_edit(result)
end

-- Sends the request to rust-analyzer to move the item and handle the response
function M.move_item(up)
    vim.lsp.buf_request(0, "experimental/moveItem", get_params(up or false), handler)
end

return M
