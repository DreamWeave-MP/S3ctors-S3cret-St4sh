---@module 'scripts.s3.components.headBlock'
---@omw-context menu|player

local emptyOptions = {}

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2

local zero = UtilVector2(0, 0)
local rightTop = UtilVector2(1, 0)
local leftBottom = UtilVector2(0, 1)
local rightBottom = UtilVector2(1, 1)
local relativeWidth = rightTop
local cornerSize = UtilVector2(2, 2)
local topPosition = UtilVector2(2, 0)
local topSize = UtilVector2(-4, 2)
local topRightPosition = UtilVector2(-2, 0)
local leftPosition = UtilVector2(0, 2)
local middlePosition = UtilVector2(2, 2)
local rightPosition = UtilVector2(-2, 2)
local bottomLeftPosition = UtilVector2(0, -2)
local bottomPosition = UtilVector2(2, -2)
local bottomRightPosition = UtilVector2(-2, -2)

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

local function image(resource, anchor, position, size, relativeSize, tileH, tileV)
  return {
    type = ui.TYPE.Image,
    props = {
      resource = resource,
      ignorePointerEvents = true,
      anchor = anchor,
      relativePosition = anchor,
      position = position,
      size = size,
      relativeSize = relativeSize,
      tileH = tileH,
      tileV = tileV,
    },
  }
end

---@param options? H3.HeadBlockOptions
---@return openmw.ui.Layout
local function headBlock(options)
  options = options or emptyOptions

  local height = options.height or 20
  assert(height >= 4, 'HeadBlock height must be at least 4')

  local middleHeight = height - 4
  local sideSize = UtilVector2(2, middleHeight)
  local middleSize = UtilVector2(-4, middleHeight)
  local props = {}

  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  props.size = props.size or UtilVector2(0, height)
  props.relativeSize = props.relativeSize or relativeWidth

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = ui.content {
      image(textures.topLeft, zero, nil, cornerSize),
      image(textures.top, zero, topPosition, topSize, relativeWidth, true),
      image(textures.topRight, rightTop, topRightPosition, cornerSize),
      image(textures.left, zero, leftPosition, sideSize),
      image(textures.middle, zero, middlePosition, middleSize, relativeWidth, true, true),
      image(textures.right, rightTop, rightPosition, sideSize),
      image(textures.bottomLeft, leftBottom, bottomLeftPosition, cornerSize),
      image(textures.bottom, leftBottom, bottomPosition, topSize, relativeWidth, true),
      image(textures.bottomRight, rightBottom, bottomRightPosition, cornerSize),
    },
  }
end

return headBlock
