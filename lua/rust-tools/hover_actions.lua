local utils = require("rust-tools.utils.utils")
local util = vim.lsp.util
local config = require("rust-tools.config")

local M = {}

local function get_params()
	return vim.lsp.util.make_position_params()
end

M._state = { winnr = nil, commands = nil }
M.code_actions = {}

local set_keymap_opt = { noremap = true, silent = true }

-- run the command under the cursor, if the thing under the cursor is not the
-- command then do nothing
function M._run_command()
  local line = vim.api.nvim_win_get_cursor(M._state.winnr)[1]

  if line > (#(M._state.commands or {}) + #M.code_actions) then return end

  local action = M._state.commands and M._state.commands[line - #M.code_actions] or nil
  if action then
    M._close_hover()
    M.execute_rust_analyzer_command(action)
  else
    action = M.code_actions[line]
    M._close_hover()
    if action then
      require'lspsaga.api'.code_action_execute(action[1], action[2], M.ctx)
    end
  end
end

function M.execute_rust_analyzer_command(action)
	local fn = vim.lsp.commands[action.command]
	if fn then
		fn(action)
	end
end

function M._close_hover()
	if M._state.winnr ~= nil then
		vim.api.nvim_win_close(M._state.winnr, true)
	end
end

local function parse_commands()
  local prompt = {}
  if #M.code_actions ~= 0 then
    for i, info in ipairs(M.code_actions) do
      table.insert(prompt, string.format("%d. %s ", i, info[2].title))
    end
  end

  if M._state.commands then
    for i, value in ipairs(M._state.commands) do
      i = i + #M.code_actions
      if value.command == "rust-analyzer.gotoLocation" then
        table.insert(prompt, string.format("%d. Go to %s (%s)", i, value.title, value.tooltip))
      elseif value.command == "rust-analyzer.showReferences" then
        table.insert(prompt, string.format("%d. %s", i, "Go to " .. value.title))
      else
        table.insert(prompt, string.format("%d. %s", i, value.title))
      end
    end
  end

  return prompt
end

function M.handler(_, result, code_actions)
  if not (result and result.contents) and next(code_actions) == nil then
    return
  elseif next(code_actions) ~= nil then
    M.code_actions = code_actions
  end

	local markdown_lines = (result and result.contents) and result.contents or nil
  if config.options.tools.hover_actions.hide_content or not markdown_lines then
    markdown_lines = { "------" }
  end
  markdown_lines = util.convert_input_to_markdown_lines(markdown_lines)
	markdown_lines = util.trim_empty_lines(markdown_lines)

	if vim.tbl_isempty(markdown_lines) then
		return
	end

	local bufnr, winnr = util.open_floating_preview(markdown_lines, "markdown", {
		border = config.options.tools.hover_actions.border,
		focusable = true,
		focus_id = "rust-tools-hover-actions",
		close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
	})

	if config.options.tools.hover_actions.auto_focus then
		vim.api.nvim_set_current_win(winnr)
	end

	if M._state.winnr ~= nil then
		return
	end

	-- update the window number here so that we can map escape to close even
	-- when there are no actions, update the rest of the state later
	M._state.winnr = winnr
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<Esc>",
		":lua require'rust-tools.hover_actions'._close_hover()<CR>",
		set_keymap_opt
	)

	vim.api.nvim_buf_attach(bufnr, false, {
		on_detach = function()
			M._state.winnr = nil
		end,
	})

	--- stop here if there are no possible actions
  if next(M.code_actions) == nil and not (result or result.actions)  then
    vim.notify("No code actions found", vim.log.levels.INFO, {})
    return M._close_hover()
  end

	-- syntax highlighting
	vim.api.nvim_buf_set_option(bufnr, "filetype", "rust")

  -- update the state
  if result and result.actions then
    M._state.commands = result.actions[1].commands
  end

	local prompt = parse_commands()

	-- get the maximum length of all the possible commands
	local max_len = 0
	for _, line in ipairs(prompt) do
		if #line > max_len then
			max_len = #line
		end
	end

	--- update the height to compensate for the commands being added
	local old_height = vim.api.nvim_win_get_height(winnr)
	vim.api.nvim_win_set_height(winnr, old_height + #prompt)

	--- update the width to compensate for the commands being added
	local old_width = vim.api.nvim_win_get_width(winnr)
	if max_len > old_width then
		vim.api.nvim_win_set_width(winnr, max_len)
	end

	-- make it modifiable so that the commands text can be added
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	-- makes more sense in a dropdown-ish ui
	vim.api.nvim_win_set_option(winnr, "cursorline", true)
	-- write to the buffer containing the hover text
	vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, prompt)
	-- no need now since we have written all we want
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	-- move cursor to the start since its at the place before we added the
	-- commands text
	vim.api.nvim_win_set_cursor(winnr, { 1, 0 })
	-- run the command under the cursor
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<CR>",
		":lua require'rust-tools.hover_actions'._run_command()<CR>",
		set_keymap_opt
	)
	-- close on escape
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<Esc>",
		":lua require'rust-tools.hover_actions'._close_hover()<CR>",
		set_keymap_opt
	)
end

-- Sends the request to rust-analyzer to get hover actions and handle it
function M.hover_actions()
  utils.request(0, "textDocument/hover", get_params(), function(_,result)
    require('lspsaga.api').code_action_request({
      params = vim.lsp.util.make_range_params(),
      callback = function (ctx)
        M.ctx = ctx
        return function(response)
          local code_actions = {}
          for client_id, result in pairs(response or {}) do
            for _, action in ipairs(result.result or {}) do
              table.insert(code_actions, { client_id, action })
            end
          end
          M.handler(_, result, code_actions)
        end
      end
    })
  end)
end

return M
