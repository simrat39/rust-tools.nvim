-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params()
    return vim.lsp.util.make_position_params()
end

local latest_buf_id = nil

local function handler(_, _, result, _, _, _)
    -- echo a message when result is nil (meaning no macro under cursor) and
    -- exit
    if result == nil then
        vim.api.nvim_out_write("No macro under cursor!\n")
        return;
    end

    -- creates a buffer and gives back its buffer number
    local function create_buf()
        return vim.api.nvim_create_buf(true, true)
    end

    -- check if a buffer with the latest id is already open, if it is then
    -- delete it and continue, else create a new buffer
    if latest_buf_id == nil then
        latest_buf_id = create_buf()
    else
        vim.api.nvim_buf_delete(latest_buf_id, {})
        latest_buf_id = create_buf()
    end

    -- split the window to create a new buffer and set it to our window
    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, latest_buf_id)

    -- parse the lines from result to get a list of the desirable output
    -- Example:
    -- // Recursive expansion of the eprintln macro
    -- // ============================================

    -- {
    --   $crate::io::_eprint(std::fmt::Arguments::new_v1(&[], &[std::fmt::ArgumentV1::new(&(err),std::fmt::Display::fmt),]));
    -- }
    local function get_lines(t)
        local ret = {}

        local name = t.name
        local text = "// Recursive expansion of the " .. name .. " macro"
        table.insert(ret, text)
        table.insert(ret, "// " .. string.rep("=", string.len(text) - 3))
        table.insert(ret, "")

        local expansion = t.expansion
        for string in string.gmatch(expansion, "([^\n]+)") do
            table.insert(ret, string)
        end

        return ret
    end

    -- set filetpe to rust for syntax highlighting
    vim.api.nvim_buf_set_option(latest_buf_id, "filetype" ,"rust")
    vim.api.nvim_buf_set_name(latest_buf_id, "[EXPANSION].rs")
    -- write the expansion content to the buffer
    vim.api.nvim_buf_set_lines(latest_buf_id, 0, 0, false, get_lines(result))

    -- make the new buffer smaller
    vim.cmd('vertical resize -25')
end

-- Sends the request to rust-analyzer to get cargo.tomls location and open it
function M.expand_macro()
    vim.lsp.buf_request(0, "rust-analyzer/expandMacro", get_params(), handler)
end

return M
