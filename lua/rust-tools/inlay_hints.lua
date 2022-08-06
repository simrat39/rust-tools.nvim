local rt = require("rust-tools")

local M = {}

function M.new()
  M.namespace = vim.api.nvim_create_namespace("textDocument/inlayHints")
  local self = setmetatable({ cache = {}, enabled = false }, { __index = M })

  return self
end

local function clear_ns(bufnr)
  -- clear namespace which clears the virtual text as well
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

-- Disable hints and clear all cached buffers
function M.disable(self)
  self.disable = false
  M.disable_cache_autocmd()

  for k, _ in pairs(self.cache) do
    if vim.api.nvim_buf_is_valid(k) then
      clear_ns(k)
    end
  end
end

local function set_all(self)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    M.cache_render(self, bufnr)
  end
end

-- Enable auto hints and set hints for the current buffer
function M.enable(self)
  self.enabled = true
  M.enable_cache_autocmd()
  set_all(self)
end

-- Set inlay hints only for the current buffer
function M.set(self)
  M.cache_render(self, 0)
end

-- Clear hints only for the current buffer
function M.unset()
  clear_ns()
end

function M.enable_cache_autocmd()
  local opts = rt.config.options.tools.inlay_hints
  vim.cmd(string.format(
    [[
        augroup InlayHintsCache
        autocmd BufWritePost,BufReadPost,BufEnter,BufWinEnter,TabEnter,TextChanged,TextChangedI *.rs :lua require"rust-tools".inlay_hints.cache()
        %s
        augroup END
    ]],
    opts.only_current_line
        and "autocmd CursorMoved *.rs :lua require'rust-tools'.inlay_hints.render()"
      or ""
  ))
end

function M.disable_cache_autocmd()
  vim.cmd(
    [[
    augroup InlayHintsCache
    autocmd!
    augroup END
  ]],
    false
  )
end

local function get_params(bufnr)
  ---@diagnostic disable-next-line: missing-parameter
  local params = vim.lsp.util.make_given_range_params()
  params["range"]["start"]["line"] = 0
  params["range"]["end"]["line"] = vim.api.nvim_buf_line_count(bufnr) - 1

  return params
end

-- parses the result into a easily parsable format
-- example:
-- {
--  ["12"] = { {
--      kind = "TypeHint",
--      label = "String"
--    } },
--  ["13"] = { {
--      kind = "TypeHint",
--      label = "usize"
--    } },
-- }
--
local function parse_hints(result)
  local map = {}

  if type(result) ~= "table" then
    return {}
  end
  for _, value in pairs(result) do
    local range = value.position
    local line = value.position.line
    local label = value.label
    local kind = value.kind

    local function add_line()
      if map[line] ~= nil then
        table.insert(map[line], { label = label, kind = kind, range = range })
      else
        map[line] = { { label = label, kind = kind, range = range } }
      end
    end

    add_line()
  end
  return map
end

function M.cache_render(self, bufnr)
  local buffer = bufnr or vim.api.nvim_get_current_buf()

  for _, v in ipairs(vim.lsp.buf_get_clients(buffer)) do
    if rt.utils.is_ra_server(v) then
      v.request(
        "textDocument/inlayHint",
        get_params(buffer),
        function(err, result, ctx)
          if err then
            return
          end

          self.cache[ctx.bufnr] = parse_hints(result)

          M.render(self, ctx.bufnr)
        end,
        buffer
      )
    end
  end
end

function M.render(self, bufnr)
  local opts = rt.config.options.tools.inlay_hints
  local buffer = bufnr or vim.api.nvim_get_current_buf()

  local hints = self.cache[buffer]

  if hints == nil then
    return
  end

  clear_ns(buffer)

  for key, value in pairs(hints) do
    local virt_text = ""
    local line = tonumber(key)

    if opts.only_current_line then
      local curr_line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1
      if line ~= curr_line_nr then
        goto continue
      end
    end

    local param_hints = {}
    local other_hints = {}

    -- segregate paramter hints and other hints
    for _, value_inner in ipairs(value) do
      if value_inner.kind == 2 then
        table.insert(param_hints, value_inner.label)
      end

      if value_inner.kind == 1 then
        table.insert(other_hints, value_inner)
      end
    end

    -- show parameter hints inside brackets with commas and a thin arrow
    if not vim.tbl_isempty(param_hints) and opts.show_parameter_hints then
      virt_text = virt_text .. opts.parameter_hints_prefix .. "("
      for i, value_inner_inner in ipairs(param_hints) do
        virt_text = virt_text .. value_inner_inner:sub(1, -2)
        if i ~= #param_hints then
          virt_text = virt_text .. ", "
        end
      end
      virt_text = virt_text .. ") "
    end

    -- show other hints with commas and a thicc arrow
    if not vim.tbl_isempty(other_hints) then
      virt_text = virt_text .. opts.other_hints_prefix
      for i, value_inner_inner in ipairs(other_hints) do
        if string.sub(value_inner_inner.label, 1, 2) == ": " then
          virt_text = virt_text .. value_inner_inner.label:sub(3)
        else
          virt_text = virt_text .. value_inner_inner.label
        end
        if i ~= #other_hints then
          virt_text = virt_text .. ", "
        end
      end
    end

    -- set the virtual text if it is not empty
    if virt_text ~= "" then
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_buf_set_extmark(buffer, M.namespace, line, 0, {
        virt_text_pos = opts.right_align and "right_align" or "eol",
        virt_text = {
          { virt_text, opts.highlight },
        },
        hl_mode = "combine",
      })
    end
  end
  ::continue::
end

return M
