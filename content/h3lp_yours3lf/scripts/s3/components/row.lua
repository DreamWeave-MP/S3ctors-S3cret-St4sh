---@omw-context menu|player

local emptyOptions = {}

---H3 UI component primitive for passive horizontal Flex layouts.
---@module 'scripts.s3.components.row'

local ui = require 'openmw.ui'

---Build a horizontal Flex layout.
---Allocates fresh layout, props, external, and content tables. `options.props` is shallow-copied
---before `horizontal = true` is applied, so callers may reuse their input table safely.
---@param options? {name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function row(options)
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

  props.horizontal = true

  local layout = {
    type = ui.TYPE.Flex,
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

return row
