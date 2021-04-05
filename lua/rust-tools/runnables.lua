-- ?? helps with all the warnings spam
local vim = vim
local utils = require('rust-tools.utils.utils')

local M = {}

local function get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = nil, -- get em all
    }
end

local latest_buf_id = nil

local function getOptions(result, withTitle, withIndex)
    local option_strings = withTitle and {"Runnables: "} or {}

    for i, runnable in ipairs(result) do
        local str = withIndex
                    and string.format("%d: %s", i, runnable.label)
                    or runnable.label
        table.insert(option_strings, str)
    end

    return option_strings
end

local function getCommand(c, results)
    local ret = " "
    local args = results[c].args

    for _, value in ipairs(args.cargoArgs) do
        ret = ret .. value .. " "
    end

    for _, value in ipairs(args.cargoExtraArgs) do
        ret = ret .. value .. " "
    end

    if not vim.tbl_isempty(args.executableArgs) then
        ret = ret .. "-- "
        for _, value in ipairs(args.executableArgs) do
        ret = ret .. value .. " "
        end
    end

    return ret
end

local function run_command(choice, result)
    -- do nothing if choice is too high or too low
    if choice < 1 or choice > #result then
       return
    end

    -- check if a buffer with the latest id is already open, if it is then
    -- delete it and continue
    utils.delete_buf(latest_buf_id)

    -- create the new buffer
    latest_buf_id = vim.api.nvim_create_buf(false, true)

    -- split the window to create a new buffer and set it to our window
    utils.split(false, latest_buf_id)

    -- make the new buffer smaller
    utils.resize(false, "-5")

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

local function handler(_, _, result, _, _, _)
    -- get the choice from the user
    local choice = vim.fn.inputlist(getOptions(result, true, true))

    run_command(choice, result)

end

local function get_telescope_handler(opts)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    return function (_, _, results)
        local choices = getOptions(results, false, false)

        local function attach_mappings(bufnr, map)
            local function on_select()
                local choice = action_state.get_selected_entry().index

                actions.close(bufnr)
                run_command(choice, results)
            end

            map('n', '<CR>', on_select)
            map('i', '<CR>', on_select)

            -- Additional mappings don't push the item to the tagstack.
            return true
        end

        pickers.new(opts or {} ,{
            prompt_title = "Runnables",
            finder = finders.new_table({
                results = choices,
            }),
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = nil,
            attach_mappings = attach_mappings,
        }):find()
    end
end

-- Sends the request to rust-analyzer to get the runnables and handles them
function M.runnables()
    vim.lsp.buf_request(0, "experimental/runnables", get_params(), handler)
end

-- Same thing but with telescope.nvim
function M.runnables_telescope(opts)
    vim.lsp.buf_request(0, "experimental/runnables", get_params(), get_telescope_handler(opts))
end

return M
