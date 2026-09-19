---@omw-context menu|player
---@module 'scripts.h3.ui.surface'

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local chrome = require 'scripts.h3.ui.chrome'

local Assert, Next, SetMetatable, TableConcat, ToString, Type =
  assert, next, setmetatable, table.concat, tostring, type

local UiContent, UiType, UtilVector2 = ui.content, ui.TYPE, util.vector2
local FullSize = UtilVector2(1, 1)

local WeakKeys = { __mode = 'k' }
local TemplateCache = SetMetatable({}, WeakKeys)

---@param skin H3UI.ChromeFrame
---@param thickness number
---@param tint? openmw.util.Color
---@param alpha? number
---@param backgroundProps? table
---@param padding number
---@param boxType openmw.ui.WidgetType
---@return openmw.ui.Template
local function surfaceTemplate(skin, thickness, tint, alpha, backgroundProps, padding, boxType)
  local skinCache = TemplateCache[skin]
  if not skinCache then
    skinCache = {}
    TemplateCache[skin] = skinCache
  end

  local key = TableConcat({
    ToString(boxType),
    padding,
    chrome.cacheKey(alpha),
    chrome.cacheKey(backgroundProps),
    chrome.cacheKey(tint),
  }, ':')

  local cached = skinCache[key]
  if cached then return cached end

  local content = chrome.backgroundChildren(skin, tint, alpha, backgroundProps, true)

  local marginVector = UtilVector2(padding, padding)

  local padded = boxType ~= UiType.Widget and padding > 0
  if padded then content[#content + 1] = { props = { size = marginVector } } end

  content[#content + 1] = {
    name = 'h3ui_content',
    external = { slot = true },
    props = {
      position = marginVector,
      size = UtilVector2(-2 * padding, -2 * padding),
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

  local result = { type = boxType, content = UiContent(content) }
  skinCache[key] = result
  return result
end

---Build a framed surface using immutable cached chrome templates.
---Content renders beneath the border. Selected chrome is a full-geometry sibling overlay so
---selection never requires mutable frame slices; only its per-instance visibility is retained.
---Fixed surfaces use Widget geometry, while auto surfaces size from their normal content layer.
---@param options H3UI.SurfaceOptions
---@return openmw.ui.Layout
local function surface(options)
  local skin = options.skin
  Assert(Type(skin) == 'table', 'H3 UI surface requires a skin')

  local thickness = skin.thickness
  Assert(Type(thickness) == 'number' and thickness > 0, 'H3 UI surface skin requires thickness')

  local padding = options.padding or 0
  Assert(Type(padding) == 'number' and padding >= 0, 'H3 UI surface padding must be non-negative')

  local props = options.props or {}

  local fixed = props.size or props.relativeSize
  local boxType = fixed and UiType.Widget or UiType.Container

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
      content = UiContent(options.content or {}),
    }
  end

  Assert(Type(selected) == 'table', 'H3 UI surface selected must be a table')

  local sourceProps = selected.props or {}

  local overlayProps = {}
  for key, value in Next, sourceProps do
    overlayProps[key] = value
  end

  if overlayProps.visible == nil then overlayProps.visible = false end
  if overlayProps.relativeSize == nil then overlayProps.relativeSize = FullSize end
  if overlayProps.ignorePointerEvents == nil then overlayProps.ignorePointerEvents = true end

  local content = options.content or {}
  Assert(Type(content) == 'table', 'H3 UI surface selected layer requires table content')

  local selectedSkin = selected.skin or skin
  local selectedThickness = selectedSkin.thickness
  local selectedAlpha = selected.alpha

  Assert(
    Type(selectedThickness) == 'number' and selectedThickness > 0,
    'H3 UI surface selected skin requires thickness'
  )

  local overlay = {
    content = UiContent {},
    props = overlayProps,
    template = surfaceTemplate(
      selectedSkin,
      selectedThickness,
      selected.tint,
      selectedAlpha or options.alpha,
      selected.backgroundProps,
      padding,
      UiType.Widget
    ),
    type = UiType.Widget,
  }

  if fixed then
    return {
      content = UiContent {
        {
          type = UiType.Widget,
          props = { relativeSize = FullSize },
          template = template,
          content = UiContent(content),
        },
        overlay,
      },
      events = options.events,
      external = options.external,
      name = options.name,
      props = props,
      type = UiType.Widget,
      userData = options.userData,
    }
  end

  return {
    name = options.name,
    props = props,
    events = options.events,
    external = options.external,
    content = UiContent {
      { type = UiType.Container, template = template, content = UiContent(content) },
      overlay,
    },
    type = UiType.Container,
    userData = options.userData,
  }
end

return {
  build = surface,
}
