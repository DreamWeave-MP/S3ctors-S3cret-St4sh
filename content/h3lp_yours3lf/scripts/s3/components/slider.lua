---@omw-context menu|player

local async = require 'openmw.async'
local util = require 'openmw.util'

local meter = require 'scripts.s3.components.meter'

local clamp = util.clamp
local vector2 = util.vector2
local floor = math.floor

local defaultSize = vector2(200, 18)

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

local function addHandler(events, name, handler)
    local previous = events[name]

    if not previous then
        events[name] = async:callback(handler)
        return
    end

    events[name] = async:callback(function(event, layout)
        handler(event, layout)
        return previous(event, layout)
    end)
end

---@param options? H3.SliderOptions
---@return openmw.ui.Layout
local function slider(options)
    options = options or {}

    local minimum = options.min or 0
    local maximum = options.max or 1
    local step = options.step
    local onChange = options.onChange
    local range = maximum - minimum

    assert(range > 0, 'Slider requires max to be greater than min')
    assert(not step or step > 0, 'Slider step must be positive')

    local function normalize(nextValue)
        nextValue = clamp(nextValue, minimum, maximum)
        if step then
            nextValue = minimum + floor((nextValue - minimum) / step + 0.5) * step
            nextValue = clamp(nextValue, minimum, maximum)
        end
        return nextValue
    end

    local value = normalize(options.value or minimum)
    local dragging = false
    local fillLayout
    local emptyLayout

    local function updateMeter()
        local ratio = (value - minimum) / range
        fillLayout.props.relativeSize = vector2(ratio, 1)
        emptyLayout.props.relativeSize = vector2(1 - ratio, 1)
    end

    local function updateValue(nextValue)
        nextValue = normalize(nextValue)
        if nextValue == value then return end

        value = nextValue
        updateMeter()

        if onChange then onChange(nextValue) end
    end

    local props = {}
    if options.props then
        for key, propValue in next, options.props do
            props[key] = propValue
        end
    end
    props.size = props.size or defaultSize

    local trackWidth = options.trackWidth or props.size.x
    assert(trackWidth > 0, 'Slider trackWidth must be positive')
    if props.relativeSize and props.relativeSize.x ~= 0 then
        assert(options.trackWidth, 'Slider trackWidth is required when relativeSize.x is non-zero')
    end

    local inverseTrackWidth = 1 / trackWidth
    local events = {}
    if options.events then
        for name, callback in next, options.events do
            events[name] = callback
        end
    end

    local function valueAt(event)
        local ratio = clamp(event.offset.x * inverseTrackWidth, 0, 1)
        return minimum + range * ratio
    end

    addHandler(events, 'mousePress', function(event)
        if not event or event.button ~= 1 then return end

        dragging = true
        updateValue(valueAt(event))
        return true
    end)

    addHandler(events, 'mouseMove', function(event)
        if not dragging or not event then return end
        if event.button ~= 1 then
            dragging = false
            return
        end

        updateValue(valueAt(event))
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
