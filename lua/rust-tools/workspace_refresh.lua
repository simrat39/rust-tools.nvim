local util = require("rust-tools.utils.utils")
local M = {}

local function handler(err)
  if err then
    error(tostring(err))
  end
  util.create_notify_floating_window(
    { "Cargo Workspace reloaded" },
    { width = 30 }
  )
end

function M._reload_workspace_from_cargo_toml()
  local clients = vim.lsp.get_active_clients()

  for _, client in ipairs(clients) do
    if client.name == "rust_analyzer" then
      util.create_notify_floating_window(
        { "Reloading Cargo Workspace" },
        { width = 30 }
      )
      client.request("rust-analyzer/reloadWorkspace", nil, handler, 0)
    end
  end
end

function M.reload_workspace()
  util.create_notify_floating_window({
    "Reloading Cargo Workspace",
    { width = 30 },
  })
  vim.lsp.buf_request(0, "rust-analyzer/reloadWorkspace", nil, handler)
end

return M
