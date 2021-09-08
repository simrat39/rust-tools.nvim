-- ?? helps with all the warnings spam
local vim = vim

local M = {}

local function get_params()
	local params = vim.lsp.util.make_range_params()
	local range = params.range

	params.range = nil
	params.ranges = { range }

	return params
end

local function handler(...)
	local _args = { ... }
	local result, bufnr
	if vim.fn.has "nvim-0.5.1" == 1 then
		result = _args[2]
		bufnr = _args[3].bufnr
	else
		result = _args[3]
		bufnr = _args[5]
	end
	vim.lsp.util.apply_text_edits(result, bufnr)
end

-- Sends the request to rust-analyzer to get the TextEdits to join the lines
-- under the cursor and applies them
function M.join_lines()
	vim.lsp.buf_request(0, "experimental/joinLines", get_params(), handler)
end

return M
