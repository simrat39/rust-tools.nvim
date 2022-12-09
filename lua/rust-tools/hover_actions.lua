local rt = require("rust-tools")
local util = vim.lsp.util

local M = {}

local function get_params()
  return util.make_position_params(0, nil)
end

M._state = { winnr = nil, commands = nil }

local function close_hover()
  rt.utils.close_win(M._state.winnr)
end

-- run the command under the cursor, if the thing under the cursor is not the
-- command then do nothing
local function run_command(ctx)
  local winnr = vim.api.nvim_get_current_win()
  local line = vim.api.nvim_win_get_cursor(winnr)[1]

  if line > #M._state.commands then
    return
  end

  local action = M._state.commands[line]

  close_hover()
  M.execute_rust_analyzer_command(action, ctx)
end

function M.execute_rust_analyzer_command(action, ctx)
  local fn = vim.lsp.commands[action.command]
  if fn then
    fn(action, ctx)
  end
end

function M._close_hover() end

local function parse_commands()
  local prompt = {}

  for i, value in ipairs(M._state.commands) do
    if value.command == "rust-analyzer.gotoLocation" then
      table.insert(
        prompt,
        string.format("%d. Go to %s (%s)", i, value.title, value.tooltip)
      )
    elseif value.command == "rust-analyzer.showReferences" then
      table.insert(prompt, string.format("%d. %s", i, "Go to " .. value.title))
    else
      table.insert(prompt, string.format("%d. %s", i, value.title))
    end
  end

  return prompt
end

function M.handler(_, result, ctx)
  if not (result and result.contents) then
    -- return { 'No information available' }
    return
  end

  local markdown_lines =
    util.convert_input_to_markdown_lines(result.contents, {})
  if result.actions then
    M._state.commands = result.actions[1].commands
    local prompt = parse_commands()
    local l = {}

    for _, value in ipairs(prompt) do
      table.insert(l, value)
    end

    markdown_lines = vim.list_extend(l, markdown_lines)
  end

  markdown_lines = util.trim_empty_lines(markdown_lines)

  if vim.tbl_isempty(markdown_lines) then
    -- return { 'No information available' }
    return
  end

  local bufnr, winnr = util.open_floating_preview(
    markdown_lines,
    "markdown",
    vim.tbl_extend("keep", rt.config.options.tools.hover_actions, {
      focusable = true,
      focus_id = "rust-tools-hover-actions",
      close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
    })
  )

  if rt.config.options.tools.hover_actions.auto_focus then
    vim.api.nvim_set_current_win(winnr)
  end

  if M._state.winnr ~= nil then
    return
  end

  -- update the window number here so that we can map escape to close even
  -- when there are no actions, update the rest of the state later
  M._state.winnr = winnr
  vim.keymap.set(
    "n",
    "<Esc>",
    close_hover,
    { buffer = bufnr, noremap = true, silent = true }
  )

  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      M._state.winnr = nil
    end,
  })

  --- stop here if there are no possible actions
  if result.actions == nil then
    return
  end

  -- makes more sense in a dropdown-ish ui
  vim.api.nvim_win_set_option(winnr, "cursorline", true)

  -- run the command under the cursor
  vim.keymap.set("n", "<CR>", function()
    run_command(ctx)
  end, { buffer = bufnr, noremap = true, silent = true })
end

-- Sends the request to rust-analyzer to get hover actions and handle it
function M.hover_actions()
  rt.utils.request(0, "textDocument/hover", get_params(), M.handler)
end

return M
