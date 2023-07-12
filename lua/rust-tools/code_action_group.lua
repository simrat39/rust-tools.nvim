local utils = require("rust-tools.utils.utils")
local M = {}

---@private
function M.apply_action(action, client, ctx)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if action.command then
    local command = type(action.command) == "table" and action.command or action
    local fn = vim.lsp.commands[command.command]
    if fn then
      local enriched_ctx = vim.deepcopy(ctx)
      enriched_ctx.client_id = client.id
      fn(command, ctx)
    else
      M.execute_command(command)
    end
  end
end

---@private
function M.on_user_choice(action_tuple, ctx)
  if not action_tuple then
    return
  end
  -- textDocument/codeAction can return either Command[] or CodeAction[]
  --
  -- CodeAction
  --  ...
  --  edit?: WorkspaceEdit    -- <- must be applied before command
  --  command?: Command
  --
  -- Command:
  --  title: string
  --  command: string
  --  arguments?: any[]
  --
  local client = vim.lsp.get_client_by_id(action_tuple[1])
  local action = action_tuple[2]
  local code_action_provider = nil
  if vim.fn.has("nvim-0.8.0") then
    code_action_provider = client.server_capabilities.codeActionProvider
  else
    code_action_provider = client.resolved_capabilities.code_action
  end
  if
    not action.edit
    and client
    and type(code_action_provider) == "table"
    and code_action_provider.resolveProvider
  then
    client.request("codeAction/resolve", action, function(err, resolved_action)
      if err then
        vim.notify(err.code .. ": " .. err.message, vim.log.levels.ERROR)
        return
      end
      M.apply_action(resolved_action, client, ctx)
    end)
  else
    M.apply_action(action, client, ctx)
  end
end

local function compute_width(action_tuples, is_group)
  local width = 0

  for _, value in pairs(action_tuples) do
    local action = value[2]
    local text = action.title

    if is_group and action.group then
      text = action.group .. " ▶"
    end
    local len = string.len(text)
    if len > width then
      width = len
    end
  end

  return { width = width + 5 }
end

local function on_primary_enter_press()
  if M.state.secondary.winnr then
    vim.api.nvim_set_current_win(M.state.secondary.winnr)
    return
  end

  local line = vim.api.nvim_win_get_cursor(M.state.secondary.winnr or 0)[1]

  for _, value in ipairs(M.state.actions.ungrouped) do
    if value[2].idx == line then
      M.on_user_choice(value, M.state.ctx)
    end
  end

  M.cleanup()
end

local function on_primary_quit()
  M.cleanup()
end

local function on_code_action_results(results, ctx)
  M.state.ctx = ctx

  local action_tuples = {}
  for client_id, result in pairs(results) do
    for _, action in pairs(result.result or {}) do
      table.insert(action_tuples, { client_id, action })
    end
  end
  if #action_tuples == 0 then
    vim.notify("No code actions available", vim.log.levels.INFO)
    return
  end

  M.state.primary.geometry = compute_width(action_tuples, true)

  M.state.actions.grouped = {}

  M.state.actions.ungrouped = {}

  for _, value in ipairs(action_tuples) do
    local action = value[2]

    -- Some clippy lints may have newlines in them
    action.title = string.gsub(action.title, "[\n\r]+", " ")

    if action.group then
      if not M.state.actions.grouped[action.group] then
        M.state.actions.grouped[action.group] = { actions = {}, idx = nil }
      end

      table.insert(M.state.actions.grouped[action.group].actions, value)
    else
      table.insert(M.state.actions.ungrouped, value)
    end
  end

  M.state.primary.bufnr = vim.api.nvim_create_buf(false, true)
  M.state.primary.winnr = vim.api.nvim_open_win(M.state.primary.bufnr, true, {
    relative = "cursor",
    width = M.state.primary.geometry.width,
    height = vim.tbl_count(M.state.actions.grouped)
      + vim.tbl_count(M.state.actions.ungrouped),
    focusable = true,
    border = "rounded",
    row = 1,
    col = 0,
  })

  local idx = 1
  for key, value in pairs(M.state.actions.grouped) do
    value.idx = idx
    vim.api.nvim_buf_set_lines(
      M.state.primary.bufnr,
      -1,
      -1,
      false,
      { key .. " ▶" }
    )
    idx = idx + 1
  end

  for _, value in pairs(M.state.actions.ungrouped) do
    local action = value[2]
    value[2].idx = idx
    vim.api.nvim_buf_set_lines(
      M.state.primary.bufnr,
      -1,
      -1,
      false,
      { action.title }
    )
    idx = idx + 1
  end

  vim.api.nvim_buf_set_lines(M.state.primary.bufnr, 0, 1, false, {})

  vim.keymap.set(
    "n",
    "<CR>",
    on_primary_enter_press,
    { buffer = M.state.primary.bufnr }
  )

  vim.keymap.set("n", "q", on_primary_quit, { buffer = M.state.primary.bufnr })

  M.codeactionify_window_buffer(M.state.primary.winnr, M.state.primary.bufnr)

  vim.api.nvim_buf_attach(M.state.primary.bufnr, false, {
    on_detach = function(_, _)
      M.state.primary.clear()
      vim.schedule(M.cleanup)
    end,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = M.state.primary.bufnr,
    callback = M.on_cursor_move,
  })

  vim.cmd("redraw")
