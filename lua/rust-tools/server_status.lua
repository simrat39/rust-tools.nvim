local rt = require("rust-tools")

local M = {}

function M.handler(_, result)
  if result.quiescent and not M.ran_once then
    if rt.config.options.tools.inlay_hints.auto then
      rt.inlay_hints.enable()
    end
    if rt.config.options.tools.on_initialized then
      rt.config.options.tools.on_initialized(result)
    end
    M.ran_once = true
  end
end

return M
