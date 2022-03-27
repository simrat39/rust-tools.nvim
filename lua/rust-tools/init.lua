local M = {
  config = nil,
  utils = nil,
  inlay_hints = nil,
  lsp = nil,
}

function M.setup(opts)
  local config = require("rust-tools/config")
  local utils = require("rust-tools/utils/utils")
  local lsp = require("rust-tools/lsp")
  local inlay = require("rust-tools/inlay_hints")
  local commands = require("rust-tools/commands")
  local rt_dap = require("rust-tools/dap")

  M.config = config
  M.utils = utils

  M.lsp = lsp

  M.inlay_hints = inlay

  config.setup(opts)
  lsp.setup()
  commands.setup_lsp_commands()

  if pcall(require, "dap") then
    rt_dap.setup_adapter()
  end
end

return M
