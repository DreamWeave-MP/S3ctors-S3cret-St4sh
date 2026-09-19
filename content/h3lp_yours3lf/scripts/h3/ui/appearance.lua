---@omw-context menu|player

local async = require 'openmw.async'
local core = require 'openmw.core'
local storage = require 'openmw.storage'
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local builtinChrome = require 'scripts.h3.ui.chrome'
local themeModule = require 'scripts.h3.ui.theme'

local Assert, Error, MathFloor, MathMax, MathMin, Next, TableSort, StrFormat, ToNumber, ToString, Type =
  assert,
  error,
  math.floor,
  math.max,
  math.min,
  next,
  table.sort,
  string.format,
  tonumber,
  tostring,
  type

local ColorHex, ContentFiles, FileExists, PlayerSection =
  util.color.hex, core.contentFiles, vfs.fileExists, storage.playerSection

local SectionName, CustomSectionName, CustomThemeId, MenuTransparencyKey, ChromeTransparencyKey, NormalTextSizeKey, HeaderTextSizeKey, ChromeSourceKey, ChromeMaterialFamilyKey, ChromeMaterialKey, DefaultChromeSource, DefaultMaterial =
  'SettingsPlayerH3UI',
  'SettingsPlayerH3UICustom',
  'custom',
  'menuTransparency',
  'chromeTransparency',
  'textSizeNormal',
  'textSizeHeader',
  'chromeSource',
  'chromeMaterialFamily',
  'chromeMaterial',
  'auto',
  'coral_fort_wall_02'

---@type string
local DefaultMaterialFamily = Assert(builtinChrome.variantFamily(DefaultMaterial))

local DefaultMenuTransparency, DefaultChromeTransparency, DefaultNormalTextSize, DefaultHeaderTextSize =
  0.84, 1.0, 16, 18

local ColorKeys = {
  'text',
  'textHover',
  'textPressed',
  'active',
  'activeHover',
  'activePressed',
  'disabled',
  'disabledHover',
  'disabledPressed',
  'link',
  'linkHover',
  'linkPressed',
  'journalLink',
  'journalLinkHover',
  'journalLinkPressed',
  'journalTopic',
  'journalTopicHover',
  'journalTopicPressed',
  'answer',
  'answerHover',
  'answerPressed',
  'header',
  'notify',
  'bigText',
  'bigTextHover',
  'bigTextPressed',
  'bigLink',
  'bigLinkHover',
  'bigLinkPressed',
  'bigAnswer',
  'bigAnswerHover',
  'bigAnswerPressed',
  'bigHeader',
  'bigNotify',
  'background',
  'focus',
  'health',
  'magic',
  'fatigue',
  'misc',
  'weaponFill',
  'magicFill',
  'positive',
  'negative',
  'count',
  'accent',
  'chromeBorder',
}

local ColorKeySet = {}
for index = 1, #ColorKeys do
  ColorKeySet[ColorKeys[index]] = true
end

---@type H3UI.AppearanceState
local state

---@return nil
local function invalidate() state.active = nil end

---@param value H3UI.SettingValue|openmw.util.Color
---@return string?
local function normalizeHex(value)
  if Type(value) ~= 'string' then return end

  local hex = value:gsub('^#', ''):lower()
  if not hex:match '^%x%x%x%x%x%x$' then return end

  return hex
end

---@param value H3UI.SettingValue
---@return number?
local function normalizeTransparency(value)
  if Type(value) ~= 'string' and Type(value) ~= 'number' then return end
  value = ToNumber(value)

  if not value then return end

  return MathMax(0, MathMin(1, value))
end

---@param value H3UI.SettingValue
---@return integer?
local function normalizeTextSize(value)
  if Type(value) ~= 'string' and Type(value) ~= 'number' then return end
  value = ToNumber(value)

  if not value then return end

  return MathFloor(MathMax(1, MathMin(100, value)) + 0.5)
end

