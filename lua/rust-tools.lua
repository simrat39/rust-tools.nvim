local vim = vim
local nvim_lsp = require 'lspconfig'

local M = {}

-- Takes a table and converts it into a long string
local function table_to_long_str(t)
    local ret = "{"
    for key, value in pairs(t) do
        ret = ret .. tostring(key) .. "="
        -- recursively handle nested tables
        if type(value) == 'table' then
            ret = ret .. table_to_long_str(value) .. ","
        else
            -- Add surrounding quotes if we have a string
            if type(value) == 'string' then
                ret = ret .. "\"" .. tostring(value) .. "\"" .. ","
                else
                ret = ret .. tostring(value) .. ","
            end
        end
    end
    ret = ret .. "}"
    print(ret)
    return ret
end

local function setupCommands(lsp_opts, tool_opts)
    local runnables_opts = tool_opts.runnables or {}
    -- Setup the dropdown theme if telescope is installed
    if pcall(require, 'telescope') then
        runnables_opts =
            require('telescope.themes').get_dropdown(runnables_opts)
    end

    lsp_opts.commands = vim.tbl_deep_extend("force", lsp_opts.commands or {}, {
        RustSetInlayHints = {
            function()
                require('rust-tools.inlay_hints').set_inlay_hints(
                    tool_opts.inlay_hints or {})
            end
        },
        RustDisableInlayHints = {
            require('rust-tools.inlay_hints').disable_inlay_hints
        },
        RustToggleInlayHints = {
            function()
                require('rust-tools.inlay_hints').toggle_inlay_hints(
                    tool_opts.inlay_hints or {})
            end
        },
        RustExpandMacro = {require('rust-tools.expand_macro').expand_macro},
        RustOpenCargo = {require('rust-tools.open_cargo_toml').open_cargo_toml},
        RustParentModule = {require('rust-tools.parent_module').parent_module},
        RustJoinLines = {require('rust-tools.join_lines').join_lines},
        RustRunnables = {
            function()
                require('rust-tools.runnables').runnables(runnables_opts)
            end
        },
        RustHoverActions = {require('rust-tools.hover_actions').hover_actions},
        RustMoveItemDown = {
            function() require('rust-tools.move_item').move_item() end
        },
        RustMoveItemUp = {
            function()
                require('rust-tools.move_item').move_item(true)
            end
        }
    })
end

local function setup_handlers(lsp_opts, tool_opts)
    local custom_handlers = {}

    if tool_opts.hover_with_actions == nil then
        tool_opts.hover_with_actions = true
    end
    if tool_opts.hover_with_actions then
        custom_handlers["textDocument/hover"] =
            require('rust-tools.hover_actions').handler
    end

    lsp_opts.handlers = vim.tbl_deep_extend("force", custom_handlers,
                                            lsp_opts.handlers or {})
end

local function setup_capabilities(lsp_opts)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- snippets
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    -- send actions with hover request
    capabilities.experimental = {hoverActions = true}
    -- enable auto-import
    capabilities.textDocument.completion.completionItem.resolveSupport =
        {properties = {'documentation', 'detail', 'additionalTextEdits'}}
    lsp_opts.capabilities = vim.tbl_deep_extend("force", capabilities,
                                                lsp_opts.capabilities or {})
end

local function setup_lsp(lsp_opts) nvim_lsp.rust_analyzer.setup(lsp_opts) end

function M.setup(opts)
    opts = opts or {}
    local tool_opts = opts.tools or {}
    local lsp_opts = opts.server or {}

    setup_capabilities(lsp_opts)
    -- setup handlers
    setup_handlers(lsp_opts, tool_opts)
    -- setup user commands
    setupCommands(lsp_opts, tool_opts)
    -- setup rust analyzer
    setup_lsp(lsp_opts)

    -- enable automatic inlay hints
    if opts.autoSetHints == nil then opts.autoSetHints = true end
    if opts.autoSetHints then
        require'rust-tools.inlay_hints'.setup_autocmd(
            table_to_long_str(tool_opts.inlay_hints or {}))
    end
end

return M
