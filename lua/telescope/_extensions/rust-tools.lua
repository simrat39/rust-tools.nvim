local telescope = require('telescope')
local get_telescope_handler = require('rust-tools.runnables').get_telescope_handler

return telescope.register_extension({
   setup = function(tools_opts)
      local server_opts = require('lspconfig').rust_analyzer

      server_opts.handlers = vim.tbl_extend('force', server_opts.handlers or {}, {
         ['experimental/runnables'] = get_telescope_handler(tools_opts),
      })

      server_opts.setup(server_opts)
   end,
   extensions = {},
})
