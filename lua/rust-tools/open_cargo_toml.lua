local rt = require("rust-tools")

local M = {}

local function get_params()
  return {
    textDocument = vim.lsp.util.make_text_document_params(),
  }
end

local function handler(_, result)
  if result == nil then
    return
  end
  vim.lsp.util.jump_to_location(result)
end

-- Sends the request to rust-analyzer to get cargo.tomls location and open it
function M.open_cargo_toml()
  rt.utils.request(0, "experimental/openCargoToml", get_params(), handler)
end

return M
