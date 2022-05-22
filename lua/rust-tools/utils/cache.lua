local M = {}

local cache = {
  last_runnable = nil,
}

-- @param action 
M.set_last_runnable = function(action)
  cache.last_runnable = action
end

M.execute_last_runnable = function()
  local action = cache.last_runnable

  -- see hover_actions.lua execute_rust_analyzer_command
  if action then 
    local fn = vim.lsp.commands[action.command]

    if fn then 
      fn(action)
    end
  end
end

return M
