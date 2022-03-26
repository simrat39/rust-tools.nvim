local config = require("rust-tools.config")
local inlay = require("rust-tools/inlay_hints")

local M = {}

function M.handler(_, result)
  if result.quiescent and not M.ran_once then
    if config.options.tools.autoSetHints then
      inlay.set_inlay_hints()
      inlay.setup_autocmd()
    end
    if config.options.tools.on_initialized then
      config.options.tools.on_initialized(result)
    end
    M.ran_once = true
  end
end

return M
