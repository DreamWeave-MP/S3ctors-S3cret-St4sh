--- Builds a Morrowind-style pinned-state button layout.
---@module scripts.s3.components.pinButton
---@omw-context menu|player

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2
local pinSize = vector2(19, 19)

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
      position = position,
      size = size,
    },
  }
end

local function setSkin(layout, skin)
  for name, resource in pairs(skin) do
    layout.content[name].props.resource = resource
  end
end

---@param options? H3.PinButtonOptions
---@return openmw.ui.Layout
local function pinButton(options)
  options = options or {}
  local pinned = options.pinned == true
  local props = {}
  for key, value in pairs(options.props or {}) do
    props[key] = value
  end
  if props.size then
    assert(props.size.x == pinSize.x and props.size.y == pinSize.y, 'PinButton size must be 19x19')
  end
  props.size = props.size or pinSize
  props.propagateEvents = false

  local events = {}
  for key, event in pairs(options.events or {}) do
    events[key] = event
  end
  local previousPress = events.mousePress
  events.mousePress = async:callback(function(event, layout)
    if previousPress then return previousPress(event, layout) end
  end)
  local previousClick = events.mouseClick
  events.mouseClick = async:callback(function(event, layout)
    pinned = not pinned
    setSkin(layout, textures[pinned and 'down' or 'up'])
    if options.onToggle then options.onToggle(pinned) end
    if previousClick then return previousClick(event, layout) end
  end)
  local skin = textures[pinned and 'down' or 'up']

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = options.external,
    events = events,
    userData = options.userData,
    content = ui.content {
      image('center', skin.center, vector2(2, 2), vector2(15, 15)),
      image('topLeft', skin.topLeft, vector2(0, 0), vector2(2, 2)),
      image('top', skin.top, vector2(2, 0), vector2(15, 2)),
      image('topRight', skin.topRight, vector2(17, 0), vector2(2, 2)),
      image('left', skin.left, vector2(0, 2), vector2(2, 15)),
      image('right', skin.right, vector2(17, 2), vector2(2, 15)),
      image('bottomLeft', skin.bottomLeft, vector2(0, 17), vector2(2, 2)),
      image('bottom', skin.bottom, vector2(2, 17), vector2(15, 2)),
      image('bottomRight', skin.bottomRight, vector2(17, 17), vector2(2, 2)),
    },
  }
end

return pinButton
