---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'

---Build an MWUI button with an icon and optional label.
---Allocates fresh layout, props, external, and content tables. Pass a prebuilt texture `resource`; this
---primitive does not register textures or own element lifetime.
---@param options? {resource?: openmw.ui.TextureResource, label?: string, name?: string, props?: table, iconProps?: table, labelProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function iconButton(options)
  options = options or emptyOptions

  local iconProps = {}
  if options.iconProps then
    for key, value in next, options.iconProps do
      iconProps[key] = value
    end
  end

  if options.resource ~= nil then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true

  local rowContent = {
    {
      type = ui.TYPE.Image,
      props = iconProps,
    },
  }
  if options.label ~= nil then
    local labelProps = {}
    if options.labelProps then
      for key, value in next, options.labelProps do
        labelProps[key] = value
      end
    end

    labelProps.text = options.label
    labelProps.ignorePointerEvents = true
    rowContent[#rowContent + 1] = {
      template = I.MWUI.templates.interval,
      props = { ignorePointerEvents = true },
    }
    rowContent[#rowContent + 1] = {
      template = I.MWUI.templates.textNormal,
      props = labelProps,
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
    content = ui.content {
      {
        template = I.MWUI.templates.padding,
        props = { ignorePointerEvents = true },
        content = ui.content {
          {
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            content = ui.content(rowContent),
          },
        },
      },
    },
  }
end

return iconButton
