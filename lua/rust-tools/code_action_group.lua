local M = {}

---@private
local function apply_action(action, client, ctx)
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
local function on_user_choice(action, ctx)
  if not action then
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
  local client = vim.lsp.get_client_by_id(action.client_id)
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
      apply_action(resolved_action, client, ctx)
    end)
  else
    apply_action(action, client, ctx)
  end
end

local select_code_action_results = function(results, ctx)
  if results.error then
    vim.notify(results.error, vim.log.levels.ERROR)
  end

  local action_tuples = {}
  for client_id, result in pairs(results) do
    for _, action in pairs(result.result or {}) do
      action.client_id = client_id
      table.insert(action_tuples, action)
    end
  end
  if #action_tuples == 0 then
    vim.notify("No code actions available", vim.log.levels.INFO)
    return
  end

  local entries, groups = {}, {}
  for _, action in ipairs(action_tuples) do
    -- Some clippy lints may have newlines in them
    action.title = string.gsub(action.title, "[\n\r]+", " ")

    if action.group then
      if not groups[action.group] then
        local group =
          { title = action.group .. " ▶", actions = {}, idx = nil }
        groups[action.group] = group
        table.insert(entries, group)
      end

      table.insert(groups[action.group].actions, action)
    else
      table.insert(entries, action)
    end
  end

  vim.ui.select(entries, {
    prompt = "Code Actions:",
    format_item = function(item)
      return item.title
    end,
  }, function(selected)
    if not selected then
      return
    end

    if selected.actions then
      vim.schedule(function()
        vim.ui.select(selected.actions, {
          prompt = selected.title .. ": ",
          format_item = function(item)
            return item.title
          end,
        }, function(selected_group)
          if not selected_group then
            return
          end
          print(vim.inspect(selected_group))

          vim.schedule(function()
            on_user_choice(selected_group, ctx)
          end)
        end)
      end)
    else
      vim.schedule(function()
        on_user_choice(selected, ctx)
      end)
    end
  end)
end

function M.code_action_group()
  local context = {}
  context.diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  local params = vim.lsp.util.make_range_params()
  params.context = context

  vim.lsp.buf_request_all(
    0,
    "textDocument/codeAction",
    params,
    function(results)
      select_code_action_results(
        results,
        { bufnr = 0, method = "textDocument/codeAction", params = params }
      )
    end
  )
end

return M
