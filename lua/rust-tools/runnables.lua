local utils = require("rust-tools.utils.utils")
local config = require("rust-tools.config")

local M = {}

local function get_params()
	return {
		textDocument = vim.lsp.util.make_text_document_params(),
		position = nil, -- get em all
	}
end

local function getOptions(result, withTitle, withIndex)
	local option_strings = withTitle and { "Runnables: " } or {}

	for i, runnable in ipairs(result) do
		local str = withIndex and string.format("%d: %s", i, runnable.label) or runnable.label
		table.insert(option_strings, str)
	end

	return option_strings
end

---comment
---@return string build command
---@return string|table args
---@return any cwd
local function getCommand(c, results)
	local ret = " "
	local args = results[c].args

	local dir = args.workspaceRoot

	ret = vim.list_extend({}, args.cargoArgs or {})
	ret = vim.list_extend(ret, args.cargoExtraArgs or {})
	table.insert(ret, "--")
	ret = vim.list_extend(ret, args.executableArgs or {})

	return "cargo", ret, dir
end

function M.run_command(choice, result)
	-- do nothing if choice is too high or too low
	if choice < 1 or choice > #result then
		return
	end

	local opts = config.options.tools

	local command, args, cwd = getCommand(choice, result)

	opts.executor.execute_command(command, args, cwd)
end

local function handler(_, result)
    -- get the choice from the user
    vim.ui.select(getOptions(result, true, true), { prompt = "Runnables" }, function(choice)
        M.run_command(choice, result)
    end)
end

-- Sends the request to rust-analyzer to get the runnables and handles them
-- Uses vim.ui.select which defaults to vanilla vim but can be overriden to a telescope based searcher
function M.runnables()
    local used_handler = handler or config.options.tools.runnables.select
	utils.request(0, "experimental/runnables", get_params(), used_handler)
end

return M
