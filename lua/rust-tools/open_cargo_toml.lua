local rt = require("rust-tools")

local M = {}

local function get_params()
  return {
    textDocument = vim.lsp.util.make_text_document_params(0),
  }
end

local function handler(_, result, ctx)
  if result == nil then
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  vim.lsp.util.jump_to_location(result, client.offset_encoding)
end

-- Sends the request to rust-analyzer to get cargo.tomls location and open it
function M.open_cargo_toml()
  rt.utils.request(0, "experimental/openCargoToml", get_params(), handler)
end

return M
