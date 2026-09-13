---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build a list item row layout.
---Allocates fresh row, props, external, and content tables. If `content`/`children` is omitted, a text
---label child is created. The caller owns events and mounted element lifetime.
---@param options? {label?: string, name?: string, props?: table, labelProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function listItem(options)
  options = options or emptyOptions

  local labelProps = {}
  if options.labelProps then
    for key, value in next, options.labelProps do
      labelProps[key] = value
    end
  end

  if options.label ~= nil then labelProps.text = options.label end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content
    or options.children
    or {
      {
        template = I.MWUI.templates.textNormal,
        props = labelProps,
      },
    }

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  return {
    template = options.template or I.MWUI.templates.padding,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = ui.content(children),
  }
end

return listItem
