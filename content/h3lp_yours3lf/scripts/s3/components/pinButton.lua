--- Builds a Morrowind-style pinned-state button layout.
---@module 'scripts.s3.components.pinButton'
---@omw-context menu|player

local emptyOptions = {}

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2

local pinSize = UtilVector2(19, 19)
local centerPosition = UtilVector2(2, 2)
local centerSize = UtilVector2(15, 15)
local topLeftPosition = UtilVector2(0, 0)
local cornerSize = UtilVector2(2, 2)
local topPosition = UtilVector2(2, 0)
local horizontalSize = UtilVector2(15, 2)
local topRightPosition = UtilVector2(17, 0)
local leftPosition = UtilVector2(0, 2)
local verticalSize = UtilVector2(2, 15)
local rightPosition = UtilVector2(17, 2)
local bottomLeftPosition = UtilVector2(0, 17)
local bottomPosition = UtilVector2(2, 17)
local bottomRightPosition = UtilVector2(17, 17)

local function textureSet(paths)
  return {
    topLeft = ui.texture { path = paths.topLeft },
    top = ui.texture { path = paths.top },
    topRight = ui.texture { path = paths.topRight },
    left = ui.texture { path = paths.left },
    center = ui.texture { path = paths.center },
    right = ui.texture { path = paths.right },
    bottomLeft = ui.texture { path = paths.bottomLeft },
    bottom = ui.texture { path = paths.bottom },
    bottomRight = ui.texture { path = paths.bottomRight },
  }
end

local textures = {
  up = textureSet {
    topLeft = 'textures/menu_rightbuttonup_top_left.dds',
    top = 'textures/menu_rightbuttonup_top.dds',
    topRight = 'textures/menu_rightbuttonup_top_right.dds',
    left = 'textures/menu_rightbuttonup_left.dds',
    center = 'textures/menu_rightbuttonup_center.dds',
    right = 'textures/menu_rightbuttonup_right.dds',
    bottomLeft = 'textures/menu_rightbuttonup_bottom_left.dds',
    bottom = 'textures/menu_rightbuttonup_bottom.dds',
    bottomRight = 'textures/menu_rightbuttonup_bottom_right.dds',
  },
  down = textureSet {
    topLeft = 'textures/menu_rightbuttondown_top_left.dds',
    top = 'textures/menu_rightbuttondown_top.dds',
    topRight = 'textures/menu_rightbuttondown_top_right.dds',
    left = 'textures/menu_rightbuttondown_left.dds',
    center = 'textures/menu_rightbuttondown_center.dds',
    right = 'textures/menu_rightbuttondown_right.dds',
    bottomLeft = 'textures/menu_rightbuttondown_bottom_left.dds',
    bottom = 'textures/menu_rightbuttondown_bottom.dds',
    bottomRight = 'textures/menu_rightbuttondown_bottom_right.dds',
  },
}

---@class H3.PinButtonOptions
---@field pinned? boolean
---@field onToggle? fun(pinned: boolean)
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any

local function image(name, resource, position, size)
  return {
    name = name,
    type = ui.TYPE.Image,
    props = {
      resource = resource,
      ignorePointerEvents = true,
      position = position,
      size = size,
    },
  }
end

local function setSkin(layout, skin)
  for name, resource in next, skin do
    layout.content[name].props.resource = resource
  end
end

---@param options? H3.PinButtonOptions
---@return openmw.ui.Layout
local function pinButton(options)
  options = options or emptyOptions

  local pinned = options.pinned == true
  local onToggle = options.onToggle
  local props = {}

  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  if props.size then
    assert(props.size.x == pinSize.x and props.size.y == pinSize.y, 'PinButton size must be 19x19')
  end

  props.size = props.size or pinSize
  props.propagateEvents = false

  local events = {}
  if options.events then
    for key, event in next, options.events do
      events[key] = event
    end
  end

  local previousClick = events.mouseClick
  events.mouseClick = async:callback(function(event, layout)
    pinned = not pinned
    setSkin(layout, pinned and textures.down or textures.up)

    if onToggle then onToggle(pinned) end

    if previousClick then return previousClick(event, layout) end
  end)

  local skin = pinned and textures.down or textures.up

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = options.external,
    events = events,
    userData = options.userData,
    content = ui.content {
      image('center', skin.center, centerPosition, centerSize),
      image('topLeft', skin.topLeft, topLeftPosition, cornerSize),
      image('top', skin.top, topPosition, horizontalSize),
      image('topRight', skin.topRight, topRightPosition, cornerSize),
      image('left', skin.left, leftPosition, verticalSize),
      image('right', skin.right, rightPosition, verticalSize),
      image('bottomLeft', skin.bottomLeft, bottomLeftPosition, cornerSize),
      image('bottom', skin.bottom, bottomPosition, horizontalSize),
      image('bottomRight', skin.bottomRight, bottomRightPosition, cornerSize),
    },
  }
end

return pinButton
