---@omw-context menu|player

local async = require 'openmw.async'

local textInput = require 'scripts.s3.components.textInput'

---@class H3.NumberInputOptions
---@field value? number
---@field min? number
---@field max? number
---@field step? number
---@field integer? boolean
---@field onChange? fun(value: number)
---@field onCommit? fun(value: number)
---@field name? string
---@field props? table
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

    events[name] = async:callback(function(value, layout)
        handler(value, layout)
        return previous(value, layout)
    end)
end

---@param options? H3.NumberInputOptions
---@return openmw.ui.Layout
local function numberInput(options)
    options = options or {}

    local minimum = options.min
    local maximum = options.max
    local step = options.step
    local integer = options.integer == true
    local onChange = options.onChange
    local onCommit = options.onCommit
    local stepOrigin = minimum or 0

    assert(not minimum or not maximum or maximum >= minimum, 'NumberInput max is less than min')
    assert(not step or step > 0, 'NumberInput step must be positive')

    if integer then
        assert(
            not minimum or minimum == math.floor(minimum),
            'NumberInput integer min must be integral'
        )
        assert(
            not maximum or maximum == math.floor(maximum),
            'NumberInput integer max must be integral'
        )
        assert(not step or step == math.floor(step), 'NumberInput integer step must be integral')
    end

    local function normalize(nextValue)
        if integer then
            nextValue = nextValue < 0 and math.ceil(nextValue - 0.5) or math.floor(nextValue + 0.5)
        end
        if step then
            nextValue = stepOrigin + math.floor((nextValue - stepOrigin) / step + 0.5) * step
        end
        if minimum then nextValue = math.max(minimum, nextValue) end
        if maximum then nextValue = math.min(maximum, nextValue) end
        return nextValue
    end

    local value = normalize(options.value or 0)
    local events = {}
    if options.events then
        for name, callback in next, options.events do
            events[name] = callback
        end
    end

    local function updateText(input, layout) layout.props.text = input end

    local function commit(layout)
        local inputValue = tonumber(layout.props.text)
        local nextValue = inputValue and normalize(inputValue) or value
        local changed = nextValue ~= value

        value = nextValue
        layout.props.text = tostring(nextValue)

        if changed and onChange then onChange(nextValue) end
        if onCommit then onCommit(nextValue) end
    end

    addHandler(events, 'textChanged', updateText)
    addHandler(events, 'focusLoss', function(_, layout) commit(layout) end)

    return textInput {
        name = options.name,
        text = tostring(value),
        props = options.props,
        external = options.external,
        events = events,
        userData = options.userData,
        template = options.template,
    }
end

return numberInput
