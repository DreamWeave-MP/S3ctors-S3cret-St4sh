---@omw-context menu|player
---@module 'scripts.s3.ui.chrome'

local ui
local textureCache = {}
local templateCache = {}
local copy
local UtilVector2 = require('openmw.util').vector2
local zero = UtilVector2(0, 0)
local rightTop = UtilVector2(1, 0)
local leftBottom = UtilVector2(0, 1)
local rightBottom = UtilVector2(1, 1)
local fullSize = UtilVector2(1, 1)
local relativeWidth = UtilVector2(1, 0)
local relativeHeight = UtilVector2(0, 1)

local function uiModule()
  ui = ui or require 'openmw.ui'
  return ui
end

local function frame(prefix, thickness, center, cornerSuffix)
  cornerSuffix = cornerSuffix == nil and '_corner' or cornerSuffix
  local result = {
    thickness = thickness,
    topLeft = 'textures/h3ui/' .. prefix .. '_top_left' .. cornerSuffix .. '.dds',
    top = 'textures/h3ui/' .. prefix .. '_top.dds',
    topRight = 'textures/h3ui/' .. prefix .. '_top_right' .. cornerSuffix .. '.dds',
    left = 'textures/h3ui/' .. prefix .. '_left.dds',
    right = 'textures/h3ui/' .. prefix .. '_right.dds',
    bottomLeft = 'textures/h3ui/' .. prefix .. '_bottom_left' .. cornerSuffix .. '.dds',
    bottom = 'textures/h3ui/' .. prefix .. '_bottom.dds',
    bottomRight = 'textures/h3ui/' .. prefix .. '_bottom_right' .. cornerSuffix .. '.dds',
    tintable = true,
  }
  if center then result.center = 'textures/h3ui/' .. prefix .. '_' .. center .. '.dds' end
  return result
end

local builtin = {
  preferredSource = 'h3ui',
  frame = {
    thin = frame('menu_thin_border', 2),
    thick = frame('menu_thick_border', 4),
    button = frame('menu_button_frame', 4),
  },
  caption = frame('menu_head_block', 2, 'middle'),
  pin = {
    up = frame('menu_rightbuttonup', 2, 'center', ''),
    down = frame('menu_rightbuttondown', 2, 'center', ''),
  },
  scroll = {
    up = 'textures/h3ui/omw_menu_scroll_up.dds',
    down = 'textures/h3ui/omw_menu_scroll_down.dds',
    left = 'textures/h3ui/omw_menu_scroll_left.dds',
    right = 'textures/h3ui/omw_menu_scroll_right.dds',
  },
}

copy = function(value, seen)
  if type(value) ~= 'table' then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end

  local result = {}
  seen[value] = result
  for key, item in next, value do
    result[key] = copy(item, seen)
  end
  return result
end

local function texture(value)
  if type(value) == 'string' then
    local result = textureCache[value]
    if not result then
      result = uiModule().texture { path = value }
      textureCache[value] = result
    end
    return result
  end
  return value
end

local function material(resource, tint, alpha, tintable)
  local props = {
    resource = texture(resource),
    ignorePointerEvents = true,
  }
  if tintable == true and tint ~= nil then props.color = tint end
  if alpha ~= nil then props.alpha = alpha end
  return props
end

local function image(
  resource,
  anchor,
  position,
  size,
  relativeSize,
  tileH,
  tileV,
  tint,
  alpha,
  tintable
)
  local openmwUi = uiModule()
  local props = material(resource, tint, alpha, tintable)
  props.anchor = anchor
  props.relativePosition = anchor
  props.position = position
  props.size = size
  props.relativeSize = relativeSize
  props.tileH = tileH
  props.tileV = tileV
  return { type = openmwUi.TYPE.Image, props = props }
end

