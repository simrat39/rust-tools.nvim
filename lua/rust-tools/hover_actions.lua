-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params()
    return vim.lsp.util.make_position_params()
end

local function handler(_, _, result, _, _, _)
    if result.actions == nil then
       return
    end

    local commands = result.actions[1].commands

    local type = commands[1].command

    local prompt = {"Select action: "}

    for i, value in ipairs(commands) do
        if value.command == "rust-analyzer.gotoLocation" then
            table.insert(prompt, string.format("%d: %s", i, "Go to " .. value.tooltip))
        else
            table.insert(prompt, string.format("%d: %s", i, "Go to " .. value.title))
        end
    end

    local choice = vim.fn.inputlist(prompt)

    if choice < 1 or choice > #commands then
       return
    end

    if type == "rust-analyzer.gotoLocation" then
        vim.lsp.util.jump_to_location(commands[choice].arguments[1])
    else
        vim.lsp.buf.implementation()
    end
end

-- Sends the request to rust-analyzer to get hover actions and handle it
function M.hover_actions()
    vim.lsp.buf_request(0, "textDocument/hover", get_params(), handler)
end

return M
