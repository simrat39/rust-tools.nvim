-- ?? helps with all the warnings spam
local vim = vim
local utils = require('rust-tools.utils.utils')

local M = {}

local function get_params(up)
    local direction = up and "Up" or "Down"
    local params = vim.lsp.util.make_range_params()
    params.direction = direction

    return params
end

-- move it baby
local function handler(...)
    local _args = { ... }
    local result
    if vim.fn.has 'nvim-0.5.1' == 1 then
        result = _args[2]
    else
        result = _args[3]
    end
    if result == nil then return end
    utils.snippet_text_edits_to_text_edits(result)
    vim.lsp.util.apply_text_edits(result)
end

-- Sends the request to rust-analyzer to move the item and handle the response
function M.move_item(up)
    vim.lsp.buf_request(0, "experimental/moveItem", get_params(up or false), handler)
end

return M
