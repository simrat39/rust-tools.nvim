local M = {}

local function setupCommands()
   vim.cmd("command! " .. "RustOpenCargo " .. ":lua require'rust-tools.open_cargo_toml'.open_cargo_toml()") 
   vim.cmd("command! " .. "RustExpandMacro " .. ":lua require'rust-tools.expand_macro'.expand_macro()")
end

function M.setup()
   require'rust-tools.inlay_hints'.setup()
   setupCommands()
end

return M
