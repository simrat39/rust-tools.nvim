local utils = require("rust-tools.utils.utils")
local util = vim.lsp.util
local config = require("rust-tools.config")

local M = {}

local function get_params()
	return vim.lsp.util.make_position_params()
end

M._state = { winnr = nil, commands = nil }
local set_keymap_opt = { noremap = true, silent = true }

-- run the command under the cursor, if the thing under the cursor is not the
-- command then do nothing
function M._run_command()
	local line = vim.api.nvim_win_get_cursor(M._state.winnr)[1]

	if line > #M._state.commands then
		return
	end

	local action = M._state.commands[line]

	M._close_hover()
	M.execute_rust_analyzer_command(action)
end

function M.execute_rust_analyzer_command(action)
	local fn = vim.lsp.commands[action.command]
	if fn then
		fn(action)
	end
end

function M._close_hover()
	if M._state.winnr ~= nil then
		vim.api.nvim_win_close(M._state.winnr, true)
	end
end

local function parse_commands()
	local prompt = {}

	for i, value in ipairs(M._state.commands) do
		if value.command == "rust-analyzer.gotoLocation" then
			table.insert(prompt, string.format("%d. Go to %s (%s)", i, value.title, value.tooltip))
		elseif value.command == "rust-analyzer.showReferences" then
			table.insert(prompt, string.format("%d. %s", i, "Go to " .. value.title))
		else
			table.insert(prompt, string.format("%d. %s", i, value.title))
		end
	end

	return prompt
end

function M.handler(_, result)
	if not (result and result.contents) then
		-- return { 'No information available' }
		return
	end

	local markdown_lines = util.convert_input_to_markdown_lines(result.contents)
	if result.actions then
		M._state.commands = result.actions[1].commands
		local prompt = parse_commands()
		local l = {}

		for _, value in ipairs(prompt) do
			table.insert(l, value)
		end

		markdown_lines = vim.list_extend(l, markdown_lines)
	end

	markdown_lines = util.trim_empty_lines(markdown_lines)

	if vim.tbl_isempty(markdown_lines) then
		-- return { 'No information available' }
		return
	end

	local bufnr, winnr = util.open_floating_preview(
		markdown_lines,
		"markdown",
		vim.tbl_extend("keep", config.options.tools.hover_actions, {
			focusable = true,
			focus_id = "rust-tools-hover-actions",
			close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
		})
	)

	if config.options.tools.hover_actions.auto_focus then
		vim.api.nvim_set_current_win(winnr)
	end

	if M._state.winnr ~= nil then
		return
	end

	-- update the window number here so that we can map escape to close even
	-- when there are no actions, update the rest of the state later
	M._state.winnr = winnr
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<Esc>",
		":lua require'rust-tools.hover_actions'._close_hover()<CR>",
		set_keymap_opt
	)

	vim.api.nvim_buf_attach(bufnr, false, {
		on_detach = function()
			M._state.winnr = nil
		end,
	})

	--- stop here if there are no possible actions
	if result.actions == nil then
		return
	end

	-- makes more sense in a dropdown-ish ui
	vim.api.nvim_win_set_option(winnr, "cursorline", true)

	-- run the command under the cursor
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<CR>",
		":lua require'rust-tools.hover_actions'._run_command()<CR>",
		set_keymap_opt
	)
	-- close on escape
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<Esc>",
		":lua require'rust-tools.hover_actions'._close_hover()<CR>",
		set_keymap_opt
	)
end

-- Sends the request to rust-analyzer to get hover actions and handle it
function M.hover_actions()
	utils.request(0, "textDocument/hover", get_params(), M.handler)
end

return M
