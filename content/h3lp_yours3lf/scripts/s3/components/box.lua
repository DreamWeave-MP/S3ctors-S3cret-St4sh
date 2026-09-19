---@omw-context menu|player

local emptyOptions = {}

---H3 UI component primitive for passive MWUI box layouts.
---@module 'scripts.s3.components.box'

local appearance = require 'scripts.s3.ui.appearance'
local column = require 'scripts.s3.components.column'
local inset = require 'scripts.s3.components.inset'
local surface = require 'scripts.s3.ui.surface'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local DefaultPadding = 4

local function copyTable(value)
  if value == nil then return nil end
  local result = {}
  for key, item in next, value do
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
---@param options? {name?: string, padding?: number, props?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function box(options)
  options = options or emptyOptions

  local padding = options.padding or DefaultPadding
  assert(type(padding) == 'number' and padding >= 0, 'H3 box padding must be non-negative')

  local children = options.content or options.children or {}

  if options.template then
    local props = copyTable(options.props) or {}
    local content
    if padding > 0 then
      if props.size ~= nil or props.relativeSize ~= nil then
        if props.padding == nil then
          props.padding = util.vector4(padding, padding, padding, padding)
        end
        content = ui.content(children)
      else
        content = ui.content {
          inset(column { children = children }, nil, padding),
        }
      end
    else
      content = ui.content(children)
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
