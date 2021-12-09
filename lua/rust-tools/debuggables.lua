local rt_dap = require('rust-tools.dap')
local config = require('rust-tools.config')
local utils = require('rust-tools.utils.utils')

local M = {}

local function get_params()
    return {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = nil -- get em all
    }
end

local function build_label(args)
    local ret = ""
    for _, value in ipairs(args.cargoArgs) do ret = ret .. value .. " " end

    for _, value in ipairs(args.cargoExtraArgs) do ret = ret .. value .. " " end

    if not vim.tbl_isempty(args.executableArgs) then
        ret = ret .. "-- "
        for _, value in ipairs(args.executableArgs) do
            ret = ret .. value .. " "
        end
    end
    return ret
end

local function getOptions(result, withTitle, withIndex)
    local option_strings = withTitle and {"Debuggables: "} or {}

    for i, debuggable in ipairs(result) do
        local label = build_label(debuggable.args)
        local str =
            withIndex and string.format("%d: %s", i, label) or
                label
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
-- This function also makes it so that the debuggable commands are more
-- debugging friendly. For example, we move cargo run to cargo build, and cargo
-- test to cargo test --no-run.
local function sanitize_results_for_debugging(result)
    local ret = {}

    ret = vim.tbl_filter(function(value) return is_valid_test(value.args) end,
                         result)

    for i, value in ipairs(ret) do
        if value.args.cargoArgs[1] == "run" then
            ret[i].args.cargoArgs[1] = "build"
        elseif value.args.cargoArgs[1] == "test" then
            table.insert(ret[i].args.cargoArgs, 2, "--no-run")
        end
    end

    return ret
end

local function handler(_, result)
    result = sanitize_results_for_debugging(result)

    -- get the choice from the user
    vim.ui.select(getOptions(result, true, true), { prompt = "Debuggables" }, function(choice)
        rt_dap.start(result[choice].args)
    end)
end

-- Sends the request to rust-analyzer to get the runnables and handles them
-- Uses vim.ui.select which defaults to vanilla vim but can be overriden to a telescope based searcher
function M.debuggables()
    local used_handler = handler or config.options.tools.debuggables.select
    utils.request(0, "experimental/runnables", get_params(), used_handler)
end

return M
