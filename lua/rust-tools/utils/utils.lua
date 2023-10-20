local M = {}

function M.is_windows()
  local sysname = vim.loop.os_uname().sysname
  return sysname == "Windows" or sysname == "Windows_NT"
end

function M.is_nushell()
  local shell = vim.loop.os_getenv("SHELL")
  local nu = "nu"
  -- Check if $SHELL ends in "nu"
  return shell:sub(-string.len(nu)) == nu
end

---comment
---@param command string
---@param args table
function M.make_command_from_args(command, args)
  local ret = command .. " "

  for _, value in ipairs(args) do
    ret = ret .. value .. " "
  end

  return ret
end

---Get a new command which is a chain of all the old commands
---Note that a space is not added at the end of the returned command string
---@param commands table
function M.chain_commands(commands)
  local separator = M.is_windows() and " | " or M.is_nushell() and ";" or " && "
  local ret = ""

  for i, value in ipairs(commands) do
    local is_last = i == #commands
    ret = ret .. value

    if not is_last then
      ret = ret .. separator
    end
  end

  return ret
end

function M.delete_buf(bufnr)
  if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

function M.close_win(winnr)
  if winnr ~= nil and vim.api.nvim_win_is_valid(winnr) then
    vim.api.nvim_win_close(winnr, true)
  end
end

function M.split(vertical, bufnr)
  local cmd = vertical and "vsplit" or "split"

  vim.cmd(cmd)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
end

function M.resize(vertical, amount)
  local cmd = vertical and "vertical resize " or "resize"
  cmd = cmd .. amount

  vim.cmd(cmd)
end

function M.snippet_text_edits_to_text_edits(spe)
  for _, value in ipairs(spe) do
    if value.newText and value.insertTextFormat then
      -- $0 -> Nothing
      value.newText = string.gsub(value.newText, "%$%d", "")
      -- ${0:_} -> _
      value.newText = string.gsub(value.newText, "%${%d:(.-)}", "%1")
    end
  end
end

function M.is_bufnr_rust(bufnr)
  return vim.bo[bufnr].ft == "rust"
end

function M.contains(list, item)
  for _, val in ipairs(list) do
    if item == val then
      return true
    end
  end
  return false
end

-- from mfussenegger/nvim-lsp-compl@29a81f3
function M.request(bufnr, method, params, handler)
  return vim.lsp.buf_request(bufnr, method, params, M.mk_handler(handler))
end

-- sanitize_command_for_debugging substitutes the command arguments so it can be used to run a
-- debugger.
--
-- @param command should be a table like: { "run", "--package", "<program>", "--bin", "<program>" }
-- For some reason the endpoint textDocument/hover from rust-analyzer returns
-- cargoArgs = { "run", "--package", "<program>", "--bin", "<program>" } for Debug entry.
-- It doesn't make any sense to run a program before debugging.  Even more the debuggin won't run if
-- the program waits some input.  Take a look at rust-analyzer/editors/code/src/toolchain.ts.
function M.sanitize_command_for_debugging(command)
  if command[1] == "run" then
    command[1] = "build"
  elseif command[1] == "test" then
    table.insert(command, 2, "--no-run")
  end
end

return M
