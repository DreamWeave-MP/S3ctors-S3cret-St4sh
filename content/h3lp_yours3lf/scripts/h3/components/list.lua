---@omw-context menu|player

local ui = require 'openmw.ui'

local Next = next

local UiContent, UiType = ui.content, ui.TYPE

local EmptyOptions, EmptyContent = {}, {}
---Build a vertical list Flex layout.
---Allocates fresh layout, props, external, and content tables. Items are passed through as
---child layouts; callers own item identity, events, and later Element updates.
---@param options? H3.ListOptions
---@return openmw.ui.Layout
local function list(options)
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

  props.horizontal = false

  local children = options.content or options.children or options.items
  children = children or EmptyContent

  return {
    type = UiType.Flex,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
    content = UiContent(children),
  }
end

return list
