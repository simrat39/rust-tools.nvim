---@mod ferris.executors

local termopen = require("rust-tools.executors.termopen")
local quickfix = require("rust-tools.executors.quickfix")
local toggleterm = require("rust-tools.executors.toggleterm")
local vimux = require("rust-tools.executors.vimux")

local M = {}

---@class FerrisExecutor
---@field execute_command fun(cmd:string, args:string[], cwd:string)

M.termopen = termopen
M.quickfix = quickfix
M.toggleterm = toggleterm
M.vimux = vimux

return M
