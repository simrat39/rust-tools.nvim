local utils = require("rust-tools.utils.utils")

local M = {}

local latest_buf_id = nil

function M.execute_command(command, args, cwd)
  local full_command = utils.chain_commands({
    utils.make_command_from_args("cd", { cwd }),
    utils.make_command_from_args(command, args),
  })

  -- check if a buffer with the latest id is already open, if it is then
  -- delete it and continue
  utils.delete_buf(latest_buf_id)

  -- create the new buffer
  latest_buf_id = vim.api.nvim_create_buf(false, true)

  -- split the window to create a new buffer and set it to our window
  utils.split(false, latest_buf_id)

  -- make the new buffer smaller
  utils.resize(false, "-5")

  -- close the buffer when escape is pressed :)
  vim.api.nvim_buf_set_keymap(
    latest_buf_id,
    "n",
    "<Esc>",
    ":q<CR>",
    { noremap = true }
  )

  -- run the command
  vim.fn.termopen(full_command)

  -- when the buffer is closed, set the latest buf id to nil else there are
  -- some edge cases with the id being sit but a buffer not being open
  local function onDetach(_, _)
    latest_buf_id = nil
  end
  vim.api.nvim_buf_attach(latest_buf_id, false, { on_detach = onDetach })
end

return M
