---@omw-context menu|player
---@module 'scripts.s3.ui.chrome'

local StrFormat = string.format

local copy
local ui = require 'openmw.ui'

local textureCache = {}
local skinPartCache = setmetatable({}, { __mode = 'k' })
local skinLookupCache = setmetatable({}, { __mode = 'k' })
local colorKeyCache = setmetatable({}, { __mode = 'k' })
local UtilVector2 = require('openmw.util').vector2
local chromeAssets = require 'scripts.s3.ui.themes.chromeAssets'

local Zero = UtilVector2(0, 0)
local RightTop = UtilVector2(1, 0)
local LeftBottom = UtilVector2(0, 1)
local RightBottom = UtilVector2(1, 1)
local FullSize = UtilVector2(1, 1)
local RelativeWidth = UtilVector2(1, 0)
local RelativeHeight = UtilVector2(0, 1)

local framePartNames = {
  'center',
  'topLeft',
  'top',
  'topRight',
  'left',
  'right',
  'bottomLeft',
  'bottom',
  'bottomRight',
}

local builtin = {
  preferredSource = 'h3ui',
  frame = {
    thin = chromeAssets.h3ui.frame.thin,
    thick = chromeAssets.h3ui.frame.thick,
    button = chromeAssets.h3ui.frame.button,
  },
  caption = chromeAssets.h3ui.frame.caption,
  pin = {
    up = chromeAssets.h3ui.frame.pinUp,
    down = chromeAssets.h3ui.frame.pinDown,
  },
  scroll = {
    up = chromeAssets.h3ui.scroll.up,
    down = chromeAssets.h3ui.scroll.down,
    left = chromeAssets.h3ui.scroll.left,
    right = chromeAssets.h3ui.scroll.right,
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
  if type(value) == 'table' and value.path and value.offset and value.size then
    local offset = value.offset
    local size = value.size
    local key = table.concat({
      value.path,
      tostring(offset.x),
      tostring(offset.y),
      tostring(size.x),
      tostring(size.y),
    }, ':')
    local result = textureCache[key]
    if not result then
      result = ui.texture { path = value.path, offset = offset, size = size }
      textureCache[key] = result
    end
    return result
  end
  if type(value) == 'string' then
    local result = textureCache[value]
    if not result then
      result = ui.texture { path = value }
      textureCache[value] = result
    end
    return result
  end
  return value
end

local function sourceMargins(skin)
  local border = skin.sourceBorder or skin.thickness
  if type(border) == 'number' then return border, border, border, border end
  assert(type(border) == 'table', 'H3 UI chrome source requires border margins')
  return border.left, border.top, border.right, border.bottom
end

local function atlasPart(skin, name)
  if skin.parts then
    local part = skin.parts[name]
    return part and texture(part) or nil
  end

  if not (skin.path and skin.offset and skin.size) then return nil end
  if name == 'center' and not skin.center then return nil end

  local left, top, right, bottom = sourceMargins(skin)
  local width = skin.size.x
  local height = skin.size.y
  local centerWidth = width - left - right
  local centerHeight = height - top - bottom
  assert(centerWidth > 0 and centerHeight > 0, 'H3 UI chrome source region is too small')

  local x = skin.offset.x
  local y = skin.offset.y
  local partX = x
  local partY = y
  local partWidth = left
  local partHeight = top

  if name == 'center' then
    partX = x + left
    partY = y + top
    partWidth = centerWidth
    partHeight = centerHeight
  elseif name == 'top' then
    partX = x + left
    partWidth = centerWidth
  elseif name == 'topRight' then
    partX = x + width - right
    partWidth = right
  elseif name == 'left' then
    partY = y + top
    partHeight = centerHeight
  elseif name == 'right' then
    partX = x + width - right
    partY = y + top
    partWidth = right
    partHeight = centerHeight
  elseif name == 'bottomLeft' then
    partY = y + height - bottom
    partHeight = bottom
  elseif name == 'bottom' then
    partX = x + left
    partY = y + height - bottom
    partWidth = centerWidth
    partHeight = bottom
  elseif name == 'bottomRight' then
    partX = x + width - right
    partY = y + height - bottom
    partWidth = right
    partHeight = bottom
  end

  return texture {
    path = skin.path,
    offset = UtilVector2(partX, partY),
    size = UtilVector2(partWidth, partHeight),
  }
end

local function skinPart(skin, name)
  local cache = skinPartCache[skin]
  if not cache then
    cache = {}
    skinPartCache[skin] = cache
  end
  local cached = cache[name]
  if cached ~= nil then return cached ~= false and cached or nil end
  local result = atlasPart(skin, name) or texture(skin[name])
  cache[name] = result or false
  return result
end

local function material(resource, tint, alpha, tintable, tintProps)
  local props = {
    resource = texture(resource),
    ignorePointerEvents = true,
  }
  if tintable == true and tint ~= nil then props.color = tint end
  if alpha ~= nil then props.alpha = alpha end
  if tintProps then
    for key, value in next, tintProps do
      props[key] = value
    end
  end
  return props
end

local function image(
  name,
  resource,
  anchor,
  position,
  size,
  relativeSize,
  tileH,
  tileV,
  tint,
  alpha,
  tintable,
  tintProps
)
  local openmwUi = ui
  local props = material(resource, tint, alpha, tintable, tintProps)
  props.anchor = anchor
  props.relativePosition = anchor
  props.position = position
  props.size = size
  props.relativeSize = relativeSize
  props.tileH = tileH
  props.tileV = tileV
  return { name = name, type = openmwUi.TYPE.Image, props = props }
end

local function backgroundChildren(skin, tint, alpha, backgroundProps, includeCenter, tintProps)
  local openmwUi = ui
  local content = {}

  if backgroundProps then
    local background = copy(backgroundProps)
    background.resource = background.resource or texture 'white'
    background.ignorePointerEvents = true
    background.relativeSize = background.relativeSize or FullSize
    content[#content + 1] = { type = openmwUi.TYPE.Image, props = background }
  end

  local centerResource = skinPart(skin, 'center')
  if includeCenter ~= false and centerResource then
    local center = material(centerResource, tint, alpha, skin.tintable, tintProps)
    center.anchor = Zero
    center.relativePosition = Zero
    center.position = Zero
    center.size = Zero
    center.relativeSize = FullSize
    center.tileH = true
    center.tileV = true
    content[#content + 1] = {
      name = 'h3ui_center',
      type = openmwUi.TYPE.Image,
      props = center,
    }
  end

  return content
end

local function frameChildren(
  skin,
  thickness,
  tint,
  alpha,
  backgroundProps,
  includeCenter,
  tintProps
)
  local content = backgroundChildren(skin, tint, alpha, backgroundProps, includeCenter, tintProps)

  local function addFrameImage(name, resource, anchor, position, size, relativeSize, tileH, tileV)
    local child = image(
      'h3ui_' .. name,
      resource,
      anchor,
      position,
      size,
      relativeSize,
      tileH,
      tileV,
      tint,
      alpha,
      skin.tintable,
      tintProps
    )
    content[#content + 1] = child
  end

  addFrameImage(
    'topLeft',
    skinPart(skin, 'topLeft'),
    Zero,
    Zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil
  )
  addFrameImage(
    'top',
    skinPart(skin, 'top'),
    Zero,
    UtilVector2(thickness, 0),
    UtilVector2(-2 * thickness, thickness),
    RelativeWidth,
    true,
    false
  )
  addFrameImage(
    'topRight',
    skinPart(skin, 'topRight'),
    RightTop,
    Zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil
  )
  addFrameImage(
    'left',
    skinPart(skin, 'left'),
    Zero,
    UtilVector2(0, thickness),
    UtilVector2(thickness, -2 * thickness),
    RelativeHeight,
    false,
    true
  )
  addFrameImage(
    'right',
    skinPart(skin, 'right'),
    RightTop,
    UtilVector2(0, thickness),
    UtilVector2(thickness, -2 * thickness),
    RelativeHeight,
    false,
    true
  )
  addFrameImage(
    'bottomLeft',
    skinPart(skin, 'bottomLeft'),
    LeftBottom,
    Zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil
  )
  addFrameImage(
    'bottom',
    skinPart(skin, 'bottom'),
    LeftBottom,
    UtilVector2(thickness, 0),
    UtilVector2(-2 * thickness, thickness),
    RelativeWidth,
    true,
    false
  )
  addFrameImage(
    'bottomRight',
    skinPart(skin, 'bottomRight'),
    RightBottom,
    Zero,
    UtilVector2(thickness, thickness),
    nil,
    nil,
    nil
  )

  return content
end

local function skinFrom(theme, path)
  if theme then
    local cache = skinLookupCache[theme]
    if cache and cache[path] ~= nil then return cache[path] end
  end

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

  if theme then
    local cache = skinLookupCache[theme]
    if not cache then
      cache = {}
      skinLookupCache[theme] = cache
    end
    cache[path] = value
  end
  return value
end

local function frameLayout(options)
  local openmwUi = ui
  local skin = options.skin
  assert(type(skin) == 'table', 'H3 UI chrome frame requires a skin')
  local thickness = skin.thickness
  assert(type(thickness) == 'number' and thickness > 0, 'H3 UI chrome frame requires thickness')

  local contentProps = options.contentProps
  if options.inset ~= nil then
    assert(
      type(options.inset) == 'number' and options.inset >= 0,
      'H3 UI chrome inset must be non-negative'
    )
    contentProps = copy(options.contentProps or {})
    contentProps.position = contentProps.position or UtilVector2(options.inset, options.inset)
    contentProps.size = contentProps.size or UtilVector2(-2 * options.inset, -2 * options.inset)
    contentProps.relativeSize = contentProps.relativeSize or FullSize
  end

  local content = backgroundChildren(skin, options.tint, options.alpha, options.backgroundProps)
  if contentProps then
    content[#content + 1] = {
      type = openmwUi.TYPE.Widget,
      props = contentProps,
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

local function framePart(layout, name) return layout.content['h3ui_' .. name] end

local function applyCompatibleSkin(layout, skin, tint, alpha)
  assert(type(skin) == 'table', 'H3 UI chrome skin requires a table')
  assert(
    type(skin.thickness) == 'number' and skin.thickness > 0,
    'H3 UI chrome skin requires thickness'
  )

  local topLeft = framePart(layout, 'topLeft')
  assert(topLeft, 'H3 UI chrome frame is missing topLeft')
  assert(
    topLeft.props.size.x == skin.thickness,
    'H3 UI chrome skin thickness is incompatible with the existing frame'
  )

  for index = 1, #framePartNames do
    local name = framePartNames[index]
    local resource = skinPart(skin, name)
    local child = framePart(layout, name)
    assert(
      (resource ~= nil) == (child ~= nil),
      'H3 UI chrome skin topology is incompatible with the existing frame'
    )
    if resource then
      child.props.resource = texture(resource)
      child.props.color = skin.tintable and tint or nil
      child.props.alpha = alpha
    end
  end
end

local function nineSliceLayout(options)
  options = options or {}
  local normalized = copy(options)
  normalized.skin = options.source or options.skin
  return frameLayout(normalized)
end

local function colorHex(value) return value:asHex() end

local function cacheKey(value, seen)
  if value == nil then return 'nil' end
  local valueType = type(value)

  -- Equivalent colors must share cache entries regardless of userdata identity.
  if valueType == 'userdata' then
    local cached = colorKeyCache[value]
    if cached then return cached end
    local ok, hex = pcall(colorHex, value)
    if ok and type(hex) == 'string' then
      cached = StrFormat('color:%s', hex)
      colorKeyCache[value] = cached
      return cached
    end
  end

  if valueType ~= 'table' then return StrFormat('%s:%s', valueType, tostring(value)) end

  seen = seen or {}
  if seen[value] then return '<cycle>' end
  seen[value] = true

  local keys = {}
  for key in next, value do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)

  local parts = {}
  for index = 1, #keys do
    local key = keys[index]
    parts[#parts + 1] = StrFormat('%s=%s', cacheKey(key, seen), cacheKey(value[key], seen))
  end
  seen[value] = nil
  return StrFormat('{%s}', table.concat(parts, ';'))
end

---@return H3UI.ChromeSpec
local function builtinChrome() return builtin end

local function variantFamily(stem) return chromeAssets.variantFamily[stem] end

---@param stem string
---@return H3UI.ChromeSpec?
local function variantChrome(stem) return chromeAssets.material(stem) end

return {
  builtin = builtinChrome,
  variant = variantChrome,
  variantFamily = variantFamily,
  materialFamilies = chromeAssets.materialFamilies,
  materialStems = chromeAssets.materialStems,
  frame = frameLayout,
  backgroundChildren = backgroundChildren,
  frameChildren = frameChildren,
  cacheKey = cacheKey,
  nineSlice = nineSliceLayout,
  applyCompatibleSkin = applyCompatibleSkin,
  resolve = skinFrom,
  texture = texture,
}
