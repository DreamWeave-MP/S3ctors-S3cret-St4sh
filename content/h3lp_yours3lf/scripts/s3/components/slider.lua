---@omw-context menu|player

local async = require 'openmw.async'
local util = require 'openmw.util'

local meter = require 'scripts.s3.components.meter'

local clamp = util.clamp
local vector2 = util.vector2

---@class H3.SliderOptions
---@field value? number
---@field min? number
---@field max? number
---@field step? number
---@field trackWidth? number Width used to map pointer offsets when the track is relatively sized.
---@field onChange? fun(value: number)
---@field name? string
---@field props? table
---@field fillProps? table
---@field emptyProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

local function copyEvents(events)
  local copied = {}
  for key, event in pairs(events or {}) do
    copied[key] = event
  end
  return copied
end

local function addHandler(events, name, handler)
  local previous = events[name]
  events[name] = async:callback(function(event, layout)
    local handlerResult = handler(event, layout)
    if previous then return previous(event, layout) end
    return handlerResult
  end)
end

---@param options? H3.SliderOptions
---@return openmw.ui.Layout
local function slider(options)
  options = options or {}
  local minimum = options.min or 0
  local maximum = options.max or 1
  local step = options.step
  assert(maximum > minimum, 'Slider requires max to be greater than min')
  assert(not step or step > 0, 'Slider step must be positive')

  local dragging = false

  local function normalize(nextValue)
    nextValue = clamp(nextValue, minimum, maximum)
    if step then
      nextValue =
        clamp(minimum + math.floor((nextValue - minimum) / step + 0.5) * step, minimum, maximum)
    end
    return nextValue
  end

  local value = normalize(options.value or minimum)

  local function updateMeter(layout)
    local ratio = (value - minimum) / (maximum - minimum)
    local track = layout.content[1]
    local fill = track.content[1]
    local empty = track.content[2]
    fill.props.relativeSize = vector2(ratio, 1)
    empty.props.relativeSize = vector2(1 - ratio, 1)
  end

  local function updateValue(nextValue, layout)
    nextValue = normalize(nextValue)
    if nextValue == value then return end
    value = nextValue
    updateMeter(layout)
    if options.onChange then options.onChange(nextValue) end
  end

  local props = {}
  for key, propValue in pairs(options.props or {}) do
    props[key] = propValue
  end
  props.size = props.size or vector2(200, 18)
  local trackWidth = options.trackWidth or props.size.x
  assert(trackWidth > 0, 'Slider trackWidth must be positive')
  if props.relativeSize and props.relativeSize.x ~= 0 then
    assert(options.trackWidth, 'Slider trackWidth is required when relativeSize.x is non-zero')
  end

  local events = copyEvents(options.events)

  local function valueAt(event)
    return minimum + (maximum - minimum) * clamp(event.offset.x / trackWidth, 0, 1)
  end

  addHandler(events, 'mousePress', function(event, layout)
    if not event or event.button ~= 1 then return end
    dragging = true
    updateValue(valueAt(event), layout)
    return true
  end)

  addHandler(events, 'mouseMove', function(event, layout)
    if not dragging or not event then return end
    if event.button ~= 1 then
      dragging = false
      return
    end
    updateValue(valueAt(event), layout)
    return true
  end)

  addHandler(events, 'mouseRelease', function(event)
    if not event or event.button ~= 1 or not dragging then return end
    dragging = false
    return true
  end)

  addHandler(events, 'focusLoss', function()
    if not dragging then return end
    dragging = false
    return true
  end)

  return meter {
    name = options.name,
    value = value - minimum,
    max = maximum - minimum,
    props = props,
    fillProps = options.fillProps,
    emptyProps = options.emptyProps,
    external = options.external,
    events = events,
    userData = options.userData,
    template = options.template,
  }
end

return slider
