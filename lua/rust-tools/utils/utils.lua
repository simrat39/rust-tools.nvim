local vim = vim

local M = {}

function M.delete_buf(bufnr)
    if bufnr ~= nil then
        vim.api.nvim_buf_delete(bufnr, {force=true})
    end
end

function M.split(vertical, bufnr)
    local cmd = vertical and "vsplit" or "split"

    vim.cmd(cmd)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, bufnr)
end

function M.resize(vertical, amount)
   local cmd = vertical and "vertical resize " or "resize"
   cmd = cmd .. amount

   vim.cmd(cmd)
end

return M
