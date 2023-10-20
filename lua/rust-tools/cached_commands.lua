local M = {}

local cache = {
  last_debuggable = nil,
  last_runnable = nil,
}

-- @param action
M.set_last_runnable = function(choice, result)
  cache.last_runnable = { choice, result }
end

-- @param args
M.set_last_debuggable = function(args)
  cache.last_debuggable = args
end

M.execute_last_debuggable = function()
  local args = cache.last_debuggable
  if args then
    local rt_dap = require("rust-tools.dap")
    rt_dap.start(args)
  else
    local debuggables = require("rust-tools.debuggables")
    debuggables()
  end
end

M.execute_last_runnable = function()
  local action = cache.last_runnable
  local runnables = require("rust-tools.runnables")
  if action then
    runnables.run_command(action[0], action[1])
  else
    runnables.runnables()
  end
end

return M
