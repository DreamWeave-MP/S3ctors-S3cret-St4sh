---@omw-context menu|player

---H3 UI component primitive for passive base Widget layouts.
---@module 'scripts.h3.components.widget'

local ui = require 'openmw.ui'

local Next = next

local UiContent, UiType = ui.content, ui.TYPE

local EmptyOptions = {}
---Build a base Widget layout.
---Allocates fresh layout, props, and external tables. If `content` or `children` is provided,
---it is wrapped in a fresh `openmw.ui.Content`. The caller owns the returned layout;
---this module does not call `ui.create`, mutate layers, register anything, or persist state.
---@param options? H3.WidgetOptions
---@return openmw.ui.Layout
local function widget(options)
  options = options or EmptyOptions

  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end

  local layout = {
    type = UiType.Widget,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
  local children = options.content or options.children

  if children then layout.content = UiContent(children) end
  return layout
end

return widget
