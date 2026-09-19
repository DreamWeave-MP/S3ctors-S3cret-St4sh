---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local chrome = require 'scripts.h3.ui.chrome'

local Next = next

local UiContent, UiType, UtilVector2 = ui.content, ui.TYPE, util.vector2

local EmptyOptions = {}

---@param textProps table
---@return openmw.ui.Layout
local function paragraph(textProps)
  local props = {
    autoSize = true,
    readOnly = true,
    multiline = true,
    wordWrap = true,
    size = UtilVector2(100, 0),
  }
  for key, value in Next, textProps do
    props[key] = value
  end
  props.ignorePointerEvents = true

  return {
    type = UiType.TextEdit,
    props = props,
  }
end

---Build a boxed tooltip layout.
---Allocates fresh layout, props, external, and content tables. This primitive does not position, show,
---hide, create, or destroy anything; caller owns tooltip lifecycle.
---@param options? H3.TooltipOptions
---@return openmw.ui.Layout
local function tooltip(options)
  options = options or EmptyOptions

  local textProps = {}
  if options.textProps then
    for key, value in Next, options.textProps do
      textProps[key] = value
    end
  end
  if not textProps.textColor then textProps.textColor = appearance.token 'color.text' end
  if not textProps.textSize then textProps.textSize = appearance.token 'textSize.normal' end

  if options.text then textProps.text = options.text end
  textProps.ignorePointerEvents = true

  local children = options.content or options.children
  if not children then children = { paragraph(textProps) } end

  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end

  local layout = {
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = UiContent(children),
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