---@param value H3UI.SettingValue
---@return H3UI.ChromeSource?
local function normalizeChromeSource(value)
  if value == 'auto' or value == 'theme' or value == 'h3ui' then return value end
end

---@param value? H3UI.TokenValue
---@return string?
local function colorHex(value)
  if Type(value) == 'string' then return normalizeHex(value) end

  if Type(value) == 'userdata' then
    ---@cast value H3UI.ColorLikeUserdata
    if value.__type.name == 'Misc::Color' then return normalizeHex(value:asHex()) end
  end
end

---@param theme H3UI.Theme
---@param key string
---@param fallback string
---@return string
local function themeColor(theme, key, fallback)
  local value, found = theme.findToken(StrFormat('color.%s', key))
  if not found then return fallback end

  local hex = colorHex(value)
  Assert(hex, StrFormat('H3 UI theme color token is invalid: color.%s', key))

  return hex
end

---@param theme H3UI.Theme
---@return H3UI.Palette
local function paletteFor(theme)
  local fallback = themeColor(theme, 'text', 'caa560')
  local palette = {}

  for index = 1, #ColorKeys do
    local key = ColorKeys[index]
    palette[key] = themeColor(theme, key, fallback)
  end

  return palette
end

---@return H3UI.Palette?
local function customPalette()
  local palette = {}
  for index = 1, #ColorKeys do
    local key = ColorKeys[index]
    local value = normalizeHex(state.customSection:get(key))

    if not value then return end
    palette[key] = value
  end

  return palette
end

---@param palette H3UI.Palette
---@return H3UI.Palette
local function writeCustomPalette(palette)
  for index = 1, #ColorKeys do
    local key = ColorKeys[index]

    if normalizeHex(state.customSection:get(key)) ~= palette[key] then
      state.customSection:set(key, palette[key])
    end
  end

  return palette
end

---@return H3UI.Palette
local function ensureCustomPalette()
  local existing = customPalette()

  if existing then return existing end

  return writeCustomPalette(paletteFor(state.themes.morrowind.theme))
end

---@param key string
---@return H3UI.SettingValue
local function settingValue(key) return state.section:get(key) end

---@return number
local function menuTransparency()
  return normalizeTransparency(settingValue(MenuTransparencyKey)) or DefaultMenuTransparency
end

---@return number
local function chromeTransparency()
  return normalizeTransparency(settingValue(ChromeTransparencyKey)) or DefaultChromeTransparency
end

---@return H3UI.ChromeSource
local function chromeSource()
  return normalizeChromeSource(settingValue(ChromeSourceKey)) or DefaultChromeSource
end

---@param value H3UI.SettingValue
---@return string?
local function normalizeMaterialFamily(value)
  if Type(value) ~= 'string' then return end

  local families = builtinChrome.materialFamilies()

  for index = 1, #families do
    if families[index] == value then return value end
  end
end

---@param family string
---@return string
local function firstMaterialOfFamily(family)
  local stems = builtinChrome.materialStems(family)

  if #stems == 0 then Error(StrFormat('H3 UI material family is empty: %s', ToString(family))) end

  return stems[1]
end

---@return string
local function chromeMaterialFamily()
  return normalizeMaterialFamily(settingValue(ChromeMaterialFamilyKey)) or DefaultMaterialFamily
end

---@param value H3UI.SettingValue
---@param family string
---@return string?
local function normalizeMaterial(value, family)
  if Type(value) ~= 'string' then return end
  if builtinChrome.variantFamily(value) == family then return value end
end

---@return string
local function chromeMaterial()
  local family = chromeMaterialFamily()
  return normalizeMaterial(settingValue(ChromeMaterialKey), family) or firstMaterialOfFamily(family)
end

---@param key string
---@param default number
---@return number
local function textSize(key, default) return normalizeTextSize(settingValue(key)) or default end

---@param id H3UI.SettingValue
---@return H3UI.ThemeEntry?
local function registeredTheme(id) return state.themes[id] end

