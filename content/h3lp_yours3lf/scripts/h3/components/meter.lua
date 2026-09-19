---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local appearance = require 'scripts.h3.ui.appearance'
local chrome = require 'scripts.h3.ui.chrome'

local Next = next

local ColorRGB, ColorRGBA, UiContent, UiTexture, UiType, UtilClamp, UtilVector2 =
  util.color.rgb, util.color.rgba, ui.content, ui.texture, ui.TYPE, util.clamp, util.vector2

local EmptyOptions = {}

local WhiteTexture = UiTexture { path = 'white' }

local FillColor, EmptyColor = ColorRGB(0.65, 0.52, 0.25), ColorRGBA(0, 0, 0, 0.35)

local DefaultSize, FullSize = UtilVector2(150, 18), UtilVector2(1, 1)

---Build a simple horizontal meter layout.
---Allocates fresh layout, props, external, and content tables. The fill is represented by a child Image
---with relative width; callers may supply engine-supported color/size props.
---@param options? H3.MeterOptions
---@return openmw.ui.Layout
local function meter(options)
  options = options or EmptyOptions

  local value = options.value or 0
  local maximum = options.max or 1
  local ratio = maximum > 0 and UtilClamp(value / maximum, 0, 1) or 0

  local fillProps = {}
  if options.fillProps then
    for key, propValue in Next, options.fillProps do
      fillProps[key] = propValue
    end
  end
  fillProps.color = fillProps.color or appearance.token 'color.accent' or FillColor
  fillProps.resource = fillProps.resource or WhiteTexture
  fillProps.relativeSize = fillProps.relativeSize or UtilVector2(ratio, 1)
  fillProps.ignorePointerEvents = true

  local emptyProps = {}
  if options.emptyProps then
    for key, propValue in Next, options.emptyProps do
      emptyProps[key] = propValue
    end
  end
  emptyProps.color = emptyProps.color or EmptyColor
  emptyProps.resource = emptyProps.resource or WhiteTexture
  emptyProps.relativeSize = emptyProps.relativeSize or UtilVector2(1 - ratio, 1)
  emptyProps.ignorePointerEvents = true

  local props = {}
  if options.props then
    for key, propValue in Next, options.props do
      props[key] = propValue
    end
  end
  props.size = props.size or DefaultSize
  if props.ignorePointerEvents == nil then props.ignorePointerEvents = not options.events end

  local external
  if options.external then
    external = {}
    for key, propValue in Next, options.external do
      external[key] = propValue
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
        type = UiType.Flex,
        props = {
          horizontal = true,
          autoSize = false,
          relativeSize = FullSize,
          ignorePointerEvents = true,
        },
        content = UiContent {
          { type = UiType.Image, props = fillProps },
          { type = UiType.Image, props = emptyProps },
        },
      },
    },
  }

  if options.template then
    result.template = options.template
    result.content = UiContent(result.content)
    return result
  end

  return chrome.frame {
    skin = appearance.chrome 'frame.thin',
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

return meter
