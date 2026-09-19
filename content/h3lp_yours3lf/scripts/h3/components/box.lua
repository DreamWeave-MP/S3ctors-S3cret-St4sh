---@omw-context menu|player

---H3 UI component primitive for passive MWUI box layouts.
---@module 'scripts.h3.components.box'

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local column = require 'scripts.h3.components.column'
local inset = require 'scripts.h3.components.inset'
local surface = require 'scripts.h3.ui.surface'

local Assert, Next, Type = assert, next, type

local UiContent, UtilVector4 = ui.content, util.vector4
local EmptyOptions = {}

local DefaultPadding = 4

---@param value? table
---@return table?
local function copyTable(value)
  if not value then return end
  local result = {}
  for key, item in Next, value do
    result[key] = item
  end
  return result
end

---Build an H3UI boxed container layout.
---Without a custom template the box is a framed surface: skin background, content slot, border
---slices, with `padding` between frame and content. A custom template replaces the frame while
---`padding` keeps its meaning: fixed geometry insets through `props.padding`, auto geometry
---wraps content in a padded inset. Allocates fresh layout, props, external, and content wrapper
---tables; callers own mounting and any later layout mutation.
---@param options? H3.BoxOptions
---@return openmw.ui.Layout
local function box(options)
  options = options or EmptyOptions

  local padding = options.padding or DefaultPadding
  Assert(Type(padding) == 'number' and padding >= 0, 'H3 box padding must be non-negative')

  local children = options.content or options.children or {}

  if options.template then
    local props = copyTable(options.props) or {}
    local content
    if padding > 0 then
      if props.size or props.relativeSize then
        if not props.padding then
          props.padding = UtilVector4(padding, padding, padding, padding)
        end
        content = UiContent(children)
      else
        content = UiContent {
          inset(column { children = children }, nil, padding),
        }
      end
    else
      content = UiContent(children)
    end
    return {
      template = options.template,
      name = options.name,
      props = props,
      external = copyTable(options.external),
      events = options.events,
      userData = options.userData,
      content = content,
    }
  end

  return surface.build {
    skin = appearance.chrome 'frame.thin',
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    name = options.name,
    padding = padding,
    props = copyTable(options.props),
    external = copyTable(options.external),
    events = options.events,
    userData = options.userData,
    content = children,
  }
end

return box
