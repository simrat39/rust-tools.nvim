-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = nil, -- get em all
    }
end

local latest_buf_id = nil

local function getOptions(result)
    local option_strings = {"Runnables: "}

    for i, runnable in ipairs(result) do
       table.insert(option_strings, string.format("%d: %s", i, runnable.label))
    end

    return option_strings
end

local function getCommand(c, results)
    local ret = " "
    for _, value in ipairs(results[c].args.cargoArgs) do
       ret = ret .. value .. " "
    end
    return ret
end

local function handler(_, _, result, _, _, _)
    -- get the choice from the user
    local choice = vim.fn.inputlist(getOptions(result))

    -- do nothing if choice is too high or too low
    if choice < 1 or choice > #result then
       return
    end

    -- creates a buffer and gives back its buffer number
    local function create_buf()
        return vim.api.nvim_create_buf(false, false)
    end

    -- check if a buffer with the latest id is already open, if it is then
    -- delete it and continue
    if latest_buf_id ~= nil then
        vim.api.nvim_buf_delete(latest_buf_id, {force=true})
    end

    -- create the new buffer
    latest_buf_id = create_buf()

    -- split the window to create a new buffer and set it to our window
    vim.cmd('split')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, latest_buf_id)

    -- make the new buffer smaller
    vim.cmd('resize -5')

    local command = "cargo" .. getCommand(choice, result)
    -- run the command
    vim.fn.termopen(command)

    -- when the buffer is closed, set the latest buf id to nil else there are
    -- some edge cases with the id being sit but a buffer not being open
    local function onDetach(_, _)
       latest_buf_id = nil
    end
    vim.api.nvim_buf_attach(latest_buf_id, false, {on_detach = onDetach})
end

-- Sends the request to rust-analyzer to get the runnables and handles them
function M.runnables()
    vim.lsp.buf_request(0, "experimental/runnables", get_params(), handler)
end

return M