---@param entry H3UI.ThemeEntry
---@return H3UI.ChromeSpec
local function selectedChrome(entry)
  local source = chromeSource()
  local themeChrome = entry.theme.chrome()

  if source == 'auto' then source = themeChrome.preferredSource or 'theme' end

  if source == 'theme' and entry.hasChrome then return themeChrome end

  if source == 'h3ui' then
    return builtinChrome.variant(chromeMaterial()) or builtinChrome.builtin()
  end

  return builtinChrome.builtin()
end

---@param id H3UI.SettingValue
---@return boolean
local function validPreset(id)
  if not id or id == CustomThemeId then return false end

  return registeredTheme(id) ~= nil
end

-- Optional installation-wide VFS hint, consulted only when no saved theme takes precedence.
-- H3UI does not ship this file; a present but broken override must fail loudly.
---@return string?
local function defaultHint()
  if not FileExists 'scripts/h3/ui/defaultTheme.lua' then return end

  local hint = require 'scripts.h3.ui.defaultTheme'
  Assert(Type(hint) == 'string', 'H3UI defaultTheme.lua must return a theme ID string')

  return registeredTheme(hint) and hint
end

---@return string
local function resolveDefault()
  local hint = defaultHint()
  if hint then return hint end

  if ContentFiles.has 'StarwindRemasteredV1.15.esm' or ContentFiles.has 'Star_Data.omwaddon' then
    return 'starwind'
  end

  return 'morrowind'
end

---@param id string
---@return nil
local function writePreset(id)
  local entry = registeredTheme(id)
  Assert(entry, StrFormat('Unknown H3 UI theme preset: %s', ToString(id)))

  local palette = paletteFor(entry.theme)
  state.lastPresetId = id

  if settingValue 'theme' ~= id then state.section:set('theme', id) end

  for index = 1, #ColorKeys do
    local key = ColorKeys[index]
    if normalizeHex(settingValue(key)) ~= palette[key] then state.section:set(key, palette[key]) end
  end

  invalidate()
end

---@return nil
local function canonicalizeStorage()
  local raw = state.section:asTable()

  local storedTransparency = normalizeTransparency(raw[MenuTransparencyKey])
    or DefaultMenuTransparency
  if storedTransparency ~= raw[MenuTransparencyKey] then
    state.section:set(MenuTransparencyKey, storedTransparency)
  end

  local storedChromeTransparency = normalizeTransparency(raw[ChromeTransparencyKey])
    or DefaultChromeTransparency
  if storedChromeTransparency ~= raw[ChromeTransparencyKey] then
    state.section:set(ChromeTransparencyKey, storedChromeTransparency)
  end

  local storedNormalTextSize = normalizeTextSize(raw[NormalTextSizeKey]) or DefaultNormalTextSize
  if storedNormalTextSize ~= raw[NormalTextSizeKey] then
    state.section:set(NormalTextSizeKey, storedNormalTextSize)
  end

  local storedHeaderTextSize = normalizeTextSize(raw[HeaderTextSizeKey]) or DefaultHeaderTextSize
  if storedHeaderTextSize ~= raw[HeaderTextSizeKey] then
    state.section:set(HeaderTextSizeKey, storedHeaderTextSize)
  end

  local storedChromeSource = normalizeChromeSource(raw[ChromeSourceKey]) or DefaultChromeSource
  if storedChromeSource ~= raw[ChromeSourceKey] then
    state.section:set(ChromeSourceKey, storedChromeSource)
  end

  local storedMaterialFamily = normalizeMaterialFamily(raw[ChromeMaterialFamilyKey])
    or DefaultMaterialFamily
  if storedMaterialFamily ~= raw[ChromeMaterialFamilyKey] then
    state.section:set(ChromeMaterialFamilyKey, storedMaterialFamily)
  end

  local storedMaterial = normalizeMaterial(raw[ChromeMaterialKey], storedMaterialFamily)
    or firstMaterialOfFamily(storedMaterialFamily)
  if storedMaterial ~= raw[ChromeMaterialKey] then
    state.section:set(ChromeMaterialKey, storedMaterial)
  end

  local explicitTheme = raw.theme
  if validPreset(explicitTheme) then return writePreset(explicitTheme) end

  ensureCustomPalette()
  if explicitTheme == CustomThemeId then return invalidate() end

  writePreset(resolveDefault())