local function backgroundChildren(skin, tint, alpha, backgroundProps, includeCenter)
  local openmwUi = uiModule()
  local content = {}

  if backgroundProps then
    local background = copy(backgroundProps)
    background.resource = background.resource or texture 'white'
    background.ignorePointerEvents = true
    background.relativeSize = background.relativeSize or fullSize
    content[#content + 1] = { type = openmwUi.TYPE.Image, props = background }
  end

  if includeCenter ~= false and skin.center then
    local center = material(skin.center, tint, alpha, skin.tintable)
    center.anchor = zero
    center.relativePosition = zero
    center.position = zero
    center.size = zero
    center.relativeSize = fullSize
    center.tileH = true
    center.tileV = true
    content[#content + 1] = { type = openmwUi.TYPE.Image, props = center }
  end

  return content
end

local function frameChildren(skin, thickness, tint, alpha, backgroundProps, includeCenter)
  local content = backgroundChildren(skin, tint, alpha, backgroundProps, includeCenter)

  content[#content + 1] = image(
    skin.topLeft,
    zero,
    zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.top,
    zero,
    UtilVector2(thickness, 0),
    UtilVector2(-2 * thickness, thickness),
    relativeWidth,
    true,
    false,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.topRight,
    rightTop,
    zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.left,
    zero,
    UtilVector2(0, thickness),
    UtilVector2(thickness, -2 * thickness),
    relativeHeight,
    false,
    true,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.right,
    rightTop,
    UtilVector2(0, thickness),
    UtilVector2(thickness, -2 * thickness),
    relativeHeight,
    false,
    true,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.bottomLeft,
    leftBottom,
    zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.bottom,
    leftBottom,
    UtilVector2(thickness, 0),
    UtilVector2(-2 * thickness, thickness),
    relativeWidth,
    true,
    false,
    tint,
    alpha,
    skin.tintable
  )
  content[#content + 1] = image(
    skin.bottomRight,
    rightBottom,
    zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil,
    tint,
    alpha,
    skin.tintable
  )

  return content
end

local function skinFrom(theme, path)
  local source = theme and theme.chrome and theme.chrome() or nil
  local value = source
  for part in string.gmatch(path, '[^%.]+') do
    if type(value) ~= 'table' then
      value = nil
      break
    end
    value = value[part]
  end
  if value == nil then
    value = builtin
    for part in string.gmatch(path, '[^%.]+') do
      value = value[part]
    end
  end
  return value
end

local function frameLayout(options)
  local openmwUi = uiModule()
  local skin = options.skin
  assert(type(skin) == 'table', 'H3 UI chrome frame requires a skin')
  local thickness = skin.thickness
  assert(type(thickness) == 'number' and thickness > 0, 'H3 UI chrome frame requires thickness')

  local content = backgroundChildren(skin, options.tint, options.alpha, options.backgroundProps)
  if options.contentProps then
    content[#content + 1] = {
      type = openmwUi.TYPE.Widget,
      props = copy(options.contentProps),
      content = openmwUi.content(options.content or {}),
    }
  else
    for index = 1, #(options.content or {}) do
      content[#content + 1] = options.content[index]
    end
  end

  local slices = frameChildren(skin, thickness, options.tint, options.alpha, nil, false)
  for index = 1, #slices do
    content[#content + 1] = slices[index]
  end

  return {
    type = options.type or openmwUi.TYPE.Widget,
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = openmwUi.content(content),
  }
end

local function cacheKey(value)
  if value == nil then return 'nil' end
  return tostring(value)
end

local function boxTemplate(options)
  local skin = options.skin
  local thickness = skin.thickness
  local skinCache = templateCache[skin]
  if not skinCache then
    skinCache = {}
    templateCache[skin] = skinCache
  end

  local tintKey = cacheKey(options.tint)
  local tintCache = skinCache[tintKey]
  if not tintCache then
    tintCache = {}
    skinCache[tintKey] = tintCache
  end

  local alphaKey = cacheKey(options.alpha)
  local backgroundKey = cacheKey(options.backgroundProps)
  local key = alphaKey .. ':' .. backgroundKey
  local result = tintCache[key]
  if result then return result end

  result = {
    type = uiModule().TYPE.Container,
    content = uiModule().content(
      frameChildren(skin, thickness, options.tint, options.alpha, options.backgroundProps)
    ),
  }
  tintCache[key] = result
  return result
end

local function boxLayout(options)
  local skin = options.skin
  assert(type(skin) == 'table', 'H3 UI chrome box requires a skin')
  assert(
    type(skin.thickness) == 'number' and skin.thickness > 0,
    'H3 UI chrome box requires thickness'
  )

  return {
    template = boxTemplate(options),
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = uiModule().content(options.content or {}),
  }
end

---@return H3UI.ChromeSpec
local function builtinChrome() return builtin end

return {
  builtin = builtinChrome,
  box = boxLayout,
  frame = frameLayout,
  resolve = skinFrom,
  texture = texture,
}
