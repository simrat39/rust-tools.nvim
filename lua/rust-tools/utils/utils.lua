local vim = vim

local M = {}

function M.delete_buf(bufnr)
    if bufnr ~= nil then vim.api.nvim_buf_delete(bufnr, {force = true}) end
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

function M.override_apply_text_edits()
   local old_func = vim.lsp.util.apply_text_edits
   vim.lsp.util.apply_text_edits = function (edits, bufnr)
       M.snippet_text_edits_to_text_edits(edits)
       old_func(edits, bufnr)
   end
end

function M.snippet_text_edits_to_text_edits(spe)
    for _, value in ipairs(spe) do
        if value.newText and value.insertTextFormat then
            value.newText = string.gsub(value.newText, "%$%d", "");
        end
    end
end

function M.is_bufnr_rust(bufnr)
    return vim.api.nvim_buf_get_option(bufnr, 'ft') == 'rust'
end

function M.contains(list, item)
    for _, val in ipairs(list) do
        if item == val then
            return true
        end
    end
    return false
end

-- callback args changed in Neovim 0.5.1/0.6. See:
-- https://github.com/neovim/neovim/pull/15504
function M.mk_handler(fn)
  return function(...)
    local config_or_client_id = select(4, ...)
    local is_new = type(config_or_client_id) ~= "number"
    if is_new then
      fn(...)
    else
      local err = select(1, ...)
      local method = select(2, ...)
      local result = select(3, ...)
      local client_id = select(4, ...)
      local bufnr = select(5, ...)
      local config = select(6, ...)
      fn(err, result, { method = method, client_id = client_id, bufnr = bufnr }, config)
    end
  end
end

-- from mfussenegger/nvim-lsp-compl@29a81f3
function M.request(bufnr, method, params, handler)
  return vim.lsp.buf_request(bufnr, method, params, M.mk_handler(handler))
end

return M
