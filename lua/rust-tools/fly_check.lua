local M = {}

function M.fly_check()
  vim.lsp.buf_notify(0, "rust-analyzer/runFlycheck", {
    textDocument = vim.lsp.util.make_text_document_params()
  })
end

return M
