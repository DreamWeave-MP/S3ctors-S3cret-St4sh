---@omw-context menu|player
---@module 'scripts.h3.ui.chrome'

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local chromeAssets = require 'scripts.h3.ui.themes.chromeAssets'

local Assert, Next, SetMetatable, StrFormat, StrGmatch, TableConcat, TableSort, ToString, Type =
  assert, next, setmetatable, string.format, string.gmatch, table.concat, table.sort, tostring, type

local UiContent, UiTexture, UiType, UtilVector2 = ui.content, ui.texture, ui.TYPE, util.vector2

local TextureCache = {}
local WeakKeys = { __mode = 'k' }
local SkinPartCache = SetMetatable({}, WeakKeys)
local SkinLookupCache = SetMetatable({}, WeakKeys)
local ColorKeyCache = SetMetatable({}, WeakKeys)

local Zero, RightTop, LeftBottom, RightBottom, FullSize, RelativeWidth, RelativeHeight =
  UtilVector2(0, 0),
  UtilVector2(1, 0),
  UtilVector2(0, 1),
  UtilVector2(1, 1),
  UtilVector2(1, 1),
  UtilVector2(1, 0),
  UtilVector2(0, 1)

local FramePartNames = {
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

local Builtin = {
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

---@generic T
---@param value T
---@param seen? table<table, table>
---@return T
local function copy(value, seen)
  if Type(value) ~= 'table' then return value end

  seen = seen or {}
  if seen[value] then return seen[value] end

  local result = {}
  seen[value] = result

  for key, item in Next, value do
    result[key] = copy(item, seen)
  end

  return result
end

---@param value H3UI.ChromeTexture
---@return openmw.ui.TextureResource
local function texture(value)
  if Type(value) == 'table' then
    local path, offset, size = value.path, value.offset, value.size
    if path and offset and size then
      local key = TableConcat({
        path,
        ToString(offset.x),
        ToString(offset.y),
        ToString(size.x),
        ToString(size.y),
      }, ':')

      local result = TextureCache[key]
      if not result then
        result = UiTexture { path = path, offset = offset, size = size }
        TextureCache[key] = result
      end

      return result
    end
  end

  if Type(value) == 'string' then
    local result = TextureCache[value]

    if not result then
      result = UiTexture { path = value }
      TextureCache[value] = result
    end

    return result
  end

  ---@cast value openmw.ui.TextureResource
  return value
end

---@param skin H3UI.ChromeFrame
---@return number left
---@return number top
---@return number right
---@return number bottom
local function sourceMargins(skin)
  local border = skin.sourceBorder or skin.thickness

  if Type(border) == 'number' then return border, border, border, border end

  Assert(Type(border) == 'table', 'H3 UI chrome source requires border margins')

  return border.left, border.top, border.right, border.bottom
end

---@param skin H3UI.ChromeFrame
---@param name string
---@return openmw.ui.TextureResource?
local function atlasPart(skin, name)
  if skin.parts then
    local part = skin.parts[name]
    return part and texture(part)
  end

  if not (skin.path and skin.offset and skin.size) then return end
  if name == 'center' and not skin.center then return end

  local left, top, right, bottom = sourceMargins(skin)
  local width = skin.size.x
  local height = skin.size.y
  local centerWidth = width - left - right
  local centerHeight = height - top - bottom
  Assert(centerWidth > 0 and centerHeight > 0, 'H3 UI chrome source region is too small')

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

---@param skin H3UI.ChromeFrame
---@param name string
---@return openmw.ui.TextureResource?
local function skinPart(skin, name)
  local cache = SkinPartCache[skin]

  if not cache then
    cache = {}
    SkinPartCache[skin] = cache
  end

  local cached = cache[name]
  if cached == false then return end
  if cached then return cached end

  local result = atlasPart(skin, name)
  if not result then
    local legacy = skin[name]
    if legacy then result = texture(legacy) end
  end
  cache[name] = result or false

  return result
end

---@param resource H3UI.ChromeTexture
---@param tint? openmw.util.Color
---@param alpha? number
---@param tintable? boolean
---@return table
local function material(resource, tint, alpha, tintable)
  local props = {
    resource = texture(resource),
    ignorePointerEvents = true,
  }

  if tintable and tint then props.color = tint end
  if alpha then props.alpha = alpha end

  return props
end

---@param name string
---@param resource H3UI.ChromeTexture
---@param anchor openmw.util.Vector2
---@param position openmw.util.Vector2
---@param size openmw.util.Vector2
---@param relativeSize? openmw.util.Vector2
---@param tileH? boolean
---@param tileV? boolean
---@param tint? openmw.util.Color
---@param alpha? number
---@param tintable? boolean
---@return openmw.ui.Layout
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
  tintable
)
  local props = material(resource, tint, alpha, tintable)

  props.anchor = anchor
  props.relativePosition = anchor
  props.position = position
  props.size = size
  props.relativeSize = relativeSize
  props.tileH = tileH
  props.tileV = tileV

  return { name = name, type = UiType.Image, props = props }
end

---@param skin H3UI.ChromeFrame
---@param tint? openmw.util.Color
---@param alpha? number
---@param backgroundProps? table
---@param includeCenter? boolean
---@return openmw.ui.LayoutOrElement[]
local function backgroundChildren(skin, tint, alpha, backgroundProps, includeCenter)
  local content = {}

  if backgroundProps then
    local background = copy(backgroundProps)

    background.resource = background.resource or texture 'white'
    background.ignorePointerEvents = true
    background.relativeSize = background.relativeSize or FullSize

    content[#content + 1] = { type = UiType.Image, props = background }
  end

  local centerResource = skinPart(skin, 'center')
  if includeCenter ~= false and centerResource then
    local center = material(centerResource, tint, alpha, skin.tintable)
    center.anchor = Zero
    center.relativePosition = Zero
    center.position = Zero
    center.size = Zero
    center.relativeSize = FullSize
    center.tileH = true
    center.tileV = true
    content[#content + 1] = {
      name = 'h3ui_center',
      type = UiType.Image,
      props = center,
    }
  end

  return content
end

---@param skin H3UI.ChromeFrame
---@param thickness number
---@param tint? openmw.util.Color
---@param alpha? number
---@param backgroundProps? table
---@param includeCenter? boolean
---@return openmw.ui.LayoutOrElement[]
local function frameChildren(skin, thickness, tint, alpha, backgroundProps, includeCenter)
  local content = backgroundChildren(skin, tint, alpha, backgroundProps, includeCenter)

  ---@param name string
  ---@param resource? H3UI.ChromeTexture
  ---@param anchor openmw.util.Vector2
  ---@param position openmw.util.Vector2
  ---@param size openmw.util.Vector2
  ---@param relativeSize? openmw.util.Vector2
  ---@param tileH? boolean
  ---@param tileV? boolean
  ---@return nil
  local function addFrameImage(name, resource, anchor, position, size, relativeSize, tileH, tileV)
    Assert(resource, StrFormat('H3 UI chrome frame is missing part: %s', name))

    local child = image(
      StrFormat('h3ui_%s', name),
      resource,
      anchor,
      position,
      size,
      relativeSize,
      tileH,
      tileV,
      tint,
      alpha,
      skin.tintable
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

---@param root table
---@param path string
---@return H3UI.ChromeResource?
local function lookupPath(root, path)
  local value = root

  for part in StrGmatch(path, '[^%.]+') do
    if Type(value) ~= 'table' then return end

    value = value[part]
  end

  return value
end

---@param theme? H3UI.Theme
---@param path string
---@return H3UI.ChromeResource
local function skinFrom(theme, path)
  if not theme then
    local value = lookupPath(Builtin, path)

    Assert(value, StrFormat('Unknown H3 UI chrome path: %s', path))

    return value
  end

  local cache = SkinLookupCache[theme]
  if cache and cache[path] then return cache[path] end

  local value = lookupPath(theme.chrome(), path) or lookupPath(Builtin, path)
  Assert(value, StrFormat('Unknown H3 UI chrome path: %s', path))

  if not cache then
    cache = {}
    SkinLookupCache[theme] = cache
  end

  cache[path] = value

  return value
end

---@param options H3UI.ChromeFrameOptions
---@return openmw.ui.Layout
local function frameLayout(options)
  local skin = options.skin
  Assert(Type(skin) == 'table', 'H3 UI chrome frame requires a skin')

  local thickness = skin.thickness
  Assert(Type(thickness) == 'number' and thickness > 0, 'H3 UI chrome frame requires thickness')

  local contentProps = options.contentProps
  local optionContent = options.content or {}
  if options.inset ~= nil then
    Assert(
      Type(options.inset) == 'number' and options.inset >= 0,
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
      type = UiType.Widget,
      props = contentProps,
      content = UiContent(optionContent),
    }
  else
    for index = 1, #optionContent do
      content[#content + 1] = optionContent[index]
    end
  end

  local slices = frameChildren(skin, thickness, options.tint, options.alpha, nil, false)
  for index = 1, #slices do
    content[#content + 1] = slices[index]
  end

  return {
    type = options.type or UiType.Widget,
    name = options.name,
    props = options.props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    content = UiContent(content),
  }
end

---@param layout openmw.ui.Layout
---@param name string
---@return openmw.ui.Layout?
local function framePart(layout, name) return layout.content[StrFormat('h3ui_%s', name)] end

---@param layout openmw.ui.Layout
---@param skin H3UI.ChromeFrame
---@param tint? openmw.util.Color
---@param alpha? number
---@return nil
local function applyCompatibleSkin(layout, skin, tint, alpha)
  Assert(Type(skin) == 'table', 'H3 UI chrome skin requires a table')

  Assert(
    Type(skin.thickness) == 'number' and skin.thickness > 0,
    'H3 UI chrome skin requires thickness'
  )

  local topLeft = framePart(layout, 'topLeft')
  Assert(topLeft, 'H3 UI chrome frame is missing topLeft')
  Assert(
    topLeft.props.size.x == skin.thickness,
    'H3 UI chrome skin thickness is incompatible with the existing frame'
  )

  for index = 1, #FramePartNames do
    local name = FramePartNames[index]
    local resource = skinPart(skin, name)
    local child = framePart(layout, name)

    if resource then
      Assert(child, 'H3 UI chrome skin topology is incompatible with the existing frame')
      child.props.resource = texture(resource)
      child.props.color = skin.tintable and tint or nil
      child.props.alpha = alpha
    else
      Assert(not child, 'H3 UI chrome skin topology is incompatible with the existing frame')
    end
  end
end

---@param options H3UI.NineSliceOptions
---@return openmw.ui.Layout
local function nineSliceLayout(options)
  options = options or {}

  return frameLayout {
    alpha = options.alpha,
    backgroundProps = options.backgroundProps,
    content = options.content,
    contentProps = options.contentProps,
    events = options.events,
    external = options.external,
    inset = options.inset,
    name = options.name,
    props = options.props,
    skin = options.source,
    tint = options.tint,
    userData = options.userData,
  }
end

---@param left H3UI.CacheKeyValue
---@param right H3UI.CacheKeyValue
---@return boolean
local function compareCacheKeys(left, right) return ToString(left) < ToString(right) end

---@param value H3UI.CacheKeyValue
---@param seen? table<table, boolean?>
---@return string
local function cacheKey(value, seen)
  if value == nil then return 'nil' end
  local valueType = Type(value)

  if valueType == 'userdata' then
    ---@cast value H3UI.ColorLikeUserdata
    if value.__type.name == 'Misc::Color' then
      local cached = ColorKeyCache[value]
      if cached then return cached end

      cached = StrFormat('color:%s', value:asHex())
      ColorKeyCache[value] = cached
      return cached
    end
  end

  if valueType ~= 'table' then return StrFormat('%s:%s', valueType, ToString(value)) end

  seen = seen or {}
  Assert(not seen[value], 'H3 UI chrome cache keys cannot contain table cycles')
  seen[value] = true

  local keys = {}

  for key in Next, value do
    keys[#keys + 1] = key
  end

  TableSort(keys, compareCacheKeys)

  local parts = {}
  for index = 1, #keys do
    local key = keys[index]
    parts[#parts + 1] = StrFormat('%s=%s', cacheKey(key, seen), cacheKey(value[key], seen))
  end

  seen[value] = nil

  return StrFormat('{%s}', TableConcat(parts, ';'))
end

---@return H3UI.ChromeSpec
local function builtinChrome() return Builtin end

---@param stem string
---@return string?
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
