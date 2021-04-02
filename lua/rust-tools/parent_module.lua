-- ?? helps with all the warnings spam
local vim = vim

local M = {}

-- Sends the request to rust-analyzer to get the parent modules location and open it
function M.parent_module()
    vim.lsp.buf_request(0, "experimental/parentModule", M.get_params(), M.handler)
end

function M.get_params()
    return vim.lsp.util.make_position_params();
end

function M.handler(_, _, result, _, _, _)
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

return M
