local M = {}

local function handler(err)
  if err then
    error(tostring(err))
  end
  vim.notify("Cargo workspace reloaded")
end

function M.reload_workspace()
  local client = vim.lsp.get_active_clients({ name = "rust_analyzer" })
  if #client ~= 0 then
    vim.notify("Reloading Cargo Workspace")
    client[1].request("rust-analyzer/reloadWorkspace", nil, handler, 0)
  end
end

return M
