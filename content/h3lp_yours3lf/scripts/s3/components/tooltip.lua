---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build a boxed tooltip layout.
---Allocates fresh layout, props, external, and content tables. This primitive does not position, show,
---hide, create, or destroy anything; caller owns tooltip lifecycle.
---@param options? {text?: string, name?: string, props?: table, textProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function tooltip(options)
  options = options or emptyOptions

  local textProps = {}
  if options.textProps then
    for key, value in next, options.textProps do
      textProps[key] = value
    end
  end

  if options.text ~= nil then textProps.text = options.text end
  textProps.ignorePointerEvents = true

  local children = options.content or options.children
  if not children then
    children = {
      {
        template = I.MWUI.templates.textParagraph,
        props = textProps,
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
    template = options.template or I.MWUI.templates.boxTransparent,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = ui.content {
      {
        template = I.MWUI.templates.padding,
        content = ui.content(children),
      },
    },
  }
end

return tooltip
