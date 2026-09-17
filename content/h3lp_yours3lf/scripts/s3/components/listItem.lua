---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local activationEvents = require 'scripts.s3.components.activationEvents'
local appearance = require 'scripts.s3.ui.appearance'
local row = require 'scripts.s3.components.row'
local text = require 'scripts.s3.components.text'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local relativeWidth = util.vector2(1, 0)

---@class H3.ListItemOptions
---@field label? string
---@field secondary? string|number Right-aligned secondary value for list rows.
---@field name? string
---@field props? table
---@field labelProps? table
---@field secondaryProps? table
---@field external? table
---@field events? table
---@field onActivate? fun(event: table, layout: openmw.ui.Layout): any
---@field userData? any
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field template? openmw.ui.Template

---@param options? H3.ListItemOptions
---@return openmw.ui.Layout
local function listItem(options)
  options = options or emptyOptions

  local labelProps = {
    textColor = appearance.token 'color.text',
    textSize = appearance.token 'textSize.normal',
  }
  for key, value in next, options.labelProps or {} do
    labelProps[key] = value
  end
  if labelProps.ignorePointerEvents == nil then labelProps.ignorePointerEvents = true end

  local children = options.content or options.children
  if not children then
    local label = text {
      text = options.label,
      props = labelProps,
      external = options.secondary ~= nil and { grow = 1 } or nil,
    }
    children = { label }

    if options.secondary ~= nil then
      local secondaryProps = {
        textColor = appearance.token 'color.text',
        textSize = appearance.token 'textSize.normal',
        ignorePointerEvents = true,
      }
      for key, value in next, options.secondaryProps or {} do
        secondaryProps[key] = value
      end

      children = {
        row {
          props = { relativeSize = relativeWidth },
          children[1],
          text { text = tostring(options.secondary), props = secondaryProps },
        },
      }
    end
  end

  local props = {}
  for key, value in next, options.props or {} do
    props[key] = value
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
    events = activationEvents(options.events, options.onActivate),
    userData = options.userData,
    content = ui.content(children),
  }
end

return listItem
