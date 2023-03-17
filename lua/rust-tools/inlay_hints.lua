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
  clear_ns(0)
end

function M.enable_cache_autocmd()
  local opts = rt.config.options.tools.inlay_hints
  vim.cmd(
    string.format(
      [[
        augroup InlayHintsCache
        autocmd BufWritePost,BufReadPost,BufEnter,BufWinEnter,TabEnter,TextChanged,TextChangedI *.rs :lua require"rust-tools".inlay_hints.cache()
        %s
        augroup END
    ]],
      opts.only_current_line
          and "autocmd CursorMoved,CursorMovedI *.rs :lua require'rust-tools'.inlay_hints.render()"
        or ""
    )
  )
end

function M.disable_cache_autocmd()
  vim.cmd([[
    augroup InlayHintsCache
    autocmd!
    augroup END
  ]])
end

local function get_params(client, bufnr)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = {
        line = 0,
        character = 0,
      },
      ["end"] = {
        line = 0,
        character = 0,
      },
    },
  }

  local line_count = vim.api.nvim_buf_line_count(bufnr) - 1
  local last_line =
    vim.api.nvim_buf_get_lines(bufnr, line_count, line_count + 1, true)

  params["range"]["end"]["line"] = line_count
  params["range"]["end"]["character"] = vim.lsp.util.character_offset(
    bufnr,
    line_count,
    #last_line[1],
    client.offset_encoding
  )

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
local function parse_hints(result, bufnr)
  local map = {}
  local max_line_len = 0

  if type(result) ~= "table" then
    return {}
  end

  for _, value in pairs(result) do
    local range = value.position
    local line = value.position.line
    local label = value.label
    local kind = value.kind

    local status_ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, line, line + 1, true)

    if not status_ok then
        break
    end

    local line_len = string.len(lines[1])
    max_line_len = math.max(max_line_len, line_len)

    if map[line] ~= nil then
      table.insert(map[line], { label = label, kind = kind, range = range })
    else
      map[line] = { { label = label, kind = kind, range = range } }
    end
  end
  return map, max_line_len
end

function M.cache_render(self, bufnr)
  local buffer = bufnr or vim.api.nvim_get_current_buf()

  for _, v in pairs(vim.lsp.get_active_clients({ bufnr = buffer })) do
    if rt.utils.is_ra_server(v) then
      v.request(
        "textDocument/inlayHint",
        get_params(v, buffer),
        function(err, result, ctx)
          if err then
            return
          end

          if not vim.api.nvim_buf_is_loaded(ctx.bufnr) then
            self.cache[ctx.bufnr] = nil
            return
          end

          local hints, max_line_len = parse_hints(result, ctx.bufnr)
          self.cache[ctx.bufnr] = { hints = hints, max_line_len = max_line_len }

          M.render(self, ctx.bufnr)
        end,
        buffer
      )
    end
  end
end

local function parse_hint_label(hint_label)
  if type(hint_label) == "string" then
    return hint_label
  elseif type(hint_label) == "table" then
    return table.concat(vim.tbl_map(function(label_part)
      return label_part.value
    end, hint_label))
  end
end

local function render_line(line, line_hints, bufnr, max_line_len)
  local opts = rt.config.options.tools.inlay_hints
  local virt_text = ""

  local param_hints = {}
  local other_hints = {}

  if line > vim.api.nvim_buf_line_count(bufnr) then
    return
  end

  if opts.max_len_align then
    local line_len =
      string.len(vim.api.nvim_buf_get_lines(bufnr, line, line + 1, true)[1])

    virt_text =
      string.rep(" ", max_line_len - line_len + opts.max_len_align_padding)
  end

  -- segregate parameter hints and other hints
  for _, hint in ipairs(line_hints) do
    if hint.kind == 2 then
      table.insert(param_hints, parse_hint_label(hint.label))
    end

    if hint.kind == 1 then
      table.insert(other_hints, parse_hint_label(hint.label))
    end
  end

  -- show parameter hints inside brackets with commas and a thin arrow
  if not vim.tbl_isempty(param_hints) and opts.show_parameter_hints then
    virt_text = virt_text .. opts.parameter_hints_prefix .. "("
    for i, p_hint in ipairs(param_hints) do
      virt_text = virt_text .. p_hint:sub(1, -2)
      if i ~= #param_hints then
        virt_text = virt_text .. ", "
      end
    end
    virt_text = virt_text .. ") "
  end

  -- show other hints with commas and a thicc arrow
  if not vim.tbl_isempty(other_hints) then
    virt_text = virt_text .. opts.other_hints_prefix
    for i, o_hint in ipairs(other_hints) do
      virt_text = virt_text .. o_hint:gsub("^: ", "")
      if i ~= #other_hints then
        virt_text = virt_text .. ", "
      end
    end
  end

  -- set the virtual text if it is not empty
  if virt_text ~= "" then
    ---@diagnostic disable-next-line: param-type-mismatch
    if opts.right_align then
      virt_text = virt_text .. string.rep(" ", opts.right_align_padding)
    end
    vim.api.nvim_buf_set_extmark(bufnr, M.namespace, line, 0, {
      virt_text_pos = opts.right_align and "right_align" or "eol",
      virt_text = {
        { virt_text, opts.highlight },
      },
      hl_mode = "combine",
    })
  end
end

function M.render(self, bufnr)
  local opts = rt.config.options.tools.inlay_hints
  local buffer = bufnr or vim.api.nvim_get_current_buf()

  local cached = self.cache[buffer]

  if cached == nil then
    return
  end

  local hints, max_line_len = cached.hints, cached.max_line_len

  clear_ns(buffer)

  if opts.only_current_line then
    local curr_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line_hints = hints[curr_line]
    if line_hints then
      render_line(curr_line, line_hints, buffer, max_line_len)
    end
  else
    for line, line_hints in pairs(hints) do
      render_line(line, line_hints, buffer, max_line_len)
    end
  end
end

return M
