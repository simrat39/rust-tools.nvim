local M = {
  config = nil,
  lsp = nil,
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

  local utils = require("rust-tools.utils.utils")
  M.utils = utils

  config.setup(opts)
  commands.setup_lsp_commands()
end

return M
