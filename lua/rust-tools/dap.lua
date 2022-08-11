local rt = require("rust-tools")

local M = {}

---For the heroes who want to use it
---@param codelldb_path string
---@param liblldb_path string
function M.get_codelldb_adapter(codelldb_path, liblldb_path)
  return {
    type = "server",
    port = "${port}",
    host = "127.0.0.1",
    executable = {
      command = codelldb_path,
      args = { "--liblldb", liblldb_path, "--port", "${port}" },
    },
  }
end

function M.setup_adapter()
  local dap = require("dap")
  dap.adapters.rt_lldb = rt.config.options.dap.adapter
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

local function get_rustc_hash(callback)
  local Job = require("plenary.job")
  Job
    :new({
      command = "rustc",
      args = { "--version", "--verbose" },
      clear_env = false,
      on_exit = function(j, code)
        if code and code > 0 then
          scheduled_error(
            "An error occured while trying to get the commit hash of rustc. Could not set the libstd source map."
          )
          return
        end
        local commit_hash = vim.split(j:result()[3], " ")[2]
        callback(commit_hash)
      end,
    })
    :start()
end

local function get_rustc_sysroot(callback)
  local Job = require("plenary.job")
  Job
    :new({
      command = "rustc",
      args = { "--print", "sysroot" },
      on_exit = function(j, code)
        if code and code > 0 then
          scheduled_error(
            "An error occured while trying to get the sysroot path of rustc. Could not set the libstd source map."
          )
          return
        end
        local sysroot = j:result()[1]
        callback(sysroot)
      end,
    })
    :start()
end

local function setup_std_source_map()
  get_rustc_hash(function(rustc_commit_hash)
    get_rustc_sysroot(function(rustc_sysroot)
      local new_map = {
        "/rustc/" .. rustc_commit_hash,
        rustc_sysroot .. "/lib/rustlib/src/rust",
      }
      if not rt.config.options.dap.configuration.sourceMap then
        rt.config.options.dap.configuration.sourceMap = {}
      end
      vim.list_extend(
        rt.config.options.dap.configuration.sourceMap,
        { new_map }
      )
    end)
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

  -- setup libstd source map
  if rt.config.options.dap.std_source_map then
    setup_std_source_map()
  end

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
              dap.run(
                vim.tbl_deep_extend(
                  "force",
                  dap_config,
                  rt.config.options.dap.configuration
                )
              )
              break
            end
          end
        end)
      end,
    })
    :start()
end

return M
