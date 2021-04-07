local M = {}

local function setup_commands(server_opts, tools_opts)
   server_opts.commands = vim.tbl_extend('force', server_opts.commands or {}, {
      RustSetInlayHints = {
         function()
            require('rust-tools.inlay_hints').set_inlay_hints(tools_opts.inlay_hints or {})
         end,
         -- TODO: Add description.
      },
      RustExpandMacro = {
         require('rust-tools.expand_macro').expand_macro,
         -- TODO: Add description.
      },
      RustOpenCargo = {
         require('rust-tools.open_cargo_toml').open_cargo_toml,
         -- TODO: Add description.
      },
      RustParentModule = {
         require('rust-tools.parent_module').parent_module,
         -- TODO: Add description.
      },
      RustJoinLines = {
         require('rust-tools.join_lines').join_lines,
         -- TODO: Add description.
      },
      RustRunnables = {
         function()
            require('rust-tools.runnables').runnables(tools_opts.runnables or {})
         end,
         -- TODO: Add description.
      },
      RustHoverActions = {
         require('rust-tools.hover_actions').hover_actions
         -- TODO: Add description.
      },
      RustMoveItemDown = {
         require('rust-tools.move_item').move_item
         -- TODO: Add description.
      },
      RustMoveItemUp = {
         function()
            require('rust-tools.move_item').move_item(true)
         end,
         -- TODO: Add description.
      }
   })
end

   function M.setup(opts)
      opts = opts or {}
      local server_opts = opts.server or {}
      local tools_opts = opts.tools or {}

      setup_commands(server_opts, tools_opts)

      require('lspconfig').rust_analyzer.setup(server_opts)
   end

return M
