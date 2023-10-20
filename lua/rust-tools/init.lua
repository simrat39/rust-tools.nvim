local M = {
  config = nil,
}

function M.setup(opts)
  local cached_commands = require("rust-tools.cached_commands")
  M.cached_commands = cached_commands

  local commands = require("rust-tools.commands")

  local config = require("rust-tools.config")
  M.config = config

  config.setup(opts)
  commands.setup_lsp_commands()
end

return M
