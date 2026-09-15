--- Builds a Morrowind-style pinned-state button layout.
---@module 'scripts.s3.components.pinButton'
---@omw-context menu|player

local emptyOptions = {}

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'

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
    tintable = paths.tintable,
    topLeft = chrome.texture(paths.topLeft),
    top = chrome.texture(paths.top),
    topRight = chrome.texture(paths.topRight),
    left = chrome.texture(paths.left),
    center = chrome.texture(paths.center),
    right = chrome.texture(paths.right),
    bottomLeft = chrome.texture(paths.bottomLeft),
    bottom = chrome.texture(paths.bottom),
    bottomRight = chrome.texture(paths.bottomRight),
  }
end

---@class H3.PinButtonOptions
---@field pinned? boolean
---@field onToggle? fun(pinned: boolean)
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any

local function image(name, resource, position, size, color)
  local props = {
    resource = resource,
    ignorePointerEvents = true,
    position = position,
    size = size,
  }
  if color then props.color = color end
  return {
    name = name,
    type = ui.TYPE.Image,
    props = props,
  }
end

local function setSkin(layout, skin, color)
  for name, resource in next, skin do
    if name ~= 'tintable' and name ~= 'thickness' then
      layout.content[name].props.resource = resource
      layout.content[name].props.color = skin.tintable and color or nil
    end
  end
end

---@param options? H3.PinButtonOptions
---@return openmw.ui.Layout
local function pinButton(options)
  options = options or emptyOptions

  local pinned = options.pinned == true
  local onToggle = options.onToggle
  local upSkin = appearance.chrome 'pin.up'
  local downSkin = appearance.chrome 'pin.down'
  local textures = {
    up = textureSet(upSkin),
    down = textureSet(downSkin),
  }
  local skin = pinned and downSkin or upSkin
  local resources = pinned and textures.down or textures.up
  local tint = skin.tintable and appearance.token 'color.chromeBorder' or nil
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
    setSkin(layout, pinned and textures.down or textures.up, tint)

    if onToggle then onToggle(pinned) end

    if previousClick then return previousClick(event, layout) end
  end)

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = options.external,
    events = events,
    userData = options.userData,
    content = ui.content {
      image('center', resources.center, centerPosition, centerSize, tint),
      image('topLeft', resources.topLeft, topLeftPosition, cornerSize, tint),
      image('top', resources.top, topPosition, horizontalSize, tint),
      image('topRight', resources.topRight, topRightPosition, cornerSize, tint),
      image('left', resources.left, leftPosition, verticalSize, tint),
      image('right', resources.right, rightPosition, verticalSize, tint),
      image('bottomLeft', resources.bottomLeft, bottomLeftPosition, cornerSize, tint),
      image('bottom', resources.bottom, bottomPosition, horizontalSize, tint),
      image('bottomRight', resources.bottomRight, bottomRightPosition, cornerSize, tint),
    },
  }
end

return pinButton
