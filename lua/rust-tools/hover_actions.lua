local utils = require("rust-tools.utils.utils")
local util = vim.lsp.util
local config = require("rust-tools.config")

local M = {}

local function get_params()
  return vim.lsp.util.make_position_params()
end

M._state = { winnr = nil, parent_bufnr = nil, commands = nil }
local set_keymap_opt = { noremap = true, silent = true }

-- run the command under the cursor, if the thing under the cursor is not the
-- command then do nothing
function M._run_command()
  local line = vim.api.nvim_win_get_cursor(M._state.winnr)[1]

  if line > #M._state.commands then
    return
  end

  local action = M._state.commands[line]

  M._close_hover()
  M.execute_rust_analyzer_command(action)
end

function M.execute_rust_analyzer_command(action)
  local fn = vim.lsp.commands[action.command]
  if fn then
    fn(action)
  end
end

function M._close_hover()
  if M._state.winnr ~= nil then
    vim.api.nvim_win_close(M._state.winnr, true)
  end
end

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

function M.handler(_, result)
  if not (result and result.contents) then
    -- return { 'No information available' }
    return
  end

  local markdown_lines = util.convert_input_to_markdown_lines(result.contents)
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

  -- update parent_bufnr before focus on hover buf
  local parent_bufnr = vim.api.nvim_get_current_buf()
  M._state.parent_bufnr = parent_bufnr

  local bufnr, winnr = util.open_floating_preview(
    markdown_lines,
    "markdown",
    vim.tbl_extend("keep", config.options.tools.hover_actions, {
      focusable = true,
      focus_id = "rust-tools-hover-actions",
      close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
    })
  )

  if config.options.tools.hover_actions.auto_focus then
    vim.api.nvim_set_current_win(winnr)
  end

  if M._state.winnr ~= nil then
    return
  end

  -- update the window number here so that we can map escape to close even
  -- when there are no actions, update the rest of the state later
  M._state.winnr = winnr
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "<Esc>",
    ":lua require'rust-tools.hover_actions'._close_hover()<CR>",
    set_keymap_opt
  )

  -- set keymaps for scrolling the popup
  local keymaps = config.options.tools.hover_actions.keymaps
  if keymaps.enable then
    vim.api.nvim_buf_set_keymap(
      M._state.parent_bufnr, -- set for parent buf, not the hover window buf
      "n",
      keymaps.scroll_up,
      ":lua require'rust-tools.hover_actions'.scroll_hover(1)<CR>",
      { silent = true }
    )

    vim.api.nvim_buf_set_keymap(
      M._state.parent_bufnr, -- set for parent buf, not the hover window buf
      "n",
      keymaps.scroll_down,
      ":lua require'rust-tools.hover_actions'.scroll_hover(-1)<CR>",
      { silent = true }
    )
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      M._state.winnr = nil
      if keymaps.enable then
        vim.api.nvim_buf_del_keymap(M._state.parent_bufnr, "n", keymaps.scroll_up)
        vim.api.nvim_buf_del_keymap(M._state.parent_bufnr, "n", keymaps.scroll_down)
      end
    end,
  })

  --- stop here if there are no possible actions
  if result.actions == nil then
    return
  end

  -- makes more sense in a dropdown-ish ui
  vim.api.nvim_win_set_option(winnr, "cursorline", true)

  -- run the command under the cursor
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "<CR>",
    ":lua require'rust-tools.hover_actions'._run_command()<CR>",
    set_keymap_opt
  )
  -- close on escape
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "<Esc>",
    ":lua require'rust-tools.hover_actions'._close_hover()<CR>",
    set_keymap_opt
  )
end

---Scroll the hover window
---@param offset number, scroll up if offset > 0 else scroll down
function M.scroll_hover(offset)
  if M._state.winnr ~= nil then
    local cmd = [[exec "norm! \<c-d>"]]
    if offset < 0 then
      cmd = [[exec "norm! \<c-u>"]]
    end
    vim.api.nvim_win_call(
      M._state.winnr,
      function() vim.cmd(cmd) end
    )
  end
end

-- Sends the request to rust-analyzer to get hover actions and handle it
function M.hover_actions()
  utils.request(0, "textDocument/hover", get_params(), M.handler)
end

return M
