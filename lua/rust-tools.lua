local vim = vim
local nvim_lsp = require 'lspconfig'
local config = require 'rust-tools.config'

local M = {}

local function setupCommands()
    local lsp_opts = config.options.server

    lsp_opts.commands = vim.tbl_deep_extend("force", lsp_opts.commands or {}, {
        RustSetInlayHints = {
            function()
                require('rust-tools.inlay_hints').set_inlay_hints()
            end
        },
        RustDisableInlayHints = {
            require('rust-tools.inlay_hints').disable_inlay_hints
        },
        RustToggleInlayHints = {
            function()
                require('rust-tools.inlay_hints').toggle_inlay_hints()
            end
        },
        RustExpandMacro = {require('rust-tools.expand_macro').expand_macro},
        RustOpenCargo = {require('rust-tools.open_cargo_toml').open_cargo_toml},
        RustParentModule = {require('rust-tools.parent_module').parent_module},
        RustJoinLines = {require('rust-tools.join_lines').join_lines},
        RustRunnables = {
            function() require('rust-tools.runnables').runnables() end
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

local function setup_handlers()
    local lsp_opts = config.options.server
    local tool_opts = config.options.tools
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

local function setup_capabilities()
    local lsp_opts = config.options.server
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

local function setup_lsp() nvim_lsp.rust_analyzer.setup(config.options.server) end

function M.setup(opts)
    config.setup(opts)

    setup_capabilities()
    -- setup handlers
    setup_handlers()
    -- setup user commands
    setupCommands()
    -- setup rust analyzer
    setup_lsp()

    -- enable automatic inlay hints
    if config.options.tools.autoSetHints then
        require'rust-tools.inlay_hints'.setup_autocmd()
    end
end

return M
