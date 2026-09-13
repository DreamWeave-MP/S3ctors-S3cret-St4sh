---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build a TextEdit layout using `I.MWUI.templates.textEditLine` by default.
---Allocates fresh layout, props, and external tables. Event callbacks, if supplied, are passed
---through unchanged; callers must wrap OpenMW UI callbacks with `async:callback`.
---@param options? {text?: string, name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function textInput(options)
  options = options or emptyOptions

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  if options.text ~= nil then props.text = options.text end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  return {
    type = ui.TYPE.TextEdit,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template or I.MWUI.templates.textEditLine,
  }
end

return textInput
