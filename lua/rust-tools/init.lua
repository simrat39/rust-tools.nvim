local M = {
  code_action_group = nil,
  config = nil,
  crate_graph = nil,
  dap = nil,
  debuggables = nil,
  expand_macro = nil,
  external_docs = nil,
  hover_actions = nil,
  hover_range = nil,
  inlay_hints = {
    enable = nil,
    disable = nil,
    set = nil,
    unset = nil,
    cache = nil,
  },
  join_lines = nil,
  lsp = nil,
  move_item = nil,
  open_cargo_toml = nil,
  parent_module = nil,
  runnables = nil,
  server_status = nil,
  ssr = nil,
  standalone = nil,
  workspace_refresh = nil,
  utils = nil,
}

function M.setup(opts)
  local code_action_group = require("rust-tools.code_action_group")
  M.code_action_group = code_action_group

  local commands = require("rust-tools.commands")

  local config = require("rust-tools.config")
  M.config = config

  local crate_graph = require("rust-tools.crate_graph")
  M.crate_graph = crate_graph

  local rt_dap = require("rust-tools.dap")
  M.dap = rt_dap

  local debuggables = require("rust-tools.debuggables")
  M.debuggables = debuggables

  local expand_macro = require("rust-tools.expand_macro")
  M.expand_macro = expand_macro

  local external_docs = require("rust-tools.external_docs")
  M.external_docs = external_docs

  local hover_actions = require("rust-tools.hover_actions")
  M.hover_actions = hover_actions

  local hover_range = require("rust-tools.hover_range")
  M.hover_range = hover_range

  local inlay = require("rust-tools.inlay_hints")
  local hints = inlay.new()
  M.inlay_hints = {
    enable = function()
      inlay.enable(hints)
    end,
    disable = function()
      inlay.disable(hints)
    end,
    set = function()
      inlay.set(hints)
    end,
    unset = function()
      inlay.unset()
    end,
    cache = function()
      inlay.cache_render(hints)
    end,
    render = function()
      inlay.render(hints)
    end,
  }

  local join_lines = require("rust-tools.join_lines")
  M.join_lines = join_lines

  local lsp = require("rust-tools.lsp")
  M.lsp = lsp

  local move_item = require("rust-tools.move_item")
  M.move_item = move_item

  local open_cargo_toml = require("rust-tools.open_cargo_toml")
  M.open_cargo_toml = open_cargo_toml

  local parent_module = require("rust-tools.parent_module")
  M.parent_module = parent_module

  local runnables = require("rust-tools.runnables")
  M.runnables = runnables

  local server_status = require("rust-tools.server_status")
  M.server_status = server_status

  local ssr = require("rust-tools.ssr")
  M.ssr = ssr

  local standalone = require("rust-tools.standalone")
  M.standalone = standalone

  local workspace_refresh = require("rust-tools.workspace_refresh")
  M.workspace_refresh = workspace_refresh

  local utils = require("rust-tools.utils.utils")
  M.utils = utils

  config.setup(opts)
  lsp.setup()
  commands.setup_lsp_commands()

  if pcall(require, "dap") then
    rt_dap.setup_adapter()
  end
end

return M
