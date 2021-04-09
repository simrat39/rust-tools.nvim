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

function M.make_telescope_handler(opts)
    return function(_, _, result, _, _, _)
        if not result or vim.tbl_isempty(result.actions or {}) then
            print(opts.no_results_message)
            return
        end

        local goto_cmd = "rust-analyzer.gotoLocation"
        local commands = result.actions[1].commands
        local items = {}

        for idx, value in ipairs(commands) do
            local title
            if value.command == goto_cmd then
                title = string.format("Go to %s", value.tooltip)
            else
                title = string.format("Go to %s", value.title)
            end

            table.insert(items, {
                idx = idx,
                title = title,
                value = value,
            })
        end

        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local sorters = require('telescope.sorters')
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        local function apply_edit_fn(prompt_bufnr)
            return function()

                local selection = action_state.get_selected_entry(prompt_bufnr)
                actions.close(prompt_bufnr)
                if not selection then
                    return
                end

                local value = selection.value
                print(vim.inspect(value))
                if value.command ==  goto_cmd  then
                    vim.lsp.util.jump_to_location(value.arguments[1])
                else
                    vim.lsp.buf.implementation()
                end
            end
        end

        local function attach_hover_actions_mappings(prompt_bufnr, map)
            map('i', '<CR>', apply_edit_fn(prompt_bufnr))
            map('n', '<CR>', apply_edit_fn(prompt_bufnr))

            return true
        end

        pickers.new(opts.telescope or {}, {
            prompt_title = "Hover Actions",
            finder = finders.new_table({
                results = items,
                entry_maker = function(line)
                    return {
                        valid = line ~= nil,
                        value = line.value,
                        ordinal = line.idx .. line.title,
                        display = string.format("%d: %s", line.idx, line.title),
                    }
                end,
            }),
            attach_mappings = attach_hover_actions_mappings,
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = nil,
        }):find()
    end
end

-- Sends the request to rust-analyzer to get hover actions and handle it
function M.hover_actions(custom_handler)
    local hover_handler = custom_handler or handler
    vim.lsp.buf_request(0, "textDocument/hover", get_params(), hover_handler)
end

return M
