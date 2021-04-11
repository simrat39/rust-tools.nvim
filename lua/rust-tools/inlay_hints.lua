local M = {}
-- ?? helps with all the warnings spam
local vim = vim

-- Update inlay hints when opening a new buffer and when writing a buffer to a
-- file
-- opts is a string representation of the table of options
function M.setup_autocmd(opts)
    vim.api.nvim_command('augroup InlayHints')
    vim.api.nvim_command('autocmd InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs :lua require"rust-tools.inlay_hints".set_inlay_hints(' .. opts .. ')')
    vim.api.nvim_command('augroup END')
end

local function get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
    }
end

local namespace = vim.api.nvim_create_namespace("rust-analyzer/inlayHints")

-- parses the result into a easily parsable format
-- example:
--{
--  ["12"] = { {
--      kind = "TypeHint",
--      label = "String"
--    } },
--  ["13"] = { {
--      kind = "TypeHint",
--      label = "usize"
--    } },
--  ["15"] = { {
--      kind = "ParameterHint",
--      label = "styles"
--    }, {
--      kind = "ParameterHint",
--      label = "len"
--    } },
--  ["7"] = { {
--      kind = "ChainingHint",
--      label = "Result<String, VarError>"
--    }, {
--      kind = "ParameterHint",
--      label = "key"
--    } },
--  ["8"] = { {
--      kind = "ParameterHint",
--      label = "op"
--    } }
--}
--
local function parseHints(result)
    local map = {}

    if type(result) ~= 'table' then
        return {}
    end
    for _, value in pairs(result) do
        local line = tostring(value.range["end"].line)
        local label = value.label
        local kind = value.kind

        if map[line] ~= nil then
           table.insert(map[line], {label=label, kind=kind})
        else
            map[line] = {{label=label, kind=kind}}
        end
    end
    return map
end

local function get_handler(opts)
    if opts.show_parameter_hints == nil then opts.show_parameter_hints = true end

    return function(_, _, result, _, bufnr, _)
        -- clean it up at first
        M.disable_inlay_hints()

        local ret = parseHints(result)

        for key, value in pairs(ret) do
            local virt_text = ""
            local line = tonumber(key)

            local param_hints = {}
            local other_hints = {}

            -- segregate paramter hints and other hints
            for _, value_inner in ipairs(value) do
                if value_inner.kind == "ParameterHint" then
                   table.insert(param_hints, value_inner.label)
                else
                   table.insert(other_hints, value_inner.label)
                end
            end

            -- show parameter hints inside brackets with commas and a thin arrow
            if not vim.tbl_isempty(param_hints) and opts.show_parameter_hints then
                virt_text = virt_text .. "<- ("
                for i, value_inner_inner in ipairs(param_hints) do
                   virt_text = virt_text .. value_inner_inner
                   if i ~= #param_hints then
                      virt_text = virt_text .. ", "
                   end
                end
                virt_text = virt_text .. ") "
            end

            -- show other hints with commas and a thicc arrow
            if not vim.tbl_isempty(other_hints) then
                virt_text = virt_text .. "=> "
                for i, value_inner_inner in ipairs(other_hints) do
                   virt_text = virt_text .. value_inner_inner
                   if i ~= #other_hints then
                      virt_text = virt_text .. ", "
                   end
                end
            end

            -- set the virtual text
            vim.api.nvim_buf_set_virtual_text(bufnr, namespace, line, {{virt_text, "Comment"}}, {})
        end
    end
end

function M.disable_inlay_hints()
    -- clear namespace which clears the virtual text as well
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
end

-- Sends the request to rust-analyzer to get the inlay hints and handle them
function M.set_inlay_hints(opts)
    opts = opts or {}
    vim.lsp.buf_request(0, "rust-analyzer/inlayHints", get_params(), get_handler(opts))
end

return M
