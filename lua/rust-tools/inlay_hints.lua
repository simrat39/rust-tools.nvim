local M = {}
-- ?? helps with all the warnings spam
local vim = vim

-- Update inlay hints when opening a new buffer and when writing a buffer to a
-- file
function M.setup()
    vim.api.nvim_command('augroup InlayHints')
    vim.api.nvim_command('autocmd BufEnter,BufWinEnter,TabEnter *.rs :lua require"rust-tools.inlay_hints".set_inlay_hints()')
    vim.api.nvim_command('augroup END')
end

-- Sends the request to rust-analyzer to get the inlay hints and handle them
function M.set_inlay_hints()
    vim.lsp.buf_request(0, "rust-analyzer/inlayHints", M.get_params(), M.handler)
end

function M.get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
    }
end

local namespace = vim.api.nvim_create_namespace("rust-analyzer/inlayHints")

function M.handler(_, _, result, _, bufnr, _)
    -- clear namespace which clears the virtual text as well
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

    for _, value in pairs(result) do
        local kind = value.kind
        local label = value.label
        local line = value.range["end"].line

        -- neovim virtual text does not support putting stuff inside the text,
        -- only at the end, which renders parameter hints useless (i think
        -- atleast)
        -- TODO: Make pre arrow thingy configurable
        if kind ~= "ParameterHint" then
            vim.api.nvim_buf_set_virtual_text(bufnr, namespace, line, {{"-> " .. label, "Comment"}}, {})
        end
    end
end

return M
