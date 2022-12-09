local rt = require("rust-tools")
local M = {}

function M.start_standalone_client()
  local config = {
    root_dir = require("lspconfig.util").path.dirname(
      vim.api.nvim_buf_get_name(0)
    ),
    capabilities = rt.config.options.server.capabilities,
    cmd = rt.config.options.server.cmd or { "rust-analyzer" },
    filetypes = { "rust" },
    init_options = { detachedFiles = { vim.api.nvim_buf_get_name(0) } },
    name = "rust_analyzer-standalone",
    on_init = function(client)
      local current_buf = vim.api.nvim_get_current_buf()
      vim.lsp.buf_attach_client(0, client.id)
      local on_attach = rt.config.options.server.on_attach
      if on_attach then
        on_attach(client, current_buf)
      end
      vim.cmd(
        "command! RustSetInlayHints :lua require('rust-tools.inlay_hints').set_inlay_hints()"
      )
      vim.cmd(
        "command! RustDisableInlayHints :lua require('rust-tools.inlay_hints').disable_inlay_hints()"
      )
      vim.cmd(
        "command! RustToggleInlayHints :lua require('rust-tools.inlay_hints').toggle_inlay_hints()"
      )
      vim.cmd(
        "command! RustExpandMacro :lua require('rust-tools.expand_macro').expand_macro()"
      )
      vim.cmd(
        "command! RustJoinLines :lua require('rust-tools.join_lines').join_lines()"
      )
      vim.cmd(
        "command! RustHoverActions :lua require('rust-tools.hover_actions').hover_actions()"
      )
      vim.cmd(
        "command! RustMoveItemDown :lua require('rust-tools.move_item').move_item()"
      )
      vim.cmd(
        "command! RustMoveItemUp :lua require('rust-tools.move_item').move_item(true)"
      )
    end,
    on_exit = function()
      vim.cmd("delcommand RustSetInlayHints")
      vim.cmd("delcommand RustDisableInlayHints")
      vim.cmd("delcommand RustToggleInlayHints")
      vim.cmd("delcommand RustExpandMacro")
      vim.cmd("delcommand RustJoinLines")
      vim.cmd("delcommand RustHoverActions")
      vim.cmd("delcommand RustMoveItemDown")
      vim.cmd("delcommand RustMoveItemUp")
    end,
    handlers = rt.config.options.server.handlers,
  }

  vim.lsp.start_client(config)
end

return M
