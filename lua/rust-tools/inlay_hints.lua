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

          local lines = {}
          for _, hint in pairs(result) do
            local line_number = hint.position.line + 1
            local line = lines[line_number]
            if not line then
              line = {}
              lines[line_number] = line
            end
            table.insert(line, hint)
          end

          self.cache[ctx.bufnr] = lines

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

local function render_line(line, line_hints, bufnr, _)
  -- print("Hints")
  -- print(vim.inspect(line_hints))
  local opts = rt.config.options.tools.inlay_hints

  if line > vim.api.nvim_buf_line_count(bufnr) then
    return
  end

  local hints = {}

  -- Discarded: label[].location, textEdits
  for _, hint in ipairs(line_hints) do
    if opts.show_param_hints and hint.kind == 2 or hint.kind == 1 then
      table.insert(hints, {
        kind = hint.kind,
        position = hint.position,
        label = parse_hint_label(hint.label),
        paddingLeft = hint.paddingLeft,
        paddingRight = hint.paddingRight,
      })
    end
  end

  for _, hint in ipairs(hints) do
    local text = {}
    if hint.paddingLeft then
      table.insert(text, { " ", "NonText" })
    end
    table.insert(text, { hint.label, opts.highlight })
    if hint.paddingRight then
        table.insert(text, { " ", "NonText" })
    end
    vim.api.nvim_buf_set_extmark(
      bufnr,
      M.namespace,
      hint.position.line,
      hint.position.character,
      {
        virt_text_pos = "inline",
        virt_text = text,
        hl_mode = "combine",
      }
    )
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

  if opts.only_current_line then
    local curr_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line_hints = hints[curr_line]
    if line_hints then
      render_line(curr_line, line_hints, buffer)
    end
  else
    for line, line_hints in pairs(hints) do
      render_line(line, line_hints, buffer)
    end
  end
end

return M
