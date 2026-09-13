---@omw-context menu|player

local emptyOptions = {}

---H3 UI component primitive for passive Container layouts.
---@module 'scripts.s3.components.container'

local ui = require 'openmw.ui'

---Build a Container layout that wraps its children.
---Allocates fresh layout, props, external, and content wrapper tables.
---The caller owns the layout and any later Element; no element is created here.
---@param options? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function container(options)
  options = options or emptyOptions

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  local layout = {
    type = ui.TYPE.Container,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
  local children = options.content or options.children

  if children then layout.content = ui.content(children) end
  return layout
end

return container
