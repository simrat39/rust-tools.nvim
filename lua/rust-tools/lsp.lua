local rt = require("rust-tools")
local lspconfig = require("lspconfig")
local lspconfig_utils = require("lspconfig.util")
local server_status = require("rust-tools.server_status")

local M = {}

local function setup_commands()
  local lsp_opts = rt.config.options.server

  lsp_opts.commands = vim.tbl_deep_extend("force", lsp_opts.commands or {}, {
    RustSetInlayHints = {
      rt.inlay_hints.enable,
    },
    RustOpenExternalDocs= {
      require("rust-tools.external_docs").open_external_docs,
    },
    RustDisableInlayHints = {
      rt.inlay_hints.disable,
    },
    -- RustToggleInlayHints = {
    --   rt.inlay_hints.toggle_inlay_hints,
    -- },
    RustExpandMacro = { require("rust-tools.expand_macro").expand_macro },
    RustOpenCargo = { require("rust-tools.open_cargo_toml").open_cargo_toml },
    RustParentModule = { require("rust-tools.parent_module").parent_module },
    RustJoinLines = { require("rust-tools.join_lines").join_lines },
    RustRunnables = {
      require("rust-tools.runnables").runnables,
    },
    RustDebuggables = {
      require("rust-tools.debuggables").debuggables,
    },
    RustHoverActions = { require("rust-tools.hover_actions").hover_actions },
    RustHoverRange = { require("rust-tools.hover_range").hover_range },
    RustMoveItemDown = {
      require("rust-tools.move_item").move_item,
    },
    RustMoveItemUp = {
      function()
        require("rust-tools.move_item").move_item(true)
      end,
    },
    RustViewCrateGraph = {
      function(backend, output, pipe)
        require("rust-tools.crate_graph").view_crate_graph(
          backend,
          output,
          pipe
        )
      end,
      "-nargs=* -complete=customlist,v:lua.rust_tools_get_graphviz_backends",
      description = "`:RustViewCrateGraph [<backend> [<output>]]` Show the crate graph",
    },
    RustSSR = {
      function(query)
        require("rust-tools.ssr").ssr(query)
      end,
      "-nargs=?",
      description = "`:RustSSR [query]` Structural Search Replace",
    },
    RustReloadWorkspace = {
      require("rust-tools/workspace_refresh").reload_workspace,
    },
    RustCodeAction = {
      function()
        require("rust-tools/code_action_group").code_action_group()
      end,
    },
  })
end

local function setup_handlers()
  local lsp_opts = rt.config.options.server
  local tool_opts = rt.config.options.tools
  local custom_handlers = {}

  if tool_opts.hover_with_actions then
    custom_handlers["textDocument/hover"] = rt.utils.mk_handler(
      require("rust-tools.hover_actions").handler
    )
  end

  custom_handlers["experimental/serverStatus"] = rt.utils.mk_handler(
    server_status.handler
  )

  lsp_opts.handlers = vim.tbl_deep_extend(
    "force",
    custom_handlers,
    lsp_opts.handlers or {}
  )
end

local function setup_on_init()
  local lsp_opts = rt.config.options.server
  local old_on_init = lsp_opts.on_init

  lsp_opts.on_init = function(...)
    rt.utils.override_apply_text_edits()
    if old_on_init ~= nil then
      old_on_init(...)
    end
  end
end

local function setup_capabilities()
  local lsp_opts = rt.config.options.server
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- snippets
  capabilities.textDocument.completion.completionItem.snippetSupport = true

  -- send actions with hover request
  capabilities.experimental = {
    hoverActions = true,
    hoverRange = true,
    serverStatusNotification = true,
    snippetTextEdit = true,
    codeActionGroup = true,
    ssr = true,
  }

  -- enable auto-import
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
  }

  -- rust analyzer goodies
  capabilities.experimental.commands = {
    commands = {
      "rust-analyzer.runSingle",
      "rust-analyzer.debugSingle",
      "rust-analyzer.showReferences",
      "rust-analyzer.gotoLocation",
      "editor.action.triggerParameterHints",
    },
  }

  lsp_opts.capabilities = vim.tbl_deep_extend(
    "force",
    capabilities,
    lsp_opts.capabilities or {}
  )
end

local function setup_lsp()
  lspconfig.rust_analyzer.setup(rt.config.options.server)
end

local function get_root_dir(filename)
  local fname = filename or vim.api.nvim_buf_get_name(0)
  local cargo_crate_dir = lspconfig_utils.root_pattern("Cargo.toml")(fname)
  local cmd = { "cargo", "metadata", "--no-deps", "--format-version", "1" }
  if cargo_crate_dir ~= nil then
    cmd[#cmd + 1] = "--manifest-path"
    cmd[#cmd + 1] = lspconfig_utils.path.join(cargo_crate_dir, "Cargo.toml")
  end
  local cargo_metadata = ""
  local cm = vim.fn.jobstart(cmd, {
    on_stdout = function(_, d, _)
      cargo_metadata = table.concat(d, "\n")
    end,
    stdout_buffered = true,
  })
  if cm > 0 then
    cm = vim.fn.jobwait({ cm })[1]
  else
    cm = -1
  end
  local cargo_workspace_dir = nil
  if cm == 0 then
    cargo_workspace_dir = vim.fn.json_decode(cargo_metadata)["workspace_root"]
  end
  return cargo_workspace_dir
    or cargo_crate_dir
    or lspconfig_utils.root_pattern("rust-project.json")(fname)
    or lspconfig_utils.find_git_ancestor(fname)
end

local function setup_root_dir()
  local lsp_opts = rt.config.options.server
  if not lsp_opts.root_dir then
    lsp_opts.root_dir = get_root_dir
  end
end

function M.start_standalone_if_required()
  local lsp_opts = rt.config.options.server
  local current_buf = vim.api.nvim_get_current_buf()

  if
    lsp_opts.standalone
    and rt.utils.is_bufnr_rust(current_buf)
    and (get_root_dir() == nil)
  then
    require("rust-tools.standalone").start_standalone_client()
  end
end

function M.setup()
  setup_capabilities()
  -- setup on_init
  setup_on_init()
  -- setup root_dir
  setup_root_dir()
  -- setup handlers
  setup_handlers()
  -- setup user commands
  setup_commands()
  -- setup rust analyzer
  setup_lsp()
end

return M
