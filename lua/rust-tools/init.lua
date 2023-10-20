local M = {
  config = nil,
  lsp = nil,
  runnables = nil,
  server_status = nil,
  ssr = nil,
  workspace_refresh = nil,
  utils = nil,
}

function M.setup(opts)
  local cached_commands = require("rust-tools.cached_commands")
  M.cached_commands = cached_commands

  local commands = require("rust-tools.commands")

  local config = require("rust-tools.config")
  M.config = config

  local lsp = require("rust-tools.lsp")
  M.lsp = lsp

  local runnables = require("rust-tools.runnables")
  M.runnables = runnables

  local server_status = require("rust-tools.server_status")
  M.server_status = server_status

  local ssr = require("rust-tools.ssr")
  M.ssr = ssr

  local workspace_refresh = require("rust-tools.workspace_refresh")
  M.workspace_refresh = workspace_refresh

  local utils = require("rust-tools.utils.utils")
  M.utils = utils

  config.setup(opts)
  commands.setup_lsp_commands()
end

return M
