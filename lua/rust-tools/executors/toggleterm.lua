local utils = require("rust-tools.utils.utils")

local M = {}

function M.execute_command(command, args, cwd)
	local ok, term = pcall(require, "toggleterm.terminal")
	if not ok then
		vim.schedule(function()
			vim.notify("toggleterm not found.", vim.log.levels.ERROR)
		end)
		return
	end

	term.Terminal
		:new({
			dir = cwd,
			cmd = utils.make_command_from_args(command, args),
			close_on_exit = false,
		})
		:toggle()
end

return M
