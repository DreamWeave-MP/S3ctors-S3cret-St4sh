---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local image = require 'scripts.h3.components.image'

local Assert, Next, Type = assert, next, type

local UiTexture, UtilVector2 = ui.texture, util.vector2

local FullHeight, FullWidth = UtilVector2(0, 1), UtilVector2(1, 0)

local WhiteTexture = UiTexture { path = 'white' }

---@param options? H3.DividerOptions
---@return openmw.ui.Layout
local function divider(options)
  options = options or {}
  local orientation = options.orientation or 'horizontal'
  local thickness = options.thickness or 1
  local length = options.length
  Assert(
    orientation == 'horizontal' or orientation == 'vertical',
    'H3 divider orientation must be horizontal or vertical'
  )
  Assert(Type(thickness) == 'number' and thickness > 0, 'H3 divider thickness must be positive')
  if length then
    Assert(Type(length) == 'number' and length >= 0, 'H3 divider length must be non-negative')
  end

  local props = {
    color = options.color or appearance.token 'color.chromeBorder',
  }
  if orientation == 'horizontal' then
    props.size = UtilVector2(length or 0, thickness)
    if not length then props.relativeSize = FullWidth end
  else
    props.size = UtilVector2(thickness, length or 0)
    if not length then props.relativeSize = FullHeight end
  end
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  return image {
    name = options.name,
    resource = WhiteTexture,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
  }
end

return divider
