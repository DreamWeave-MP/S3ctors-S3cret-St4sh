---@omw-context menu|player

local emptyOptions = {}

---H3 UI component primitive for passive MWUI box layouts.
---@module 'scripts.s3.components.box'

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build an MWUI boxed container layout.
---Allocates fresh layout, props, external, and content wrapper tables. Uses shared MWUI templates
---read-only; callers own mounting and any later layout mutation.
---@param options? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function box(options)
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
    template = options.template or I.MWUI.templates.box,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
  }
  local children = options.content or options.children

  if children then layout.content = ui.content(children) end
  return layout
end

return box