end

---@return nil
local function initializeSettings()
  if state.initialized then return end
  state.initialized = true

  local explicitTheme = settingValue 'theme'
  if Type(explicitTheme) == 'string' and validPreset(explicitTheme) then state.lastPresetId = explicitTheme end
  invalidate()

  async:newUnsavableSimulationTimer(0, canonicalizeStorage)
end

---@return H3UI.ThemeEntry
local function activeEntry()
  local selected = settingValue 'theme'

  if selected == CustomThemeId then
    local baseId = state.lastPresetId or resolveDefault()
    return registeredTheme(baseId) or state.themes.morrowind
  end

  return registeredTheme(selected) or registeredTheme(resolveDefault()) or state.themes.morrowind
end

---@param entry H3UI.ThemeEntry
---@param section? openmw.storage.MutableStorageSection
---@return H3UI.Palette
local function configuredPalette(entry, section)
  local canonical = paletteFor(entry.theme)
  local palette = {}

  section = section or state.section

  for index = 1, #ColorKeys do
    local key = ColorKeys[index]
    palette[key] = normalizeHex(section:get(key)) or canonical[key]
  end

  return palette
end

---@return nil
local function restoreCustomPalette()
  local entry = registeredTheme(state.lastPresetId or resolveDefault()) or state.themes.morrowind
  local palette = ensureCustomPalette()

  for index = 1, #ColorKeys do
    local key = ColorKeys[index]

    if normalizeHex(state.section:get(key)) ~= palette[key] then
      state.section:set(key, palette[key])
    end
  end

  state.lastPresetId = entry.id

  invalidate()
end

---@return string
local function currentThemeId()
  initializeSettings()
  local selected = settingValue 'theme'

  if selected == CustomThemeId then return CustomThemeId end
  if Type(selected) == 'string' and registeredTheme(selected) then return selected end

  return resolveDefault()
end

---@return H3UI.Palette
local function morrowindPalette() return paletteFor(state.themes.morrowind.theme) end

---@return H3UI.Theme
local function activeTheme()
  Assert(state, 'H3 UI appearance is not initialized')

  initializeSettings()
  if state.active then return state.active end

  local entry = activeEntry()
  local palette = settingValue 'theme' == CustomThemeId
      and configuredPalette(entry, state.customSection)
    or configuredPalette(entry)
  local transparency = menuTransparency()
  local chromeAlpha = chromeTransparency()
  local normalTextSize = textSize(NormalTextSizeKey, DefaultNormalTextSize)
  local headerTextSize = textSize(HeaderTextSizeKey, DefaultHeaderTextSize)
  local chrome = selectedChrome(entry)

  local tokens = {
    color = {},
    textSize = { normal = normalTextSize, header = headerTextSize },
    transparency = { menu = transparency, chrome = chromeAlpha },
  }

  for index = 1, #ColorKeys do
    local key = ColorKeys[index]
    tokens.color[key] = ColorHex(palette[key])
  end

  state.active = themeModule.new(
    { name = entry.name, tokens = tokens, chrome = chrome },
    state.registry,
    entry.theme
  )

  return state.active
end

---@overload fun(path: 'color.accent'|'color.active'|'color.background'|'color.chromeBorder'|'color.count'|'color.header'|'color.text'): openmw.util.Color
---@overload fun(path: 'border.normal'|'spacing.padding'|'spacing.sm'|'textSize.header'|'textSize.normal'|'transparency.chrome'|'transparency.menu'): number
---@overload fun(path: 'texture.white'): openmw.ui.TextureResource
---@param path string
---@return H3UI.TokenValue
local function token(path) return activeTheme().token(path) end

