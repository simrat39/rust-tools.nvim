local rt = require("rust-tools")

local M = {}

function M.setup_lsp_commands()
  if not vim.lsp.commands then
    vim.lsp.commands = {}
  end

  vim.lsp.commands["rust-analyzer.runSingle"] = function(command)
    rt.runnables.run_command(1, command.arguments)
  end

  vim.lsp.commands["rust-analyzer.gotoLocation"] = function(command)
    vim.lsp.util.jump_to_location(command.arguments[1])
  end

  vim.lsp.commands["rust-analyzer.showReferences"] = function(_)
    vim.lsp.buf.implementation()
  end

  vim.lsp.commands["rust-analyzer.debugSingle"] = function(command)
    rt.dap.start(command.arguments[1].args)
  end
end

return M
