---@omw-context menu|player

local emptyOptions = {}

---H3 UI component primitive for passive MWUI box layouts.
---@module 'scripts.s3.components.box'

local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local column = require 'scripts.s3.components.column'
local inset = require 'scripts.s3.components.inset'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local DefaultPadding = 4

---Build an H3UI boxed container layout.
---Allocates fresh layout, props, external, and content wrapper tables; callers own mounting and any
---later layout mutation.
---@param options? {name?: string, padding?: number, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function box(options)
  options = options or emptyOptions

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  local padding = options.padding or DefaultPadding
  assert(type(padding) == 'number' and padding >= 0, 'H3 box padding must be non-negative')

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  local layout = {
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
  }
  local children = options.content or options.children
  children = children or {}

  if padding > 0 then
    if props.size ~= nil or props.relativeSize ~= nil then
      if props.padding == nil then
        props.padding = util.vector4(padding, padding, padding, padding)
      end
      layout.content = ui.content(children)
    else
      layout.content = ui.content {
        inset(column { children = children }, nil, padding),
      }
    end
  else
    layout.content = ui.content(children)
  end

  if options.template then
    layout.template = options.template
    return layout
  end

  return chrome.box {
    skin = appearance.chrome 'frame.thin',
    name = layout.name,
    props = layout.props,
    external = layout.external,
    events = layout.events,
    userData = layout.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = children,
  }
end

return box
