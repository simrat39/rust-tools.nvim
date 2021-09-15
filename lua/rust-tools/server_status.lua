local config = require('rust-tools.config')
local inlay = require('rust-tools.inlay_hints')

local M = {}

function M.handler(_, result)
    if result.quiescent and config.options.tools.autoSetHints then
       inlay.set_inlay_hints();
    end
end

return M
