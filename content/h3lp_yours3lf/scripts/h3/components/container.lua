---@omw-context menu|player

---H3 UI component primitive for passive Container layouts.
---@module 'scripts.h3.components.container'

local ui = require 'openmw.ui'

local Next = next

local UiContent, UiType = ui.content, ui.TYPE
local EmptyOptions = {}

---Build a Container layout that wraps its children.
---Allocates fresh layout, props, external, and content wrapper tables.
---The caller owns the layout and any later Element; no element is created here.
---@param options? H3.ContainerOptions
---@return openmw.ui.Layout
local function container(options)
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
    type = UiType.Container,
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

return container
