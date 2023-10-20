local server_status = require("rust-tools.server_status")

local M = {}

local function override_apply_text_edits()
  local utils = require("rust-tools").utils
  local old_func = vim.lsp.util.apply_text_edits
  vim.lsp.util.apply_text_edits = function(edits, bufnr, offset_encoding)
    utils.snippet_text_edits_to_text_edits(edits)
    old_func(edits, bufnr, offset_encoding)
  end
end

local function is_library(fname)
  local cargo_home = os.getenv("CARGO_HOME")
    or vim.fs.joinpath(vim.env.HOME, ".cargo")
  local registry = vim.fs.joinpath(cargo_home, "registry", "src")

  local rustup_home = os.getenv("RUSTUP_HOME")
    or vim.fs.joinpath(vim.env.HOME, ".rustup")
  local toolchains = vim.fs.joinpath(rustup_home, "toolchains")

  for _, item in ipairs({ toolchains, registry }) do
    if fname:sub(1, #item) == item then
      local clients = vim.lsp.get_clients({ name = "rust-analyzer" })
      return clients[#clients].config.root_dir
    end
  end
end

local function get_root_dir(fname)
  local reuse_active = is_library(fname)
  if reuse_active then
    return reuse_active
  end
  local cargo_crate_dir = vim.fs.dirname(vim.fs.find({ "Cargo.toml" }, {
    upward = true,
    path = vim.fs.dirname(fname),
  })[1])
  local cmd = { "cargo", "metadata", "--no-deps", "--format-version", "1" }
  if cargo_crate_dir ~= nil then
    cmd[#cmd + 1] = "--manifest-path"
    cmd[#cmd + 1] = vim.fs.joinpath(cargo_crate_dir, "Cargo.toml")
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
    or vim.fs.dirname(vim.fs.find({ "rust-project.json", ".git" }, {
      upward = true,
      path = vim.fs.dirname(fname),
    })[1])
end

-- start or attach the LSP client
M.start_or_attach = function()
  local rt = require("rust-tools")
  local lsp_opts = rt.config.options.server
  lsp_opts.name = "rust-analyzer"
  lsp_opts.filetypes = { "rust" }
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

  lsp_opts.capabilities =
    vim.tbl_deep_extend("force", capabilities, lsp_opts.capabilities or {})

  lsp_opts.root_dir = get_root_dir(vim.api.nvim_buf_get_name(0))

  local custom_handlers = {}
  custom_handlers["experimental/serverStatus"] = server_status.handler
  if rt.config.options.tools.hover_actions.replace_builtin_hover then
    custom_handlers["textDocument/hover"] =
      require("rust-tools.hover_actions").handler
  end

  lsp_opts.handlers =
    vim.tbl_deep_extend("force", custom_handlers, lsp_opts.handlers or {})

  local lsp_commands = {
    RustCodeAction = {
      require("rust-tools.code_action_group"),

      {},
    },
    RustViewCrateGraph = {
      require("rust-tools.crate_graph"),
      {
        nargs = "*",
        complete = "customlist,v:lua.rust_tools_get_graphviz_backends",
      },
    },
    RustDebuggables = {
      require("rust-tools.debuggables"),
      {},
    },
    RustExpandMacro = {
      require("rust-tools.expand_macro"),
      {},
    },
    RustOpenExternalDocs = {
      require("rust-tools.external_docs"),
      {},
    },
    RustHoverActions = {
      require("rust-tools.hover_actions").hover_actions,
      {},
    },
    RustHoverRange = {
      rt.hover_range.hover_range,
      {},
    },
    RustLastDebug = {
      rt.cached_commands.execute_last_debuggable,
      {},
    },
    RustLastRun = {
      rt.cached_commands.execute_last_runnable,
      {},
    },
    RustJoinLines = {
      rt.join_lines.join_lines,
      {},
    },
    RustMoveItemDown = {
      rt.move_item.move_item,
      {},
    },
    RustMoveItemUp = {
      function()
        require("rust-tools.move_item").move_item(true)
      end,
      {},
    },
    RustOpenCargo = {
      rt.open_cargo_toml.open_cargo_toml,
      {},
    },
    RustParentModule = {
      rt.parent_module.parent_module,
      {},
    },
    RustRunnables = {
      rt.runnables.runnables,
      {},
    },
    RustSSR = {
      function(query)
        require("rust-tools.ssr").ssr(query)
      end,
      {
        nargs = "?",
      },
    },
    RustReloadWorkspace = {
      rt.workspace_refresh.reload_workspace,
      {},
    },
  }

  local old_on_init = lsp_opts.on_init
  lsp_opts.on_init = function(...)
    override_apply_text_edits()
    for name, command in pairs(lsp_commands) do
      vim.api.nvim_create_user_command(name, unpack(command))
    end
    if type(old_on_init) == "function" then
      old_on_init(...)
    end
  end

  local old_on_exit = lsp_opts.on_exit
  lsp_opts.on_exit = function(...)
    override_apply_text_edits()
    for name, _ in pairs(lsp_commands) do
      if vim.cmd[name] then
        vim.api.nvim_del_user_command(name)
      end
    end
    if type(old_on_exit) == "function" then
      old_on_exit(...)
    end
  end

  vim.lsp.start(lsp_opts)
end

return M
