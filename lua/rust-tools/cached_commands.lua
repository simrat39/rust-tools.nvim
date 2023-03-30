local rt = require("rust-tools")
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
    rt.dap.start(args)
  else
    rt.debuggables.debuggables()
  end
end

M.execute_last_runnable = function()
  local action = cache.last_runnable
  if action then
    rt.runnables.run_command(action[1], action[2])
  else
    rt.runnables.runnables()
  end
end

return M
