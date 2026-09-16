---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local image = require 'scripts.s3.components.image'
local ui = require 'openmw.ui'

---Build an MWUI button with an icon and optional label.
---Allocates fresh layout, props, external, and content tables. A texture options table passed as
---`resource` is converted by the image component; this primitive does not query game state or own any Element.
---@param options? {resource?: openmw.ui.TextureResource|openmw.ui.TextureResourceOptions, label?: string, name?: string, props?: table, iconProps?: table, labelProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
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
    image { resource = options.resource, props = iconProps },
  }
  if options.label ~= nil then
    local labelProps = {
      textColor = appearance.token 'color.text',
      textSize = appearance.token 'textSize.normal',
    }
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

  local result = {
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = {
      {
        template = I.MWUI.templates.padding,
        props = { ignorePointerEvents = false },
        content = ui.content {
          {
            template = I.MWUI.templates.padding,
            props = { ignorePointerEvents = true },
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
          },
        },
      },
    },
  }

  if options.template then
    result.template = options.template
    result.content = ui.content(result.content)
    return result
  end

  return chrome.box {
    skin = appearance.chrome 'frame.button',
    name = result.name,
    props = result.props,
    external = result.external,
    events = result.events,
    userData = result.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = result.content,
  }
end

return iconButton
