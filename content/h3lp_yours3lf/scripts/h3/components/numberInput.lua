---@omw-context menu|player

local eventHandlers = require 'scripts.h3.components.eventHandlers'
local textInput = require 'scripts.h3.components.textInput'

local Assert, MathCeil, MathFloor, MathMax, MathMin, Next, ToNumber, ToString =
  assert, math.ceil, math.floor, math.max, math.min, next, tonumber, tostring

local EmptyOptions = {}

---@param options? H3.NumberInputOptions
---@return openmw.ui.Layout
local function numberInput(options)
  options = options or EmptyOptions

  local minimum = options.min
  local maximum = options.max
  local step = options.step
  local integer = options.integer == true
  local onChange = options.onChange
  local onCommit = options.onCommit
  local stepOrigin = minimum or 0

  Assert(not minimum or not maximum or maximum >= minimum, 'NumberInput max is less than min')
  Assert(not step or step > 0, 'NumberInput step must be positive')

  if integer then
    Assert(not minimum or minimum == MathFloor(minimum), 'NumberInput integer min must be integral')
    Assert(not maximum or maximum == MathFloor(maximum), 'NumberInput integer max must be integral')
    Assert(not step or step == MathFloor(step), 'NumberInput integer step must be integral')
  end

  ---@param nextValue number
  ---@return number
  local function normalize(nextValue)
    if integer then
      nextValue = nextValue < 0 and MathCeil(nextValue - 0.5) or MathFloor(nextValue + 0.5)
    end

    if step then
      nextValue = stepOrigin + MathFloor((nextValue - stepOrigin) / step + 0.5) * step
    end

    if minimum then nextValue = MathMax(minimum, nextValue) end
    if maximum then nextValue = MathMin(maximum, nextValue) end

    return nextValue
  end

  local value = normalize(options.value or 0)
  local events = {}

  if options.events then
    for name, callback in Next, options.events do
      events[name] = callback
    end
  end

  ---@param input string
  ---@param layout openmw.ui.Layout
  ---@return nil
  local function updateText(input, layout) layout.props.text = input end

  ---@param layout openmw.ui.Layout
  ---@return nil
  local function commit(layout)
    local inputValue = ToNumber(layout.props.text)
    local nextValue = inputValue and normalize(inputValue) or value
    local changed = nextValue ~= value

    value = nextValue
    layout.props.text = ToString(nextValue)

    if changed and onChange then onChange(nextValue) end
    if onCommit then onCommit(nextValue) end
  end

  eventHandlers.add(events, 'textChanged', updateText)
  eventHandlers.add(events, 'focusLoss',
    ---@param _? openmw.ui.MouseEvent
    ---@param layout openmw.ui.Layout
    ---@return nil
    function(_, layout) commit(layout) end)

  return textInput {
    name = options.name,
    text = ToString(value),
    props = options.props,
    external = options.external,
    events = events,
    userData = options.userData,
    template = options.template,
  }
end

return numberInput
