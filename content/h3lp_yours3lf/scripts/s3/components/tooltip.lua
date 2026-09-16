---@omw-context menu|player

local emptyOptions = {}

local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2

local function paragraph(textProps)
  local props = {
    autoSize = true,
    readOnly = true,
    multiline = true,
    wordWrap = true,
    size = UtilVector2(100, 0),
  }
  for key, value in next, textProps do
    props[key] = value
  end
  props.ignorePointerEvents = true

  return {
    type = ui.TYPE.TextEdit,
    props = props,
  }
end

---Build a boxed tooltip layout.
---Allocates fresh layout, props, external, and content tables. This primitive does not position, show,
---hide, create, or destroy anything; caller owns tooltip lifecycle.
---@param options? {text?: string, name?: string, props?: table, textProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function tooltip(options)
  options = options or emptyOptions

  local textProps = {}
  textProps.textColor = appearance.token 'color.text'
  textProps.textSize = appearance.token 'textSize.normal'
  if options.textProps then
    for key, value in next, options.textProps do
      textProps[key] = value
    end
  end

  if options.text ~= nil then textProps.text = options.text end
  textProps.ignorePointerEvents = true

  local children = options.content or options.children
  if not children then children = { paragraph(textProps) } end

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

  local layout = {
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = ui.content(children),
  }

  if options.template then
    layout.template = options.template
    return layout
  end

  return chrome.nineSlice {
    source = appearance.chrome 'frame.thin',
    inset = 2,
    name = layout.name,
    props = layout.props,
    external = layout.external,
    events = layout.events,
    userData = layout.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = children,
  }
end

return tooltip
