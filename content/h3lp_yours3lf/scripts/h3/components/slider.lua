---@omw-context menu|player

local util = require 'openmw.util'

local eventHandlers = require 'scripts.h3.components.eventHandlers'
local meter = require 'scripts.h3.components.meter'

local Assert, MathFloor, Next = assert, math.floor, next

local UtilClamp, UtilVector2 = util.clamp, util.vector2

local EmptyOptions = {}

local DefaultSize = UtilVector2(200, 18)

---@param options? H3.SliderOptions
---@return openmw.ui.Layout
local function slider(options)
  options = options or EmptyOptions

  local minimum = options.min or 0
  local maximum = options.max or 1
  local step = options.step
  local onChange = options.onChange
  local range = maximum - minimum

  Assert(range > 0, 'Slider requires max to be greater than min')
  Assert(not step or step > 0, 'Slider step must be positive')

  ---@param nextValue number
  ---@return number
  local function normalize(nextValue)
    nextValue = UtilClamp(nextValue, minimum, maximum)

    if step then
      nextValue = minimum + MathFloor((nextValue - minimum) / step + 0.5) * step
      nextValue = UtilClamp(nextValue, minimum, maximum)
    end

    return nextValue
  end

  local value = normalize(options.value or minimum)
  local dragging = false
  local fillLayout
  local emptyLayout

  ---@return nil
  local function updateMeter()
    local ratio = (value - minimum) / range
    fillLayout.props.relativeSize = UtilVector2(ratio, 1)
    emptyLayout.props.relativeSize = UtilVector2(1 - ratio, 1)
  end

  ---@param nextValue number
  ---@return nil
  local function updateValue(nextValue)
    nextValue = normalize(nextValue)
    if nextValue == value then return end

    value = nextValue
    updateMeter()

    if onChange then onChange(nextValue) end
  end

  local props = {}
  if options.props then
    for key, propValue in Next, options.props do
      props[key] = propValue
    end
  end
  props.size = props.size or DefaultSize

  local trackWidth = options.trackWidth or props.size.x
  Assert(trackWidth > 0, 'Slider trackWidth must be positive')
  if props.relativeSize and props.relativeSize.x ~= 0 then
    Assert(options.trackWidth, 'Slider trackWidth is required when relativeSize.x is non-zero')
  end

  local inverseTrackWidth = 1 / trackWidth
  local events = {}
  if options.events then
    for name, callback in Next, options.events do
      events[name] = callback
    end
  end

  ---@param event openmw.ui.MouseEvent
  ---@return number
  local function valueAt(event)
    local ratio = UtilClamp(event.offset.x * inverseTrackWidth, 0, 1)
    return minimum + range * ratio
  end

  eventHandlers.add(events, 'mousePress',
    ---@param event openmw.ui.MouseEvent?
    ---@return boolean?
    function(event)
    if not event or event.button ~= 1 then return end

    dragging = true
    updateValue(valueAt(event))
    return true
  end)

  eventHandlers.add(events, 'mouseMove',
    ---@param event openmw.ui.MouseEvent?
    ---@return boolean?
    function(event)
    if not dragging or not event then return end

    if event.button ~= 1 then
      dragging = false
      return
    end

    updateValue(valueAt(event))
    return true
  end)

  eventHandlers.add(events, 'mouseRelease',
    ---@param event openmw.ui.MouseEvent?
    ---@return boolean?
    function(event)
    if not event or event.button ~= 1 or not dragging then return end

    dragging = false
    return true
  end)

  eventHandlers.add(events, 'focusLoss',
    ---@return boolean?
    function()
    if not dragging then return end

    dragging = false
    return true
  end)

  local layout = meter {
    name = options.name,
    value = value - minimum,
    max = range,
    props = props,
    fillProps = options.fillProps,
    emptyProps = options.emptyProps,
    external = options.external,
    events = events,
    userData = options.userData,
    template = options.template,
  }

  local track = layout.content[1]
  fillLayout = track.content[1]
  emptyLayout = track.content[2]

  return layout
end

return slider
