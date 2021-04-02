-- ?? helps with all the warnings spam
local vim = vim

local M = {}

-- Sends the request to rust-analyzer to get cargo.tomls location and open it
function M.open_cargo_toml()
    vim.lsp.buf_request(0, "experimental/openCargoToml", M.get_params(), M.handler)
end

function M.get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
    }
end

function M.handler(_, _, result, _, _, _)
    vim.lsp.util.jump_to_location(result)
end

return M
