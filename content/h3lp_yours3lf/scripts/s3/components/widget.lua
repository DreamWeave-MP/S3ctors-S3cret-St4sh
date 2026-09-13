---@omw-context menu|player

local emptyOptions = {}

---H3 UI component primitive for passive base Widget layouts.
---@module 'scripts.s3.components.widget'

local ui = require 'openmw.ui'

---Build a base Widget layout.
---Allocates fresh layout, props, and external tables. If `content` or `children` is provided,
---it is wrapped in a fresh `openmw.ui.Content`. The caller owns the returned layout;
---this module does not call `ui.create`, mutate layers, register anything, or persist state.
---@param options? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function widget(options)
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
    type = ui.TYPE.Widget,
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

return widget
