---@module 'scripts.h3.ui.themes.chromeAssets'
---@omw-context menu|player

local util = require 'openmw.util'
local StrFormat = string.format

local UtilVector2 = util.vector2

local H3UIPath, MorrowindPath =
  'textures/h3ui/chrome/coral_fort_wall_02.dds', 'textures/h3ui/chrome/morrowind.dds'

---@param x number
---@param y number
---@return openmw.util.Vector2
local function vector2(x, y) return UtilVector2(x, y) end

---@param path string
---@param x number
---@param y number
---@param width number
---@param height number
---@param thickness number
---@param center? boolean|string
---@param tintable? boolean
---@return H3UI.ChromeFrame
local function region(path, x, y, width, height, thickness, center, tintable)
  return {
    path = path,
    offset = vector2(x, y),
    size = vector2(width, height),
    thickness = thickness,
    center = center,
    tintable = tintable,
    sourceBorder = thickness,
  }
end

-- Both shipped atlases share one nested 512x512 layout: thick owns the canvas,
-- thin nests at +4,+4, and the controls pack into thin's center. Source borders
-- equal rendered thickness throughout, so regions differ between themes only by
-- texture path.
---@param path string
---@param tintable boolean
---@return H3UI.ChromeAssetFrameSet
local function frame(path, tintable)
  return {
    thin = region(path, 4, 4, 504, 504, 2, false, tintable),
    thick = region(path, 0, 0, 512, 512, 4, false, tintable),
    button = region(path, 56, 56, 136, 24, 4, false, tintable),
    caption = region(path, 56, 160, 260, 20, 2, true, tintable),
    pinUp = region(path, 328, 56, 20, 20, 2, true, tintable),
    pinDown = region(path, 400, 56, 20, 20, 2, true, tintable),
  }
end

---@param path string
---@param x number
---@param y number
---@param width number
---@param height number
---@return H3UI.TextureRegion
local function textureRegion(path, x, y, width, height)
  return {
    path = path,
    offset = vector2(x, y),
    size = vector2(width, height),
  }
end

---@param path string
---@return table<string, H3UI.TextureRegion>
local function scroll(path)
  return {
    up = textureRegion(path, 320, 128, 16, 16),
    down = textureRegion(path, 356, 128, 16, 16),
    left = textureRegion(path, 392, 128, 16, 16),
    right = textureRegion(path, 428, 128, 16, 16),
  }
end

-- H3UI material library. Families are the single catalog structure: order,
-- membership, and defaults all derive from this table. Every entry shares one
-- nested 512x512 layout and differs only by grain.
local Families = {
  {
    id = 'stone',
    materials = {
      'aerial_asphalt_01',
      'asphalt_04',
      'asphalt_snow',
      'dark_rock',
      'gravel_embedded_concrete',
      'marble_cliff_04',
      'pebble_embedded_pavement',
      'plastered_stone_wall',
      'rock_embedded_concrete_wall',
      'rock_wall_09',
      'stone_tiles',
      'worn_asphalt',
    },
  },
  { id = 'snow', materials = { 'snow_field_aerial' } },
  {
    id = 'concrete',
    materials = {
      'coral_fort_wall_02',
      'brushed_concrete',
      'brushed_concrete_04',
      'concrete_floor_painted',
      'cracked_concrete_wall',
      'dirty_concrete',
      'hangar_concrete_floor',
      'painted_concrete',
    },
  },
  {
    id = 'plaster',
    materials = {
      'patterned_clay_wall',
      'rough_plaster_brick',
      'rough_plaster_brick_02',
      'worn_mossy_plasterwall',
    },
  },
  {
    id = 'wood',
    materials = {
      'bamboo_wall',
      'bark_brown_02',
      'black_walnut_veneer_03',
      'wood_plank_wall',
    },
  },
  { id = 'wallpaper', materials = { 'decrepit_wallpaper' } },
  {
    id = 'fabric',
    materials = {
      'denim_fabric_06',
      'faux_fur_geometric',
      'floral_jacquard',
      'hessian_230',
      'tatami_mat',
    },
  },
  { id = 'leather', materials = { 'leather_red_03' } },
  {
    id = 'tile',
    materials = {
      'floor_pattern_02',
      'rubber_tiles',
      'square_tiles_02',
    },
  },
  { id = 'thatch', materials = { 'reed_roof_03' } },
  { id = 'classic', materials = { 'morrowind' } },
}

local variantOrder, variantFamily, familyOrder, familyMaterials = {}, {}, {}, {}
for findex = 1, #Families do
  local family = Families[findex]
  familyOrder[findex] = family.id
  familyMaterials[family.id] = family.materials
  for mindex = 1, #family.materials do
    local stem = family.materials[mindex]
    variantOrder[#variantOrder + 1] = stem
    variantFamily[stem] = family.id
  end
end

---@param source? string[]
---@return string[]
local function copyList(source)
  local result = {}
  if source then
    for index = 1, #source do
      result[index] = source[index]
    end
  end
  return result
end

---@return string[]
local function materialFamilies() return copyList(familyOrder) end

---@param family string
---@return string[]
local function materialStems(family) return copyList(familyMaterials[family]) end

---@param stem string
---@return string
local function materialPath(stem) return StrFormat('textures/h3ui/chrome/%s.dds', stem) end

---@param path string
---@return H3UI.ChromeSpec
local function atlas(path)
  local shaped = frame(path, true)
  return {
    preferredSource = 'h3ui',
    frame = {
      thin = shaped.thin,
      thick = shaped.thick,
      button = shaped.button,
    },
    caption = shaped.caption,
    pin = {
      up = shaped.pinUp,
      down = shaped.pinDown,
    },
    scroll = scroll(path),
  }
end

local MaterialCache = {}

---@param stem string
---@return H3UI.ChromeSpec?
local function material(stem)
  if not variantFamily[stem] then return end
  local cached = MaterialCache[stem]
  if cached then return cached end
  cached = atlas(materialPath(stem))
  MaterialCache[stem] = cached
  return cached
end

return {
  h3ui = {
    frame = frame(H3UIPath, true),
    scroll = scroll(H3UIPath),
  },
  morrowind = {
    frame = frame(MorrowindPath, true),
    scroll = scroll(MorrowindPath),
  },
  starwind = {
    frame = frame(MorrowindPath, true),
    scroll = scroll(MorrowindPath),
  },
  materialFamilies = materialFamilies,
  materialStems = materialStems,
  variantOrder = variantOrder,
  variantFamily = variantFamily,
  material = material,
}
