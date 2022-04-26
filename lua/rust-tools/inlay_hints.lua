local rt = require("rust-tools")

local M = {}

function M.new()
  M.namespace = vim.api.nvim_create_namespace("experimental/inlayHints")
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
    M.cache_render(self, false, bufnr)
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
  M.cache_render(self, false, 0)
end

-- Clear hints only for the current buffer
function M.unset()
  clear_ns()
end

function M.enable_cache_autocmd()
  vim.cmd([[
        augroup InlayHintsCache
        autocmd BufWritePost,BufReadPost *.rs :lua require"rust-tools".inlay_hints.cache(false)
        autocmd BufEnter,BufWinEnter,TabEnter *.rs :lua require"rust-tools".inlay_hints.cache(true)
        augroup END
    ]])
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

local function get_params()
  return { textDocument = vim.lsp.util.make_text_document_params() }
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

function M.cache_render(self, cheap, bufnr)
  local buffer = bufnr or vim.api.nvim_get_current_buf()
  if cheap and self.cache[buffer] ~= nil then
    return
  end

  for _, v in ipairs(vim.lsp.buf_get_clients(buffer)) do
    if rt.utils.is_ra_server(v) then
      v.request(
        "experimental/inlayHints",
        get_params(),
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
  clear_ns(buffer)

  local hints = self.cache[buffer]

  for key, value in pairs(hints) do
    local virt_text = ""
    local line = tonumber(key)

    local current_line = vim.api.nvim_buf_get_lines(
      bufnr,
      line,
      line + 1,
      false
    )[1]

    if current_line then
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
          if value_inner_inner.kind == 2 and opts.show_variable_name then
            local char_start = value_inner_inner.range.start.character
            local char_end = value_inner_inner.range["end"].character
            local variable_name = string.sub(
              current_line,
              char_start + 1,
              char_end
            )
            virt_text = virt_text
              .. variable_name
              .. ": "
              .. value_inner_inner.label
          else
            if string.sub(value_inner_inner.label, 1, 2) == ": " then
              virt_text = virt_text .. value_inner_inner.label:sub(3)
            else
              virt_text = virt_text .. value_inner_inner.label
            end
          end
          if i ~= #other_hints then
            virt_text = virt_text .. ", "
          end
        end
      end

      -- set the virtual text if it is not empty
      if virt_text ~= "" then
        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, line, 0, {
          virt_text_pos = opts.right_align and "right_align" or "eol",
          virt_text = {
            { virt_text, opts.highlight },
          },
          hl_mode = "combine",
        })
      end
    end
  end
end

return M
