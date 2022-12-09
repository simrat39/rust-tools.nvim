local termopen = require("rust-tools.executors.termopen")
local quickfix = require("rust-tools.executors.quickfix")
local toggleterm = require("rust-tools.executors.toggleterm")

local M = {}

M.termopen = termopen
M.quickfix = quickfix
M.toggleterm = toggleterm

return M
