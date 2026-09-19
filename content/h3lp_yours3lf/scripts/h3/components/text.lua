---@omw-context menu|player

local ui = require 'openmw.ui'

local appearance = require 'scripts.h3.ui.appearance'

local Next, ToString, Type = next, tostring, type

local UiType = ui.TYPE

local EmptyOptions = {}

---Build a Text layout with the current H3UI appearance's normal text color and size by default.
---Allocates fresh layout, props, and external tables. The returned layout is passive and must
---be mounted and updated by its owner if its text changes later.
---@param options? H3.TextOptions|string|number
---@return openmw.ui.Layout
local function text(options)
  if Type(options) == 'string' or Type(options) == 'number' then
    options = { text = ToString(options) }
  end
  options = options or EmptyOptions
  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  if not options.template then
    if not props.textColor then props.textColor = appearance.token 'color.text' end
    if not props.textSize then props.textSize = appearance.token 'textSize.normal' end
  end

  if options.text then props.text = options.text end
  if props.ignorePointerEvents == nil then props.ignorePointerEvents = not options.events end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end

  return {
    type = UiType.Text,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
end

return text