---@overload fun(path: 'caption'|'frame.button'|'frame.thick'|'frame.thin'): H3UI.ChromeFrame
---@overload fun(path: 'pin.down'|'pin.up'): H3UI.ChromeFrame
---@overload fun(path: 'scroll.left'|'scroll.right'|'scroll.up'|'scroll.down'): H3UI.TextureRegion
---@param path string
---@return H3UI.ChromeResource
local function chrome(path) return builtinChrome.resolve(activeTheme(), path) end

---@param id string
---@param expectedTheme string
---@return nil
local function scheduleThemeUpdate(id, expectedTheme)
  state.pendingTheme = { id = id, expectedTheme = expectedTheme }
  if state.themeUpdateScheduled then return end

  state.themeUpdateScheduled = true
  async:newUnsavableSimulationTimer(0,
    ---@return nil
    function()
    state.themeUpdateScheduled = false
    local pending = state.pendingTheme
    state.pendingTheme = nil
    if not pending or settingValue 'theme' ~= pending.expectedTheme then return end

    if pending.id == CustomThemeId then
      state.section:set('theme', CustomThemeId)
      restoreCustomPalette()
    elseif validPreset(pending.id) then
      writePreset(pending.id)
    end
  end)
end

---@param _ openmw.storage.StorageSection
---@param key string
---@return nil
local function onStorageChanged(_, key)
  invalidate()

  if key == 'theme' then
    local selected = settingValue 'theme'
    if Type(selected) == 'string' and validPreset(selected) then scheduleThemeUpdate(selected, selected) end
  end
end

---@param id string
---@param spec H3UI.ThemeSpec
---@param compiled? H3UI.Theme
---@return nil
local function registerThemeEntry(id, spec, compiled)
  Assert(Type(id) == 'string' and id ~= '', 'H3 UI theme id must be a non-empty string')
  local existingTheme = state.themes[id]
  if existingTheme then Error(StrFormat('H3 UI theme id is already registered: %s', id)) end

  Assert(Type(spec) == 'table', 'H3 UI theme specification must be a table')
  Assert(Type(spec.name) == 'string' and spec.name ~= '', 'H3 UI theme requires a name')

  local theme = compiled
  if not theme then
    local parent = spec.extends

    if Type(parent) == 'string' then
      local parentEntry = state.themes[parent]

      parent = parentEntry and parentEntry.theme
      if not parent then Error(StrFormat('Unknown H3 UI theme parent: %s', spec.extends)) end
    end

    local themeSpec = {}
    for key, value in Next, spec do
      if key ~= 'id' and key ~= 'extends' then themeSpec[key] = value end
    end

    theme = themeModule.new(themeSpec, state.registry, parent or state.themes.morrowind.theme)
  end

  state.themes[id] = {
    id = id,
    name = spec.name,
    description = spec.description,
    author = spec.author,
    hasChrome = theme.hasChrome(),
    theme = theme,
  }

  invalidate()
end

---@param registry H3UI.Registry
---@param builtins H3UI.BuiltinTheme[]
---@return nil
local function initialize(registry, builtins)
  Assert(not state, 'H3 UI appearance is already initialized')

  state = {
    registry = registry,
    section = PlayerSection(SectionName),
    customSection = PlayerSection(CustomSectionName),
    themes = {},
    initialized = false,
    themeUpdateScheduled = false,
  }

  for index = 1, #builtins do
    local builtin = builtins[index]
    registerThemeEntry(builtin.id, builtin.spec, builtin.theme)
  end

  state.section:subscribe(async:callback(onStorageChanged))
  state.customSection:subscribe(async:callback(invalidate))
end

---@param left H3UI.ThemeEntrySummary
---@param right H3UI.ThemeEntrySummary
---@return boolean
local function compareThemeEntries(left, right) return left.name < right.name end

---@return H3UI.ThemeEntrySummary[]
local function themeEntries()
  local result = {}

  for id, entry in Next, state.themes do
    result[#result + 1] = {
      id = id,
      name = entry.name,
      description = entry.description,
      author = entry.author,
    }
  end

  TableSort(result, compareThemeEntries)

  return result
