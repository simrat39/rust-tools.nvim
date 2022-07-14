local rt = require("rust-tools")

local M = {}

function M.open_external_docs()
  rt.utils.request(
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
