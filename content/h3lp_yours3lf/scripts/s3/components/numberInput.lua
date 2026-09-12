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

local function copyEvents(events)
  local copied = {}
  for key, event in pairs(events or {}) do
    copied[key] = event
  end
  return copied
end

local function addHandler(events, name, handler)
  local previous = events[name]
  events[name] = async:callback(function(value, layout)
    local handlerResult = handler(value, layout)
    if previous then return previous(value, layout) end
    return handlerResult
  end)
end

---@param options? H3.NumberInputOptions
---@return openmw.ui.Layout
local function numberInput(options)
  options = options or {}
  local minimum = options.min
  local maximum = options.max
  local step = options.step
  assert(not minimum or not maximum or maximum >= minimum, 'NumberInput max is less than min')
  assert(not step or step > 0, 'NumberInput step must be positive')
  if options.integer then
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

  local value = options.value or 0
  local events = copyEvents(options.events)

  local function normalize(nextValue)
    if options.integer then
      nextValue = nextValue < 0 and math.ceil(nextValue - 0.5) or math.floor(nextValue + 0.5)
    end
    if step then
      nextValue = (minimum or 0) + math.floor((nextValue - (minimum or 0)) / step + 0.5) * step
    end
    if minimum then nextValue = math.max(minimum, nextValue) end
    if maximum then nextValue = math.min(maximum, nextValue) end
    return nextValue
  end

  value = normalize(value)
  local editingText = tostring(value)
  local pendingValue = value

  local function updateText(input, layout)
    editingText = input
    pendingValue = tonumber(input)
    layout.props.text = input
  end

  local function commit(layout)
    local nextValue = pendingValue
    if nextValue then
      nextValue = normalize(nextValue)
    else
      nextValue = value
    end

    local changed = nextValue ~= value
    value = nextValue
    editingText = tostring(nextValue)
    pendingValue = nextValue
    layout.props.text = editingText

    if changed and options.onChange then options.onChange(nextValue) end
    if options.onCommit then options.onCommit(nextValue) end
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
