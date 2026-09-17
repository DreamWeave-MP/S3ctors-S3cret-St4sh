---@omw-context menu|player

local appearance = require 'scripts.s3.ui.appearance'
local image = require 'scripts.s3.components.image'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local fullHeight = UtilVector2(0, 1)
local fullWidth = UtilVector2(1, 0)
local whiteTexture = ui.texture { path = 'white' }

---@class H3.DividerOptions
---@field orientation? 'horizontal'|'vertical' Defaults to `horizontal`.
---@field thickness? number Defaults to `1`.
---@field length? number Fixed length. Omit to stretch across the parent on the divider axis.
---@field color? openmw.util.Color Defaults to the active H3UI chrome-border color.
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any

---@param options? H3.DividerOptions
---@return openmw.ui.Layout
local function divider(options)
  options = options or {}
  local orientation = options.orientation or 'horizontal'
  local thickness = options.thickness or 1
  local length = options.length
  assert(
    orientation == 'horizontal' or orientation == 'vertical',
    'H3 divider orientation must be horizontal or vertical'
  )
  assert(type(thickness) == 'number' and thickness > 0, 'H3 divider thickness must be positive')
  if length ~= nil then
    assert(type(length) == 'number' and length >= 0, 'H3 divider length must be non-negative')
  end

  local props = {
    color = options.color or appearance.token 'color.chromeBorder',
  }
  if orientation == 'horizontal' then
    props.size = UtilVector2(length or 0, thickness)
    if length == nil then props.relativeSize = fullWidth end
  else
    props.size = UtilVector2(thickness, length or 0)
    if length == nil then props.relativeSize = fullHeight end
  end
  for key, value in next, options.props or {} do
    props[key] = value
  end

  return image {
    name = options.name,
    resource = whiteTexture,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
  }
end

return divider
