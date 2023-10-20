local M = {}

function M.open_external_docs()
  vim.lsp.buf_request(
    0,
    "experimental/externalDocs",
    vim.lsp.util.make_position_params(),
    function(_, url)
      if url then
        vim.fn["netrw#BrowseX"](url, 0)
      end
    end
  )
end

return M
