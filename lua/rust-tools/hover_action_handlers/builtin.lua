local rt = require("rust-tools")

return function(options)
  if not options.actions then
    return
  end

  local config = {}
  if
    rt.config
    and rt.config.options
    and rt.config.options.tools
    and rt.config.options.tools.hover_actions
    and rt.config.options.tools.hover_actions
  then
    config = rt.config.options.tools.hover_actions
  end

  vim.ui.select(options.actions, {
    kind = "hoveraction",
    prompt = config.prompt,
    format_item = function(item)
      return item.title
    end,
  }, function(choice)
    if choice then
      choice.execute()
    end
  end)
end
