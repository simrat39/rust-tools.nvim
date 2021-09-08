local config = require('rust-tools.config')
local inlay = require('rust-tools.inlay_hints')

local M = {}

function M.handler(...)
    local _args = { ... }
    local result
    if vim.fn.has 'nvim-0.5.1' == 1 then
        result = _args[2]
    else
        result = _args[3]
    end
    if result.quiescent and config.options.tools.autoSetHints then
       inlay.set_inlay_hints();
    end
end

return M
