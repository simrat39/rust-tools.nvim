local config = require("rust-tools.config")
local loop = vim.loop

local M = {}

local function get_free_port()
  local server = loop.new_tcp()
  assert(loop.tcp_bind(server, "127.0.0.1", 0), "Unable to find an open port")

  local port = loop.tcp_getsockname(server).port
  loop.close(server)
  return port
end
---For the heroes who want to use it
---@param codelldb_path string
---@param liblldb_path string
---@param port number to pass to codelldb
function M.get_codelldb_adapter(codelldb_path, liblldb_path, port)
  return function(callback, _)
    local stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)
    local handle
    local pid_or_err
    local error_message = ""

    port = port or get_free_port()

    local opts = {
      stdio = { nil, stdout, stderr },
      args = { "--liblldb", liblldb_path, "--port", port },
      detached = true,
    }

    handle, pid_or_err = vim.loop.spawn(codelldb_path, opts, function(code)
      stdout:close()
      stderr:close()
      handle:close()
      if code ~= 0 then
        print("codelldb exited with code", code)
        print("error message", error_message)
      end
    end)

    assert(handle, "Error running codelldb: " .. tostring(pid_or_err))

    stdout:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        vim.schedule(function()
          require("dap.repl").append(chunk)
        end)
      end
    end)
    stderr:read_start(function(_, chunk)
      if chunk then
        error_message = error_message .. chunk

        vim.schedule(function()
          require("dap.repl").append(chunk)
        end)
      end
    end)

    vim.defer_fn(function()
      vim.schedule(function()
        callback({
          type = "server",
          host = "127.0.0.1",
          port = port,
        })
      end)
    end, 500)
  end
end

function M.setup_adapter()
  local dap = require("dap")
  dap.adapters.rt_lldb = config.options.dap.adapter
end

local function get_cargo_args_from_runnables_args(runnable_args)
  local cargo_args = runnable_args.cargoArgs

  table.insert(cargo_args, "--message-format=json")

  for _, value in ipairs(runnable_args.cargoExtraArgs) do
    table.insert(cargo_args, value)
  end

  return cargo_args
end

local function scheduled_error(err)
  vim.schedule(function()
    vim.notify(err, vim.log.levels.ERROR)
  end)
end

function M.start(args)
  if not pcall(require, "dap") then
    scheduled_error("nvim-dap not found.")
    return
  end

  if not pcall(require, "plenary.job") then
    scheduled_error("plenary not found.")
    return
  end

  local dap = require("dap")
  local Job = require("plenary.job")

  local cargo_args = get_cargo_args_from_runnables_args(args)

  vim.notify(
    "Compiling a debug build for debugging. This might take some time..."
  )

  Job
    :new({
      command = "cargo",
      args = cargo_args,
      cwd = args.workspaceRoot,
      on_exit = function(j, code)
        if code and code > 0 then
          scheduled_error(
            "An error occured while compiling. Please fix all compilation issues and try again."
          )
        end
        vim.schedule(function()
          for _, value in pairs(j:result()) do
            local json = vim.fn.json_decode(value)
            if
              type(json) == "table"
              and json.executable ~= vim.NIL
              and json.executable ~= nil
            then
              local dap_config = {
                name = "Rust tools debug",
                type = "rt_lldb",
                request = "launch",
                program = json.executable,
                args = args.executableArgs or {},
                cwd = args.workspaceRoot,
                stopOnEntry = false,

                -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
                --
                --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
                --
                -- Otherwise you might get the following error:
                --
                --    Error on launch: Failed to attach to the target process
                --
                -- But you should be aware of the implications:
                -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
                runInTerminal = false,
              }
              dap.run(dap_config)
              break
            end
          end
        end)
      end,
    })
    :start()
end

return M
