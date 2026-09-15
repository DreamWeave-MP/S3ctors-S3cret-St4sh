---@omw-context menu|player

local emptyOptions = {}
local emptyContent = {}

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local fullSize = util.vector2(1, 1)
local black = util.color.rgb(0, 0, 0)
local whiteTexture = ui.texture { path = 'white' }

---Build a book-like framed content layout.
---Allocates fresh layout, props, external, and content tables and uses MWUI borders read-only. It is a
---passive layout primitive; caller owns mounting and later updates.
---@param options? {title?: string, name?: string, props?: table, titleProps?: table, backgroundProps?: table, external?: table, events?: table, userData?: any, content?: openmw.ui.Content|openmw.ui.LayoutOrElement[], children?: openmw.ui.Content|openmw.ui.LayoutOrElement[], template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function bookFrame(options)
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
    titleProps.ignorePointerEvents = true
    content[#content + 1] = { template = I.MWUI.templates.textHeader, props = titleProps }
    content[#content + 1] = {
      template = I.MWUI.templates.interval,
      props = { ignorePointerEvents = true },
    }
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

  local backgroundProps = {
    resource = whiteTexture,
    color = black,
    alpha = 1,
    ignorePointerEvents = true,
    relativeSize = fullSize,
  }
  if options.backgroundProps then
    for key, value in next, options.backgroundProps do
      backgroundProps[key] = value
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
        type = ui.TYPE.Container,
        content = ui.content {
          { type = ui.TYPE.Image, props = backgroundProps },
          {
            type = ui.TYPE.Flex,
            props = { horizontal = false },
            content = ui.content(content),
          },
        },
      },
    },
  }
end

return bookFrame
