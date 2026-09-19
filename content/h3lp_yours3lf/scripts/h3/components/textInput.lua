---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local eventHandlers = require 'scripts.h3.components.eventHandlers'

local Next = next

local UiAlignment, UiType, UtilVector2 = ui.ALIGNMENT, ui.TYPE, util.vector2

local EmptyOptions = {}

local DefaultSize = UtilVector2(150, 0)

---Build an H3UI-owned single-line TextEdit layout by default.
---Allocates fresh layout, props, and external tables. `onChange` is composed with any caller-supplied
---`events.textChanged` callback so normal application code does not need raw event plumbing.
---@param options? H3.TextInputOptions
---@return openmw.ui.Layout
local function textInput(options)
  options = options or EmptyOptions

  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  if not props.textColor then props.textColor = appearance.token 'color.text' end
  if not props.textSize then props.textSize = appearance.token 'textSize.normal' end

  if not options.template then
    if not props.size then props.size = DefaultSize end
    if props.autoSize == nil then props.autoSize = true end
    if not props.multiline then props.multiline = false end
    if not props.textAlignV then props.textAlignV = UiAlignment.Center end
  end

  if options.text then props.text = options.text end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end

  local events = {}
  if options.events then
    for key, value in Next, options.events do
      events[key] = value
    end
  end

  if options.onChange then
    eventHandlers.add(events, 'textChanged',
      ---@param value string
      ---@param layout openmw.ui.Layout
      ---@return boolean?
      function(value, layout)
      layout.props.text = value
      return options.onChange(value, layout)
    end, true)
  end
  if options.onCommit then
    eventHandlers.add(
      events,
      'focusLoss',
      ---@param _? openmw.ui.MouseEvent
      ---@param layout openmw.ui.Layout
      ---@return boolean?
      function(_, layout) return options.onCommit(layout.props.text or '', layout) end
    )
  end

  return {
    type = UiType.TextEdit,
    name = options.name,
    props = props,
    external = external,
    events = Next(events) and events,
    userData = options.userData,
    template = options.template,
  }
end

return textInput
