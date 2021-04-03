local M = {}

local function setupCommands()
   vim.cmd("command! " .. "RustSetInlayHints " .. ":lua require'rust-tools.inlay_hints'.set_inlay_hints()")
   vim.cmd("command! " .. "RustExpandMacro " .. ":lua require'rust-tools.expand_macro'.expand_macro()")
   vim.cmd("command! " .. "RustOpenCargo " .. ":lua require'rust-tools.open_cargo_toml'.open_cargo_toml()")
   vim.cmd("command! " .. "RustParentModule " .. ":lua require'rust-tools.parent_module'.parent_module()")
   vim.cmd("command! " .. "RustJoinLines " .. ":lua require'rust-tools.join_lines'.join_lines()")
   vim.cmd("command! " .. "RustRunnables " .. ":lua require'rust-tools.runnables'.runnables()")
   vim.cmd("command! " .. "RustHoverActions " .. ":lua require'rust-tools.hover_actions'.hover_actions()")
end

function M.setup()
   require'rust-tools.inlay_hints'.setup()
   setupCommands()
end

return M
