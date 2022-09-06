local rt = require("rust-tools")

local M = {}

local function get_opts()
  return { full = rt.config.options.tools.crate_graph.full }
end

-- Creation of the correct handler depending on the initial call of the command
-- and give the option to override global settings
local function handler_factory(backend, output, pipe)
  backend = backend or rt.config.options.tools.crate_graph.backend
  output = output or rt.config.options.tools.crate_graph.output
  pipe = pipe or rt.config.options.tools.crate_graph.pipe

  -- Graph is a representation of the crate graph following the graphviz format
  -- The handler processes and pipes the graph to the dot command that will
  -- visualize with the given backend
  return function(err, graph)
    if err ~= nil then
      error("Could not execute request to server" .. err)
      return
    end

    -- Validating backend
    if
      not rt.utils.contains(
        rt.config.options.tools.crate_graph.enabled_graphviz_backends,
        backend
      )
    then
      error("Backend not recognized as valid")
    end

    graph = string.gsub(graph, "\n", "")
    print("rust-tools: Processing crate graph. This may take a while...")

    local cmd = "dot -T" .. backend
    if pipe ~= nil then -- optionally pipe to `pipe`
      cmd = cmd .. " | " .. pipe
    end
    if output ~= nil then -- optionally redirect to `output`
      cmd = cmd .. " > " .. output
    end

    -- Execute dot command to generate the output graph
    -- Needs to be handled with care to prevent security problems
    local handle = io.popen(cmd, "w")
    handle:write(graph)

    -- needs to be here otherwise dot may take a long time before it gets
    -- any input + cleaning up (not waiting for garbage collection)
    handle:flush()
    handle:close()
  end
end

function M.view_crate_graph(backend, output, pipe)
  rt.utils.request(
    0,
    "rust-analyzer/viewCrateGraph",
    get_opts(),
    handler_factory(backend, output, pipe)
  )
end

return M
