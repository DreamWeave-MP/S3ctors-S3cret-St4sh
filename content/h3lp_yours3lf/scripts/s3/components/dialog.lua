---@omw-context menu|player

local emptyOptions = {}
local emptyContent = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build a Window-style dialog layout.
---Allocates fresh layout, props, external, and content tables. No layer is set and no window is
---created; caller owns mounting, visibility, callbacks, and destruction.
---@param options? {title?: string, name?: string, props?: table, titleProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function dialog(options)
  options = options or emptyOptions

  local body = options.content or options.children
  body = body or emptyContent
  local content = {}
  if options.title ~= nil then
    local titleProps = {}
    if options.titleProps then
      for key, value in next, options.titleProps do
        titleProps[key] = value
      end
    end

    titleProps.text = options.title
    content[#content + 1] = { template = I.MWUI.templates.textHeader, props = titleProps }
    content[#content + 1] = { template = I.MWUI.templates.interval }
  end
  content[#content + 1] = {
    template = I.MWUI.templates.padding,
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = { horizontal = false },
        content = ui.content(body),
      },
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
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = { horizontal = false },
        content = ui.content(content),
      },
    },
  }
end

return dialog
