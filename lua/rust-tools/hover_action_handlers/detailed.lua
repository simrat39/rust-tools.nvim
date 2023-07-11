local rt = require("rust-tools")
local util = vim.lsp.util

local _state = { winnr = nil, actions = nil }

local function close_hover()
  rt.utils.close_win(_state.winnr)
end

-- run the command under the cursor, if the thing under the cursor is not the
-- command then do nothing
local function run_command()
  local winnr = vim.api.nvim_get_current_win()
  local line = vim.api.nvim_win_get_cursor(winnr)[1]

  if line > #_state.actions then
    return
  end

  local action = _state.actions[line]

  close_hover()
  action.execute()
end

local function parse_commands()
  local prompt = {}

  for i, value in ipairs(_state.actions) do
    table.insert(prompt, string.format("%d. %s", i, value.title))
  end

  return prompt
end

return function(options)
  local markdown_lines =
    util.convert_input_to_markdown_lines(options.contents, {})

  _state.actions = options.actions
  if options.actions then
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

  if _state.winnr ~= nil then
    return
  end

  -- update the window number here so that we can map escape to close even
  -- when there are no actions, update the rest of the state later
  _state.winnr = winnr
  vim.keymap.set(
    "n",
    "<Esc>",
    close_hover,
    { buffer = bufnr, noremap = true, silent = true }
  )

  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      _state.winnr = nil
    end,
  })

  --- stop here if there are no possible actions
  if options.actions == nil then
    return
  end

  -- makes more sense in a dropdown-ish ui
  vim.api.nvim_win_set_option(winnr, "cursorline", true)

  -- run the command under the cursor
  vim.keymap.set(
    "n",
    "<CR>",
    run_command,
    { buffer = bufnr, noremap = true, silent = true }
  )
end
