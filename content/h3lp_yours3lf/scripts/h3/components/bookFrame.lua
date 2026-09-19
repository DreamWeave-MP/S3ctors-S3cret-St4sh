---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local inset = require 'scripts.h3.components.inset'
local spacer = require 'scripts.h3.components.spacer'
local surface = require 'scripts.h3.ui.surface'
local text = require 'scripts.h3.components.text'

local Next = next

local UiContent, UiType, UtilVector2 = ui.content, ui.TYPE, util.vector2

local EmptyOptions, EmptyContent = {}, {}

local FullSize = UtilVector2(1, 1)

---Build a book-like framed content layout.
---Allocates fresh layout, props, external, and content tables. It is a passive layout primitive; caller
---owns mounting and later updates.
---@param options? H3.BookFrameOptions
---@return openmw.ui.Layout
local function bookFrame(options)
  options = options or EmptyOptions

  local body = options.content or options.children
  body = body or EmptyContent
  local content = {}

  if options.title then
    local titleProps = {}

    if options.titleProps then
      for key, value in Next, options.titleProps do
        titleProps[key] = value
      end
    end

    if not titleProps.textSize then titleProps.textSize = appearance.token 'textSize.header' end
    if not titleProps.textColor then titleProps.textColor = appearance.token 'color.header' end

    titleProps.text = options.title
    titleProps.ignorePointerEvents = true
    content[#content + 1] = text { text = options.title, props = titleProps }
    content[#content + 1] = spacer(2, 2)
  end

  content[#content + 1] = {
    template = inset.template,
    content = UiContent {
      {
        type = UiType.Flex,
        props = { horizontal = false },
        content = UiContent(body),
      },
    },
  }

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

  local backgroundProps = {}

  if options.backgroundProps then
    for key, value in Next, options.backgroundProps do
      backgroundProps[key] = value
    end
  end

  if not backgroundProps.resource then
    backgroundProps.resource = appearance.token 'texture.white'
  end

  if not backgroundProps.color then backgroundProps.color = appearance.token 'color.background' end
  if not backgroundProps.alpha then backgroundProps.alpha = appearance.token 'transparency.menu' end
  if backgroundProps.ignorePointerEvents == nil then backgroundProps.ignorePointerEvents = true end
  if not backgroundProps.relativeSize then backgroundProps.relativeSize = FullSize end

  if options.template then
    local templateContent = UiContent {
      {
        type = UiType.Container,
        content = UiContent {
          {
            type = UiType.Image,
            props = backgroundProps,
          },

          {
            type = UiType.Flex,
            props = { horizontal = false },
            content = UiContent(content),
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
      content = templateContent,
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
        type = UiType.Flex,
        props = { horizontal = false },
        content = UiContent(content),
      },
    },
  }
end

return bookFrame
