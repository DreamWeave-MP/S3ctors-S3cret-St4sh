---@omw-context menu|player

local emptyOptions = {}
local emptyContent = {}

local ui = require 'openmw.ui'

---Build a vertical list Flex layout.
---Allocates fresh layout, props, external, and content tables. Items are passed through as
---child layouts; callers own item identity, events, and later Element updates.
---@param options? {items?: openmw.ui.LayoutOrElement[], name?: string, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function list(options)
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

  props.horizontal = false

  local children = options.content or options.children or options.items
  children = children or emptyContent

  return {
    type = ui.TYPE.Flex,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
    content = ui.content(children),
  }
end

return list
