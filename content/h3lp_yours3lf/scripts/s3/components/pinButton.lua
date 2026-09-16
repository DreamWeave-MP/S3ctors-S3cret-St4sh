--- Builds a Morrowind-style pinned-state button layout.
---@module 'scripts.s3.components.pinButton'
---@omw-context menu|player

local emptyOptions = {}

local async = require 'openmw.async'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'

local UtilVector2 = util.vector2

local pinSize = UtilVector2(19, 19)
---@class H3.PinButtonOptions
---@field pinned? boolean
---@field onToggle? fun(pinned: boolean)
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any

local function setSkin(layout, skin, color, alpha)
  chrome.applyCompatibleSkin(layout, skin, color, alpha)
end

---@param options? H3.PinButtonOptions
---@return openmw.ui.Layout
local function pinButton(options)
  options = options or emptyOptions

  local pinned = options.pinned == true
  local onToggle = options.onToggle
  local upSkin = appearance.chrome 'pin.up'
  local downSkin = appearance.chrome 'pin.down'
  local skin = pinned and downSkin or upSkin
  local tint = appearance.token 'color.chromeBorder'
  local alpha = appearance.token 'transparency.chrome'
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
    setSkin(layout, pinned and downSkin or upSkin, tint, alpha)

    if onToggle then onToggle(pinned) end

    if previousClick then return previousClick(event, layout) end
  end)

  return chrome.frame {
    skin = skin,
    name = options.name,
    props = props,
    external = options.external,
    events = events,
    userData = options.userData,
    tint = tint,
    alpha = alpha,
  }
end

return pinButton
