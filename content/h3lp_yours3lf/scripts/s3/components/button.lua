---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build a simple MWUI text button layout.
---Allocates fresh layout, props, external, padding, text, and content tables. The button is only a
---layout; caller-owned event callbacks must be async-wrapped before use.
---@param options? {label?: string, name?: string, props?: table, labelProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function button(options)
  options = options or emptyOptions

  local labelProps = {}
  if options.labelProps then
    for key, value in next, options.labelProps do
      labelProps[key] = value
    end
  end

  if options.label ~= nil then labelProps.text = options.label end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content or options.children
  if not children then
    children = {
      {
        template = I.MWUI.templates.padding,
        props = { ignorePointerEvents = true },
        content = ui.content {
          {
            template = I.MWUI.templates.textNormal,
            props = labelProps,
          },
        },
      },
    }
  end

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
    template = options.template or I.MWUI.templates.box,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = ui.content(children),
  }
end

return button
