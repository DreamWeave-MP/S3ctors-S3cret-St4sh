---@omw-context menu|player

local emptyOptions = {}

local ui = require 'openmw.ui'

---Build a Text layout.
---Allocates fresh layout, props, and external tables. The returned layout is passive and must
---be mounted and updated by its owner if its text changes later.
---@param options? {text?: string, name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function text(options)
  options = options or emptyOptions
  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  if options.text ~= nil then props.text = options.text end
  if props.ignorePointerEvents == nil then props.ignorePointerEvents = options.events == nil end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  return {
    type = ui.TYPE.Text,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
end

return text
