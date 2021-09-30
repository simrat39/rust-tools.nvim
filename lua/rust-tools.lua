local nvim_lsp = require 'lspconfig'
local config = require 'rust-tools.config'
local utils = require('rust-tools.utils.utils')
local lspconfig_utils = require('lspconfig.util')
local rt_dap = require('rust-tools.dap')
local server_status = require('rust-tools.server_status')

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
        RustDebuggables = {
            function()
                require('rust-tools.debuggables').debuggables()
            end
        },
        RustHoverActions = {require('rust-tools.hover_actions').hover_actions},
        RustHoverRange = {require('rust-tools.hover_range').hover_range},
        RustMoveItemDown = {
            function() require('rust-tools.move_item').move_item() end
        },
        RustMoveItemUp = {
            function()
                require('rust-tools.move_item').move_item(true)
            end
        },
        RustViewCrateGraph = {
            function(backend, output)
                require('rust-tools.crate_graph').view_crate_graph(backend,
                                                                   output)
            end,
            "-nargs=* -complete=customlist,v:lua.rust_tools_get_graphviz_backends",
            description = '`:RustViewCrateGraph [<backend> [<output>]]` Show the crate graph'
        }
    })
end

local function setup_handlers()
    local lsp_opts = config.options.server
    local tool_opts = config.options.tools
    local custom_handlers = {}

    if tool_opts.hover_with_actions then
        custom_handlers["textDocument/hover"] =
            utils.mk_handler(require('rust-tools.hover_actions').handler)
    end

    -- custom_handlers['textDocument/codeLens'] = utils.mk_handler(vim.lsp.codelens.on_codelens)

    custom_handlers['experimental/serverStatus'] = utils.mk_handler(server_status.handler)

    lsp_opts.handlers = vim.tbl_deep_extend("force", custom_handlers,
                                            lsp_opts.handlers or {})
end

local function setup_on_init()
    local lsp_opts = config.options.server
    local old_on_init = lsp_opts.on_init

    lsp_opts.on_init = function (...)
        utils.override_apply_text_edits()
        vim.lsp.codelens = require('rust-tools.codelens')
        if old_on_init ~= nil then
           old_on_init(...)
        end
    end
end

local function setup_capabilities()
    local lsp_opts = config.options.server
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- snippets
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    -- send actions with hover request
    capabilities.experimental = {
        hoverActions = true,
        hoverRange = true,
        serverStatusNotification = true,
        snippetTextEdit = true
    }

    -- enable auto-import
    capabilities.textDocument.completion.completionItem.resolveSupport =
        {properties = {'documentation', 'detail', 'additionalTextEdits'}}

    -- rust analyzer goodies
    capabilities.experimental.commands =
        {
            commands = {
                "rust-analyzer.runSingle", "rust-analyzer.debugSingle",
                "rust-analyzer.showReferences", "rust-analyzer.gotoLocation",
                "editor.action.triggerParameterHints"
            }
        }

    lsp_opts.capabilities = vim.tbl_deep_extend("force", capabilities,
                                                lsp_opts.capabilities or {})
end

local function setup_lsp() nvim_lsp.rust_analyzer.setup(config.options.server) end

local function get_root_dir()
    local fname = vim.api.nvim_buf_get_name(0)
    local cargo_crate_dir = lspconfig_utils.root_pattern 'Cargo.toml'(fname)
    local cmd = 'cargo metadata --no-deps --format-version 1'
    if cargo_crate_dir ~= nil then
        cmd = cmd .. ' --manifest-path ' ..
                  lspconfig_utils.path.join(cargo_crate_dir, 'Cargo.toml')
    end
    local cargo_metadata = vim.fn.system(cmd)
    local cargo_workspace_dir = nil
    if vim.v.shell_error == 0 then
        cargo_workspace_dir =
            vim.fn.json_decode(cargo_metadata)['workspace_root']
    end
    return cargo_workspace_dir or cargo_crate_dir or
               lspconfig_utils.root_pattern 'rust-project.json'(fname) or
               lspconfig_utils.find_git_ancestor(fname)
end

function M.setup(opts)
    config.setup(opts)

    setup_capabilities()
    -- setup on_init
    setup_on_init()
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

    if utils.is_bufnr_rust(0) and (get_root_dir() == nil) then
        require('rust-tools.standalone').start_standalone_client()
    end

    if pcall(require, 'dap') then rt_dap.setup_adapter() end
end

return M
