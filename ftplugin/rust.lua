local rt = require("rust-tools")

if not vim.g.ferris_has_setup then
  rt.setup()
  vim.g.ferris_has_setup = true
end

rt.lsp.start_or_attach()
