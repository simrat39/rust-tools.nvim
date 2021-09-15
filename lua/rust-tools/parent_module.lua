local utils = require('rust-tools.utils.utils')
local vim = vim

local M = {}

local function get_params()
    return vim.lsp.util.make_position_params();
end

local function handler(_, result)
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
    utils.request(0, "experimental/parentModule", get_params(), handler)
end

return M
