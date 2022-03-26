local M = {}

local function handler(err)
  if err then
    error(tostring(err))
  end
  vim.notify("Cargo workspace reloaded")
end

function M._reload_workspace_from_cargo_toml()
  local clients = vim.lsp.get_active_clients()

  for _, client in ipairs(clients) do
    if client.name == "rust_analyzer" then
      vim.notify("Reloading Cargo Workspace")
      client.request("rust-analyzer/reloadWorkspace", nil, handler, 0)
    end
  end
end

function M.reload_workspace()
  vim.notify("Reloading Cargo Workspace")
  vim.lsp.buf_request(0, "rust-analyzer/reloadWorkspace", nil, handler)
end

return M
