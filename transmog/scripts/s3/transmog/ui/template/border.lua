local ui = require('openmw.ui')
local util = require('openmw.util')

local template = {
  type = ui.TYPE.Image,
  external = {
    grow = 0,
    stretch = 1,
  },
}

local function Border(horizontal, crossSize)
  if horizontal == nil or not crossSize then error('border template requires horizontal and crossSize') end
  if type(horizontal) ~= 'boolean' or type(crossSize) ~= 'number' then error('invalid types for Border arguments') end

  local newBorder = template

  local texturePath = horizontal
    and "textures\\menu_thick_border_bottom.dds"
    or "textures\\menu_thick_border_left.dds"

  newBorder.props = {
    resource = ui.texture { path = texturePath },
    size = horizontal and util.vector2(0, crossSize) or util.vector2(crossSize, 0),
    relativeSize = horizontal and util.vector2(1, 0) or util.vector2(0, 1),
  }

  return newBorder
end

return Border
