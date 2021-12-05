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

local function get_telescope_handler(opts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local sorters = require("telescope.sorters")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	return function(_, results)
		local choices = getOptions(results, false, false)

		local function attach_mappings(bufnr, map)
			local function on_select()
				local choice = action_state.get_selected_entry().index

				actions.close(bufnr)
				M.run_command(choice, results)
			end

			map("n", "<CR>", on_select)
			map("i", "<CR>", on_select)

			-- Additional mappings don't push the item to the tagstack.
			return true
		end

		pickers.new(opts or {}, {
			prompt_title = "Runnables",
			finder = finders.new_table({ results = choices }),
			sorter = sorters.get_generic_fuzzy_sorter(),
			previewer = nil,
			attach_mappings = attach_mappings,
		}):find()
	end
end

-- Sends the request to rust-analyzer to get the runnables and handles them
-- The opts provided here are forwarded to telescope, other than use_telescope
-- which is used to check whether we want to use telescope or the vanilla vim
-- way for input
function M.runnables()
	local opts = config.options.tools.runnables

	-- this is the handler which is actually used, hence its the used handler
	local used_handler = handler

	-- if the user has both telescope installed and option set to use telescope
	if pcall(require, "telescope") and opts.use_telescope then
		used_handler = get_telescope_handler(opts)
	end

	-- fallback to the vanilla method incase telescope is not installed or the
	-- user doesn't want to use it
	utils.request(0, "experimental/runnables", get_params(), used_handler)
end

return M
