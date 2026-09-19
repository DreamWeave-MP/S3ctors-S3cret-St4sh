---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local activationEvents = require 'scripts.h3.components.activationEvents'
local appearance = require 'scripts.h3.ui.appearance'
local inset = require 'scripts.h3.components.inset'
local row = require 'scripts.h3.components.row'
local text = require 'scripts.h3.components.text'

local Next, ToString = next, tostring

local UiContent, UtilVector2 = ui.content, util.vector2

local EmptyOptions = {}

local RelativeWidth = UtilVector2(1, 0)

---@param options? H3.ListItemOptions
---@return openmw.ui.Layout
local function listItem(options)
  options = options or EmptyOptions

  local labelProps = {}
  if options.labelProps then
    for key, value in Next, options.labelProps do
      labelProps[key] = value
    end
  end
  if not labelProps.textColor then labelProps.textColor = appearance.token 'color.text' end
  if not labelProps.textSize then labelProps.textSize = appearance.token 'textSize.normal' end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content or options.children
  if not children then
    local label = text {
      text = options.label,
      props = labelProps,
      external = options.secondary and { grow = 1 } or nil,
    }
    children = { label }

    if options.secondary then
      local secondaryProps = {}
      if options.secondaryProps then
        for key, value in Next, options.secondaryProps do
          secondaryProps[key] = value
        end
      end
      if not secondaryProps.textColor then
        secondaryProps.textColor = appearance.token 'color.text'
      end
      if not secondaryProps.textSize then
        secondaryProps.textSize = appearance.token 'textSize.normal'
      end
      if secondaryProps.ignorePointerEvents == nil then
        secondaryProps.ignorePointerEvents = true
      end

      children = {
        row {
          props = { relativeSize = RelativeWidth },
          children[1],
          text { text = ToString(options.secondary), props = secondaryProps },
        },
      }
    end
  end

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
  elseif options.secondary then
    external = { stretch = 1 }
  end

  return {
    template = options.template or inset.template,
    name = options.name,
    props = props,
    external = external,
    events = activationEvents(options.events, options.onActivate),
    userData = options.userData,
    content = UiContent(children),
  }
end

return listItem
