---@omw-context menu|player
---@module 'scripts.h3.components.pinButton'

local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local chrome = require 'scripts.h3.ui.chrome'
local eventHandlers = require 'scripts.h3.components.eventHandlers'

local Assert, Next = assert, next

local UtilVector2 = util.vector2

local EmptyOptions = {}

local PinSize = UtilVector2(20, 20)

---@param options? H3.PinButtonOptions
---@return openmw.ui.Layout
local function pinButton(options)
  options = options or EmptyOptions

  local pinned = options.pinned == true
  local onToggle = options.onToggle
  local upSkin = appearance.chrome 'pin.up'
  local downSkin = appearance.chrome 'pin.down'
  local skin = pinned and downSkin or upSkin
  local tint = appearance.token 'color.chromeBorder'
  local alpha = appearance.token 'transparency.chrome'
  local props = {}

  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  if props.size then
    Assert(props.size.x == PinSize.x and props.size.y == PinSize.y, 'PinButton size must be 20x20')
  end

  props.size = props.size or PinSize
  props.propagateEvents = false

  local events = {}
  if options.events then
    for key, event in Next, options.events do
      events[key] = event
    end
  end

  eventHandlers.add(events, 'mouseClick',
    ---@param _ openmw.ui.MouseEvent
    ---@param layout openmw.ui.Layout
    ---@return boolean
    function(_, layout)
    pinned = not pinned
    chrome.applyCompatibleSkin(layout, pinned and downSkin or upSkin, tint, alpha)
    if onToggle then onToggle(pinned) end
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