end

---@param family string
---@param set? fun(value: string)
---@return nil
local function selectMaterialFamily(family, set)
  local stems = builtinChrome.materialStems(family)

  if #stems == 0 then Error(StrFormat('Unknown H3 UI material family: %s', ToString(family))) end

  if set then
    set(family)
  else
    state.section:set(ChromeMaterialFamilyKey, family)
  end

  state.section:set(ChromeMaterialKey, stems[1])
  invalidate()
end

---@param id string
---@param set? fun(value: string)
---@return nil
local function selectTheme(id, set)
  if id ~= CustomThemeId and not validPreset(id) then
    Error(StrFormat('Unknown H3 UI theme: %s', ToString(id)))
  end

  if set then
    set(id)
  else
    state.section:set('theme', id)
  end

  if validPreset(id) then
    writePreset(id)
  else
    restoreCustomPalette()
  end
end

---@param key string
---@param value string
---@param set? fun(value: string)
---@return nil
local function setColor(key, value, set)
  if not ColorKeySet[key] then Error(StrFormat('Unknown H3 UI color: %s', ToString(key))) end

  local hex = normalizeHex(value)
  Assert(hex, 'H3 UI colors must be six-digit hexadecimal strings')

  local palette = ensureCustomPalette()
  palette[key] = hex

  writeCustomPalette(palette)

  if set then set(hex) end
  state.section:set('theme', CustomThemeId)

  restoreCustomPalette()
end

---@return nil
local function reset()
  writePreset 'morrowind'
  state.section:set(MenuTransparencyKey, DefaultMenuTransparency)
  state.section:set(ChromeTransparencyKey, DefaultChromeTransparency)
  state.section:set(NormalTextSizeKey, DefaultNormalTextSize)
  state.section:set(HeaderTextSizeKey, DefaultHeaderTextSize)
  state.section:set(ChromeSourceKey, DefaultChromeSource)
  state.section:set(ChromeMaterialFamilyKey, DefaultMaterialFamily)
  state.section:set(ChromeMaterialKey, DefaultMaterial)
end

---@param spec H3UI.ThemeRegistration
---@return nil
local function registerTheme(spec)
  Assert(state, 'H3 UI appearance is not initialized')
  registerThemeEntry(spec.id, spec)
end

---@param value string
---@return openmw.util.Color
local function color(value)
  local hex = normalizeHex(value)
  Assert(hex, 'H3 UI colors must be six-digit hexadecimal strings')
  return ColorHex(hex)
end

return {
  colorKeys = ColorKeys,
  customThemeId = CustomThemeId,
  defaultMenuTransparency = DefaultMenuTransparency,
  defaultChromeTransparency = DefaultChromeTransparency,
  defaultNormalTextSize = DefaultNormalTextSize,
  defaultHeaderTextSize = DefaultHeaderTextSize,
  defaultChromeSource = DefaultChromeSource,
  initialize = initialize,
  activeTheme = activeTheme,
  current = activeTheme,
  token = token,
  chrome = chrome,
  registerTheme = registerTheme,
  themeEntries = themeEntries,
  currentThemeId = currentThemeId,
  chromeSource = chromeSource,
  chromeTransparency = chromeTransparency,
  normalizeChromeSource = normalizeChromeSource,
  defaultMaterialFamily = DefaultMaterialFamily,
  defaultMaterial = DefaultMaterial,
  chromeMaterialFamily = chromeMaterialFamily,
  chromeMaterial = chromeMaterial,
  normalizeMaterialFamily = normalizeMaterialFamily,
  selectMaterialFamily = selectMaterialFamily,
  materialFamilies = builtinChrome.materialFamilies,
  materialStems = builtinChrome.materialStems,
  morrowindPalette = morrowindPalette,
  selectTheme = selectTheme,
  setColor = setColor,
  reset = reset,
  color = color,
  normalizeHex = normalizeHex,
}
