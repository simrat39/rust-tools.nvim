local M = {}

function M.fly_check()
  local params = vim.lsp.util.make_text_document_params()
  vim.lsp.buf_notify(0, "rust-analyzer/runFlycheck", params)
end

return M
