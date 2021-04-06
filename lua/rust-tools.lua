local vim = vim

local M = {}

local function setupCommands()
    vim.cmd("command! " .. "RustSetInlayHints " .. ":lua require'rust-tools.inlay_hints'.set_inlay_hints()")
    vim.cmd("command! " .. "RustExpandMacro " .. ":lua require'rust-tools.expand_macro'.expand_macro()")
    vim.cmd("command! " .. "RustOpenCargo " .. ":lua require'rust-tools.open_cargo_toml'.open_cargo_toml()")
    vim.cmd("command! " .. "RustParentModule " .. ":lua require'rust-tools.parent_module'.parent_module()")
    vim.cmd("command! " .. "RustJoinLines " .. "parentmodu:lua require'rust-tools.join_lines'.join_lines()")

    vim.cmd("command! " .. "RustRunnables " .. ":lua require'rust-tools.runnables'.runnables()")
    -- Setup the dropdown theme if telescope is installed
    if pcall(require, 'telescope') then
        vim.cmd("command! " .. "RustRunnables " .. ":lua require'rust-tools.runnables'.runnables(require('telescope.themes').get_dropdown({}))")
    end

    vim.cmd("command! " .. "RustRunnablesTelescope " .. ":lua require('rust-tools.runnables').runnables_telescope(require('telescope.themes').get_dropdown({}))")
    vim.cmd("command! " .. "RustHoverActions " .. ":lua require'rust-tools.hover_actions'.hover_actions()")
    vim.cmd("command! " .. "RustMoveItemDown " .. ":lua require'rust-tools.move_item'.move_item()")
    vim.cmd("command! " .. "RustMoveItemUp " .. ":lua require'rust-tools.move_item'.move_item(true)")
end

function M.setup(opts)
    opts = opts or {}
    if opts.autoSetHints == nil then opts.autoSetHints = true end

    if opts.autoSetHints then
        require'rust-tools.inlay_hints'.setup_autocmd()
    end

    setupCommands()
end

return M
