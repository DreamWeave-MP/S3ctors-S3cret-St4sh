---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local fullSize = util.vector2(1, 1)

---Build a simple MWUI text button layout.
---Allocates fresh layout, props, external, padding, text, and content tables. The button is only a
---layout; caller-owned event callbacks must be async-wrapped before use.
---@param options? {label?: string, name?: string, props?: table, labelProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function button(options)
  options = options or emptyOptions

  local labelProps = {
    textColor = appearance.token 'color.text',
    textSize = appearance.token 'textSize.normal',
  }
  if options.labelProps then
    for key, value in next, options.labelProps do
      labelProps[key] = value
    end
  end

  if options.label ~= nil then labelProps.text = options.label end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content or options.children
  local fixedSize = options.props and options.props.size ~= nil
  if not children then
    if fixedSize then
      labelProps.autoSize = false
      labelProps.relativeSize = fullSize
      labelProps.textAlignH = ui.ALIGNMENT.Center
      labelProps.textAlignV = ui.ALIGNMENT.Center
      children = {
        {
          template = I.MWUI.templates.textNormal,
          props = labelProps,
        },
      }
    else
      local label = {
        template = I.MWUI.templates.textNormal,
        props = labelProps,
      }
      local paddedLabel = {
        template = I.MWUI.templates.padding,
        props = { ignorePointerEvents = true },
        content = ui.content { label },
      }
      local spacedLabel = {
        template = I.MWUI.templates.padding,
        props = { ignorePointerEvents = true },
        content = ui.content { paddedLabel },
      }
      children = {
        {
          template = I.MWUI.templates.padding,
          props = { ignorePointerEvents = false },
          content = ui.content { spacedLabel },
        },
      }
    end
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

  local result = {
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = ui.content(children),
  }

  if options.template then
    result.template = options.template
    return result
  end

  local frame = fixedSize and chrome.frame or chrome.box
  return frame {
    skin = appearance.chrome 'frame.button',
    name = result.name,
    props = result.props,
    external = result.external,
    events = result.events,
    userData = result.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = children,
  }
end

return button
