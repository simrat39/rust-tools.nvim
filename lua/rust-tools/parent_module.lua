-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params()
    return vim.lsp.util.make_position_params();
end

local function handler(...)
    local _args = { ... }
    local result
    if vim.fn.has 'nvim-0.5.1' == 1 then
        result = _args[2]
    else
        result = _args[3]
    end
    if result == nil or vim.tbl_isempty(result) then
       vim.api.nvim_out_write("Can't find parent module\n")
       return;
    end

    local location = result

    if vim.tbl_islist(result) then
       location = result[1]
    end

    vim.lsp.util.jump_to_location(location)
end

-- Sends the request to rust-analyzer to get the parent modules location and open it
function M.parent_module()
    vim.lsp.buf_request(0, "experimental/parentModule", get_params(), handler)
end

return M
