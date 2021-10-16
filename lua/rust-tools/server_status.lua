local config = require("rust-tools.config")
local inlay = require("rust-tools.inlay_hints")

local M = {}

function M.handler(_, result)
	if result.quiescent and config.options.tools.autoSetHints and not M.ran_once then
		inlay.set_inlay_hints()
		require("rust-tools.inlay_hints").setup_autocmd()
		M.ran_once = true
	end
end

return M
