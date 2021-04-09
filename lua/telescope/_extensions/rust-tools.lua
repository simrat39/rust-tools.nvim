local telescope = require('telescope')
local get_runnables_telescope_handler = require('rust-tools.runnables').get_telescope_handler

return telescope.register_extension({
   setup = function(tools_opts)
      tools_opts = vim.tbl_deep_extend('keep', tools_opts, {
         hover_actions = {
            telescope = {},
            no_results_message = 'No hover actions found',
         },
         runnables = {
            telescope = {},
            no_results_message = 'No runnables found',
         },
      })
      local server_opts = require('lspconfig').rust_analyzer

      server_opts.handlers = vim.tbl_extend('force', server_opts.handlers or {}, {
         ['experimental/runnables'] = get_runnables_telescope_handler(tools_opts.runnables),
      })

      server_opts.commands = vim.tbl_extend('force', server_opts.commands or {}, {
         RustAnalyzerHoverActions = {
            function()
               local make_handler = require('rust-tools.hover_actions').make_telescope_handler

               require('rust-tools.hover_actions').hover_actions(
                  make_handler(tools_opts.hover_actions)
               )
            end,
         },
      })

      server_opts.setup(server_opts)
   end,
   extensions = {},
})
