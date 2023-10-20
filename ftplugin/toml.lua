if vim.api.nvim_buf_get_name(0) ~= "Cargo.toml" then
  return
end

local group = vim.api.nvim_create_augroup("RustToolsAutocmds", { clear = true })

local rt = require("rust-tools")

if rt.config.options.tools.reload_workspace_from_cargo_toml then
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = vim.fn.bufnr(),
    callback = require("rust-tools.workspace_refresh")._reload_workspace_from_cargo_toml,
    group = group,
  })
end