end

function M.codeactionify_window_buffer(winnr, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "delete")
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")

  vim.api.nvim_win_set_option(winnr, "nu", true)
  vim.api.nvim_win_set_option(winnr, "rnu", false)
  vim.api.nvim_win_set_option(winnr, "cul", true)
end

local function on_secondary_enter_press()
  local line = vim.api.nvim_win_get_cursor(M.state.secondary.winnr)[1]
  local active_group = nil

  for _, value in pairs(M.state.actions.grouped) do
    if value.idx == M.state.active_group_index then
      active_group = value
      break
    end
  end

  if active_group then
    for _, value in pairs(active_group.actions) do
      if value[2].idx == line then
        M.on_user_choice(value, M.state.ctx)
      end
    end
  end

  M.cleanup()
end

local function on_secondary_quit()
  local winnr = M.state.secondary.winnr
  -- we clear first because if we close the window first, the cursor moved
  -- autocmd of the first buffer gets called which then sees that
  -- M.state.secondary.winnr exists (when it shouldnt because it is closed)
  -- and errors out
  M.state.secondary.clear()

  utils.close_win(winnr)
end

function M.cleanup()
  if M.state.primary.winnr then
    utils.close_win(M.state.primary.winnr)
    M.state.primary.clear()
  end

  if M.state.secondary.winnr then
    utils.close_win(M.state.secondary.winnr)
    M.state.secondary.clear()
  end

  if M.state.ctx.win then
    vim.api.nvim_set_current_win(M.state.ctx.win)
  end

  M.state.actions = {}
  M.state.active_group_index = nil
  M.state.ctx = {}
end

function M.on_cursor_move()
  local line = vim.api.nvim_win_get_cursor(M.state.primary.winnr)[1]

  for _, value in pairs(M.state.actions.grouped) do
    if value.idx == line then
      M.state.active_group_index = line

      if M.state.secondary.winnr then
        utils.close_win(M.state.secondary.winnr)
        M.state.secondary.clear()
      end

      M.state.secondary.geometry = compute_width(value.actions, false)

      M.state.secondary.bufnr = vim.api.nvim_create_buf(false, true)
      M.state.secondary.winnr =
        vim.api.nvim_open_win(M.state.secondary.bufnr, false, {
          relative = "win",
          win = M.state.primary.winnr,
          width = M.state.secondary.geometry.width,
          height = #value.actions,
          focusable = true,
          border = "rounded",
          row = line - 2,
          col = M.state.primary.geometry.width + 1,
        })

      local idx = 1
      for _, inner_value in pairs(value.actions) do
        local action = inner_value[2]
        action.idx = idx
        vim.api.nvim_buf_set_lines(
          M.state.secondary.bufnr,
          -1,
          -1,
          false,
          { action.title }
        )
        idx = idx + 1
      end

      vim.api.nvim_buf_set_lines(M.state.secondary.bufnr, 0, 1, false, {})

      M.codeactionify_window_buffer(
        M.state.secondary.winnr,
        M.state.secondary.bufnr
      )

      vim.keymap.set(
        "n",
        "<CR>",
        on_secondary_enter_press,
        { buffer = M.state.secondary.bufnr }
      )

      vim.keymap.set(
        "n",
        "q",
        on_secondary_quit,
        { buffer = M.state.secondary.bufnr }
      )

      return
    end

    if M.state.secondary.winnr then
      utils.close_win(M.state.secondary.winnr)
      M.state.secondary.clear()
    end
  end
end

M.state = {
  ctx = {},
  actions = {},
  active_group_index = nil,
  primary = {
    bufnr = nil,
    winnr = nil,
    geometry = nil,
    clear = function()
      M.state.primary.geometry = nil
      M.state.primary.bufnr = nil
      M.state.primary.winnr = nil
    end,
  },
  secondary = {
    bufnr = nil,
    winnr = nil,
    geometry = nil,
    clear = function()
      M.state.secondary.geometry = nil
      M.state.secondary.bufnr = nil
      M.state.secondary.winnr = nil
    end,
  },
}

function M.code_action_group()
  local context = {}
  context.diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  local params = vim.lsp.util.make_range_params()
  params.context = context
  local win = vim.api.nvim_get_current_win()

  vim.lsp.buf_request_all(
    0,
    "textDocument/codeAction",
    params,
    function(results)
      on_code_action_results(
        results,
        {
          bufnr = 0,
          method = "textDocument/codeAction",
          params = params,
          win = win
        }
      )
    end
  )
end

return M
