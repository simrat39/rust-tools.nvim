local vim = vim

local D = {}

-- needs plenary
local reload = require('plenary.reload').reload_module

function D.R(name)
   reload(name)
   return require(name)
end

local function setupCommands()
   vim.cmd("command! " .. "DRustSetInlayHints " .. ":lua require'rust-tools-debug'.R('rust-tools.inlay_hints').set_inlay_hints()")
   vim.cmd("command! " .. "DRustHoverActions " .. ":lua require'rust-tools-debug'.R('rust-tools.hover_actions').hover_actions()")
   vim.cmd("command! " .. "DRustMoveItemDown " .. ":lua require'rust-tools-debug'.R('rust-tools.move_item').move_item()")
   vim.cmd("command! " .. "DRustMoveItemUp " .. ":lua require'rust-tools-debug'.R('rust-tools.move_item').move_item(true)")
end

function D.setup()
    setupCommands()
end

return D
