local rt_dap = require('rust-tools.dap')
local config = require('rust-tools.config')

local M = {}

local function get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = nil -- get em all
    }
end

local function getOptions(result, withTitle, withIndex)
    local option_strings = withTitle and {"Debuggables: "} or {}

    for i, debuggable in ipairs(result) do
        local str = withIndex and string.format("%d: %s", i, debuggable.label) or
                        debuggable.label
        table.insert(option_strings, str)
    end

    return option_strings
end

local function is_valid_test(args)
    local is_not_cargo_check = args.cargoArgs[1] ~= "check"
    return is_not_cargo_check
end

-- rust-analyzer doesn't actually support giving a list of debuggable targets,
-- so work around that by manually removing non debuggable targets (only cargo
-- check for now).
local function sanitize_non_debuggables(result)
    return vim.tbl_filter(function (value)
       return is_valid_test(value.args)
    end, result)
end

local function handler(_, _, result)
    result = sanitize_non_debuggables(result)

    -- get the choice from the user
    local choice = vim.fn.inputlist(getOptions(result, true, true))
    local args = result[choice].args
    rt_dap.start(args)
end

local function get_telescope_handler(opts)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    return function(_, _, results)
        results = sanitize_non_debuggables(results)
        local choices = getOptions(results, false, false)

        local function attach_mappings(bufnr, map)
            local function on_select()
                local choice = action_state.get_selected_entry().index

                actions.close(bufnr)
                local args = results[choice].args
                rt_dap.start(args)
            end

            map('n', '<CR>', on_select)
            map('i', '<CR>', on_select)

            -- Additional mappings don't push the item to the tagstack.
            return true
        end

        pickers.new(opts or {}, {
            prompt_title = "Debuggables",
            finder = finders.new_table({results = choices}),
            sorter = sorters.get_generic_fuzzy_sorter(),
            previewer = nil,
            attach_mappings = attach_mappings
        }):find()
    end
end

-- Sends the request to rust-analyzer to get the runnables and handles them
-- The opts provided here are forwarded to telescope, other than use_telescope
-- which is used to check whether we want to use telescope or the vanilla vim
-- way for input
function M.debuggables()
    local opts = config.options.tools.debuggables

    -- this is the handler which is actually used, hence its the used handler
    local used_handler = handler

    -- if the user has both telescope installed and option set to use telescope
    if pcall(require, 'telescope') and opts.use_telescope then
        used_handler = get_telescope_handler(opts)
    end

    -- fallback to the vanilla method incase telescope is not installed or the
    -- user doesn't want to use it
    vim.lsp.buf_request(0, "experimental/runnables", get_params(), used_handler)
end

return M
