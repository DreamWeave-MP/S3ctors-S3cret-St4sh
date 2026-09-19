---@omw-context menu|player

local emptyOptions = {}
local emptyContent = {}

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local inset = require 'scripts.s3.components.inset'
local spacer = require 'scripts.s3.components.spacer'
local surface = require 'scripts.s3.ui.surface'
local text = require 'scripts.s3.components.text'

local fullSize = util.vector2(1, 1)

---Build a book-like framed content layout.
---Allocates fresh layout, props, external, and content tables. It is a passive layout primitive; caller
---owns mounting and later updates.
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
    if titleProps.textSize == nil then titleProps.textSize = appearance.token 'textSize.header' end
    if titleProps.textColor == nil then titleProps.textColor = appearance.token 'color.header' end

    titleProps.text = options.title
    titleProps.ignorePointerEvents = true
    content[#content + 1] = text { text = options.title, props = titleProps }
    content[#content + 1] = spacer(2, 2)
  end

  content[#content + 1] = {
    template = inset.template,
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

  local backgroundProps = {}
  if options.backgroundProps then
    for key, value in next, options.backgroundProps do
      backgroundProps[key] = value
    end
  end
  if backgroundProps.resource == nil then backgroundProps.resource = appearance.token 'texture.white' end
  if backgroundProps.color == nil then backgroundProps.color = appearance.token 'color.background' end
  if backgroundProps.alpha == nil then backgroundProps.alpha = appearance.token 'transparency.menu' end
  if backgroundProps.ignorePointerEvents == nil then backgroundProps.ignorePointerEvents = true end
  if backgroundProps.relativeSize == nil then backgroundProps.relativeSize = fullSize end

  if options.template then
    local legacyContent = ui.content {
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
    }

    return {
      template = options.template,
      name = options.name,
      props = props,
      external = external,
      events = options.events,
      userData = options.userData,
      content = legacyContent,
    }
  end

  return surface.build {
    skin = appearance.chrome 'frame.thin',
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    backgroundProps = backgroundProps,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
    content = {
      {
        type = ui.TYPE.Flex,
        props = { horizontal = false },
        content = ui.content(content),
      },
    },
  }
end

return bookFrame
