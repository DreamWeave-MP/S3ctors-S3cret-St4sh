---@module 'scripts.s3.components.headBlock'
---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local textures = {
  topLeft = ui.texture { path = 'textures/menu_head_block_top_left_corner.dds' },
  top = ui.texture { path = 'textures/menu_head_block_top.dds' },
  topRight = ui.texture { path = 'textures/menu_head_block_top_right_corner.dds' },
  left = ui.texture { path = 'textures/menu_head_block_left.dds' },
  middle = ui.texture { path = 'textures/menu_head_block_middle.dds' },
  right = ui.texture { path = 'textures/menu_head_block_right.dds' },
  bottomLeft = ui.texture { path = 'textures/menu_head_block_bottom_left_corner.dds' },
  bottom = ui.texture { path = 'textures/menu_head_block_bottom.dds' },
  bottomRight = ui.texture { path = 'textures/menu_head_block_bottom_right_corner.dds' },
}

---@class H3.HeadBlockOptions
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field height? number

local function image(resource, props)
  return {
    type = ui.TYPE.Image,
    props = {
      resource = resource,
      anchor = props.anchor,
      relativePosition = props.relativePosition,
      position = props.position,
      size = props.size,
      relativeSize = props.relativeSize,
      tileH = props.tileH,
      tileV = props.tileV,
    },
  }
end

---@param options? H3.HeadBlockOptions
---@return openmw.ui.Layout
local function headBlock(options)
  options = options or {}
  local height = options.height or 20
  assert(height >= 4, 'HeadBlock height must be at least 4')

  local props = {}
  for key, value in pairs(options.props or {}) do
    props[key] = value
  end
  props.size = props.size or vector2(0, height)
  props.relativeSize = props.relativeSize or vector2(1, 0)

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = ui.content {
      image(textures.topLeft, {
        anchor = vector2(0, 0),
        relativePosition = vector2(0, 0),
        size = vector2(2, 2),
      }),
      image(textures.top, {
        anchor = vector2(0, 0),
        relativePosition = vector2(0, 0),
        position = vector2(2, 0),
        size = vector2(-4, 2),
        relativeSize = vector2(1, 0),
        tileH = true,
      }),
      image(textures.topRight, {
        anchor = vector2(1, 0),
        relativePosition = vector2(1, 0),
        position = vector2(-2, 0),
        size = vector2(2, 2),
      }),
      image(textures.left, {
        anchor = vector2(0, 0),
        relativePosition = vector2(0, 0),
        position = vector2(0, 2),
        size = vector2(2, height - 4),
      }),
      image(textures.middle, {
        anchor = vector2(0, 0),
        relativePosition = vector2(0, 0),
        position = vector2(2, 2),
        size = vector2(-4, height - 4),
        relativeSize = vector2(1, 0),
        tileH = true,
        tileV = true,
      }),
      image(textures.right, {
        anchor = vector2(1, 0),
        relativePosition = vector2(1, 0),
        position = vector2(-2, 2),
        size = vector2(2, height - 4),
      }),
      image(textures.bottomLeft, {
        anchor = vector2(0, 1),
        relativePosition = vector2(0, 1),
        position = vector2(0, -2),
        size = vector2(2, 2),
      }),
      image(textures.bottom, {
        anchor = vector2(0, 1),
        relativePosition = vector2(0, 1),
        position = vector2(2, -2),
        size = vector2(-4, 2),
        relativeSize = vector2(1, 0),
        tileH = true,
      }),
      image(textures.bottomRight, {
        anchor = vector2(1, 1),
        relativePosition = vector2(1, 1),
        position = vector2(-2, -2),
        size = vector2(2, 2),
      }),
    },
  }
end

return headBlock
