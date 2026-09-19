---@omw-context menu|player
---@module 'scripts.s3.ui.surface'

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local chrome = require 'scripts.s3.ui.chrome'

local UtilVector2 = util.vector2
local FullSize = UtilVector2(1, 1)

local templateCache = setmetatable({}, { __mode = 'k' })

local function surfaceTemplate(skin, thickness, tint, alpha, backgroundProps, padding, boxType)
  local skinCache = templateCache[skin]
  if not skinCache then
    skinCache = {}
    templateCache[skin] = skinCache
  end

  local key = table.concat({
    tostring(boxType),
    padding,
    chrome.cacheKey(alpha),
    chrome.cacheKey(backgroundProps),
    chrome.cacheKey(tint),
  }, ':')
  local cached = skinCache[key]
  if cached then return cached end

  local content = chrome.backgroundChildren(skin, tint, alpha, backgroundProps, true)

  local margin = padding
  local marginVector = UtilVector2(margin, margin)
  local padded = boxType ~= ui.TYPE.Widget and padding > 0
  if padded then content[#content + 1] = { props = { size = marginVector } } end
  content[#content + 1] = {
    name = 'h3ui_content',
    external = { slot = true },
    props = {
      position = marginVector,
      size = UtilVector2(-2 * margin, -2 * margin),
      relativeSize = FullSize,
    },
  }
  if padded then
    content[#content + 1] = {
      props = { position = marginVector, relativePosition = FullSize, size = marginVector },
    }
  end

  local borderSlices = chrome.frameChildren(skin, thickness, tint, alpha, nil, false)
  for index = 1, #borderSlices do
    content[#content + 1] = borderSlices[index]
  end

  local result = { type = boxType, content = ui.content(content) }
  skinCache[key] = result
  return result
end

---@class H3UI.SurfaceSelectedOptions
---@field props? table Retained control props for the selected chrome layer. Surface copies
---the table, defaults `visible` to false, `relativeSize` to full size, and
---`ignorePointerEvents` to true, then retains the copy as the layer props.
---@field skin? table Alternate chrome skin for the selected layer. Defaults to the surface skin.
---@field tint? openmw.util.Color
---@field alpha? number Defaults to the surface alpha.
---@field backgroundProps? table

---@class H3UI.SurfaceOptions
---@field skin table Chrome frame skin. Must define a positive `thickness`.
---@field props? table Fixed `size` or `relativeSize` makes a fixed surface; omit both for auto sizing.
---@field padding? number Empty space between the frame and the content on all four sides.
---@field tint? openmw.util.Color
---@field alpha? number
---@field backgroundProps? table
---@field selected? H3UI.SurfaceSelectedOptions State chrome layer sharing the wrapper
---geometry and rendered after the normal border. Its visibility is the retained
---`selectedChrome` semantic target.
---@field name? string
---@field external? table
---@field events? table
---@field userData? any
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]

---Build a framed surface layout.
---The template draws the skin background and center, then the content slot, then the border
---slices, so caller content can never render over the chrome. The slot margin is exactly
---`padding`: frame thickness never enters content geometry, and the border overlays the surface
---edge. Fixed surfaces carry only the positioned slot; auto surfaces add padding helpers around
---it when `padding` is nonzero. Props and external tables are retained, never mutated or copied;
---callers promising fresh tables copy first. Templates are shared per visual key and must be
---treated as read-only.
---With `selected`, the result is a wrapper carrying the caller identity (name, props,
---external, events, userData) with two full-geometry chrome layers: the normal surface holding
---the caller content, then the selected surface holding nothing. State chrome is a sibling of
---the normal surface, never content, so it covers the same outer rectangle and renders after
---the normal border. Both layer templates stay cached and immutable; only the per-instance
---visibility props are retained and mutated. The overlay ignores pointer events and stays out
---of auto sizing: fixed wrappers use free-positioned Widgets, auto wrappers size to the normal
---layer while the overlay fills the resolved wrapper.
---@param options H3UI.SurfaceOptions
---@return openmw.ui.Layout
local function surface(options)
  local skin = options.skin
  assert(type(skin) == 'table', 'H3 UI surface requires a skin')
  local thickness = skin.thickness
  assert(type(thickness) == 'number' and thickness > 0, 'H3 UI surface skin requires thickness')

  local padding = options.padding or 0
  assert(type(padding) == 'number' and padding >= 0, 'H3 UI surface padding must be non-negative')

  local props = options.props or {}

  local fixed = props.size ~= nil or props.relativeSize ~= nil
  local boxType = fixed and ui.TYPE.Widget or ui.TYPE.Container

  local template = surfaceTemplate(
    skin,
    thickness,
    options.tint,
    options.alpha,
    options.backgroundProps,
    padding,
    boxType
  )

  local selected = options.selected
  if selected == nil then
    return {
      template = template,
      name = options.name,
      props = props,
      external = options.external,
      events = options.events,
      userData = options.userData,
      content = ui.content(options.content or {}),
    }
  end

  assert(type(selected) == 'table', 'H3 UI surface selected must be a table')

  local sourceProps = selected.props or {}
  local overlayProps = {}
  for key, value in next, sourceProps do
    overlayProps[key] = value
  end
  if overlayProps.visible == nil then overlayProps.visible = false end
  if overlayProps.relativeSize == nil then overlayProps.relativeSize = FullSize end
  if overlayProps.ignorePointerEvents == nil then overlayProps.ignorePointerEvents = true end

  local content = options.content or {}
  assert(type(content) == 'table', 'H3 UI surface selected layer requires table content')

  local selectedSkin = selected.skin or skin
  local selectedThickness = selectedSkin.thickness
  assert(
    type(selectedThickness) == 'number' and selectedThickness > 0,
    'H3 UI surface selected skin requires thickness'
  )
  local overlay = {
    type = ui.TYPE.Widget,
    props = overlayProps,
    template = surfaceTemplate(
      selectedSkin,
      selectedThickness,
      selected.tint,
      selected.alpha ~= nil and selected.alpha or options.alpha,
      selected.backgroundProps,
      padding,
      ui.TYPE.Widget
    ),
    content = ui.content {},
  }

  if fixed then
    return {
      type = ui.TYPE.Widget,
      name = options.name,
      props = props,
      external = options.external,
      events = options.events,
      userData = options.userData,
      content = ui.content {
        {
          type = ui.TYPE.Widget,
          props = { relativeSize = FullSize },
          template = template,
          content = ui.content(content),
        },
        overlay,
      },
    }
  end

  return {
    type = ui.TYPE.Container,
    name = options.name,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = ui.content {
      { type = ui.TYPE.Container, template = template, content = ui.content(content) },
      overlay,
    },
  }
end

return {
  build = surface,
}
