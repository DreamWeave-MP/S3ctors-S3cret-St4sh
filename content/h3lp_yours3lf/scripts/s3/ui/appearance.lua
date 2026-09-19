---@omw-context menu|player

local async = require 'openmw.async'
local core = require 'openmw.core'
local storage = require 'openmw.storage'
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local builtinChrome = require 'scripts.s3.ui.chrome'
local themeModule = require 'scripts.s3.ui.theme'

local sectionName = 'SettingsPlayerH3UI'
local customSectionName = 'SettingsPlayerH3UICustom'
local customThemeId = 'custom'
local menuTransparencyKey = 'menuTransparency'
local chromeTransparencyKey = 'chromeTransparency'
local normalTextSizeKey = 'textSizeNormal'
local headerTextSizeKey = 'textSizeHeader'
local chromeSourceKey = 'chromeSource'
local defaultChromeSource = 'auto'
local chromeMaterialFamilyKey = 'chromeMaterialFamily'
local chromeMaterialKey = 'chromeMaterial'
local defaultMaterial = 'coral_fort_wall_02'
local defaultMaterialFamily = builtinChrome.variantFamily(defaultMaterial)
local defaultMenuTransparency = 0.84
local defaultChromeTransparency = 1.0
local defaultNormalTextSize = 16
local defaultHeaderTextSize = 18

local colorKeys = {
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

local colorKeySet = {}
for index = 1, #colorKeys do
  colorKeySet[colorKeys[index]] = true
end

local state

local function ensureInitialized()
  if not state then require 'scripts.s3.ui' end
end

local function invalidate()
  state.active = nil
end

local function normalizeHex(value)
  if type(value) ~= 'string' then return nil end
  local hex = value:gsub('^#', ''):lower()
  if not hex:match '^%x%x%x%x%x%x$' then return nil end
  return hex
end

local function normalizeTransparency(value)
  value = tonumber(value)
  if not value then return nil end
  return math.max(0, math.min(1, value))
end

local function normalizeTextSize(value)
  value = tonumber(value)
  if not value then return nil end
  return math.floor(math.max(1, math.min(100, value)) + 0.5)
end

local function normalizeChromeSource(value)
  if value == 'auto' or value == 'theme' or value == 'h3ui' then return value end
end

local function colorHex(value)
  if type(value) == 'string' then return normalizeHex(value) end
  if type(value) == 'userdata' then return normalizeHex(value:asHex()) end
end

-- Third-party themes may omit palette tokens; token lookup errors must preserve the fallback.
local function themeColor(theme, key, fallback)
  local ok, value = pcall(theme.token, 'color.' .. key)
  return ok and (colorHex(value) or fallback) or fallback
end

local function paletteFor(theme)
  local fallback = themeColor(theme, 'text', 'caa560')
  local palette = {}
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    palette[key] = themeColor(theme, key, fallback)
  end
  return palette
end

local function customPalette()
  local palette = {}
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    local value = normalizeHex(state.customSection:get(key))
    if not value then return nil end
    palette[key] = value
  end
  return palette
end

local function writeCustomPalette(palette)
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    if normalizeHex(state.customSection:get(key)) ~= palette[key] then
      state.customSection:set(key, palette[key])
    end
  end
  return palette
end

local function ensureCustomPalette()
  local existing = customPalette()
  if existing then return existing end
  return writeCustomPalette(paletteFor(state.themes.morrowind.theme))
end

local function rawStorageValues() return state.section:asTable() end

local function settingValue(key) return state.section:get(key) end

local function menuTransparency()
  return normalizeTransparency(settingValue(menuTransparencyKey)) or defaultMenuTransparency
end

local function chromeTransparency()
  return normalizeTransparency(settingValue(chromeTransparencyKey)) or defaultChromeTransparency
end

local function chromeSource()
  return normalizeChromeSource(settingValue(chromeSourceKey)) or defaultChromeSource
end

local function normalizeMaterialFamily(value)
  if type(value) ~= 'string' then return end
  local families = builtinChrome.materialFamilies()
  for index = 1, #families do
    if families[index] == value then return value end
  end
end

local function firstMaterialOfFamily(family)
  local stems = builtinChrome.materialStems(family)
  assert(#stems > 0, 'H3 UI material family is empty: ' .. tostring(family))
  return stems[1]
end

local function chromeMaterialFamily()
  return normalizeMaterialFamily(settingValue(chromeMaterialFamilyKey)) or defaultMaterialFamily
end

local function normalizeMaterial(value, family)
  if type(value) ~= 'string' then return end
  if builtinChrome.variantFamily(value) == family then return value end
end

local function chromeMaterial()
  local family = chromeMaterialFamily()
  return normalizeMaterial(settingValue(chromeMaterialKey), family) or firstMaterialOfFamily(family)
end

local function textSize(key, default) return normalizeTextSize(settingValue(key)) or default end

local function registeredTheme(id) return state.themes[id] end

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

local function validPreset(id)
  return id ~= nil and id ~= customThemeId and registeredTheme(id) ~= nil
end

-- Optional installation-wide VFS hint, consulted only when no saved theme takes precedence.
-- H3UI does not ship this file; a present but broken override must fail loudly.
local function defaultHint()
  if not vfs.fileExists 'scripts/s3/ui/defaultTheme.lua' then return end
  local hint = require 'scripts.s3.ui.defaultTheme'
  assert(type(hint) == 'string', 'H3UI defaultTheme.lua must return a theme ID string')
  return registeredTheme(hint) and hint or nil
end

local function resolveDefault()
  local hint = defaultHint()
  if hint then return hint end
  local contentFiles = core.contentFiles
  if
    contentFiles
    and (contentFiles.has 'StarwindRemasteredV1.15.esm' or contentFiles.has 'Star_Data.omwaddon')
  then
    return 'starwind'
  end
  return 'morrowind'
end

local function writePreset(id)
  local entry = registeredTheme(id)
  if not entry then return false end

  local palette = paletteFor(entry.theme)
  state.lastPresetId = id

  if settingValue 'theme' ~= id then state.section:set('theme', id) end

  for index = 1, #colorKeys do
    local key = colorKeys[index]
    if normalizeHex(settingValue(key)) ~= palette[key] then state.section:set(key, palette[key]) end
  end
  invalidate()
  return true
end

local function canonicalizeStorage()
  local raw = rawStorageValues()
  local storedTransparency = normalizeTransparency(raw[menuTransparencyKey])
    or defaultMenuTransparency
  if storedTransparency ~= raw[menuTransparencyKey] then
    state.section:set(menuTransparencyKey, storedTransparency)
  end
  local storedChromeTransparency = normalizeTransparency(raw[chromeTransparencyKey])
    or defaultChromeTransparency
  if storedChromeTransparency ~= raw[chromeTransparencyKey] then
    state.section:set(chromeTransparencyKey, storedChromeTransparency)
  end
  local storedNormalTextSize = normalizeTextSize(raw[normalTextSizeKey]) or defaultNormalTextSize
  if storedNormalTextSize ~= raw[normalTextSizeKey] then
    state.section:set(normalTextSizeKey, storedNormalTextSize)
  end
  local storedHeaderTextSize = normalizeTextSize(raw[headerTextSizeKey]) or defaultHeaderTextSize
  if storedHeaderTextSize ~= raw[headerTextSizeKey] then
    state.section:set(headerTextSizeKey, storedHeaderTextSize)
  end
  local storedChromeSource = normalizeChromeSource(raw[chromeSourceKey]) or defaultChromeSource
  if storedChromeSource ~= raw[chromeSourceKey] then
    state.section:set(chromeSourceKey, storedChromeSource)
  end
  local storedMaterialFamily = normalizeMaterialFamily(raw[chromeMaterialFamilyKey])
    or defaultMaterialFamily
  if storedMaterialFamily ~= raw[chromeMaterialFamilyKey] then
    state.section:set(chromeMaterialFamilyKey, storedMaterialFamily)
  end
  local storedMaterial = normalizeMaterial(raw[chromeMaterialKey], storedMaterialFamily)
    or firstMaterialOfFamily(storedMaterialFamily)
  if storedMaterial ~= raw[chromeMaterialKey] then
    state.section:set(chromeMaterialKey, storedMaterial)
  end
  local explicitTheme = raw.theme
  if validPreset(explicitTheme) then
    writePreset(explicitTheme)
    return
  end

  ensureCustomPalette()
  if explicitTheme == customThemeId then
    invalidate()
    return
  end

  writePreset(resolveDefault())
end

local function initializeSettings()
  if state.initialized then return end
  state.initialized = true

  local explicitTheme = settingValue 'theme'
  if validPreset(explicitTheme) then state.lastPresetId = explicitTheme end
  invalidate()

  async:newUnsavableSimulationTimer(0, canonicalizeStorage)
end

local function activeEntry()
  local selected = settingValue 'theme'
  if selected == customThemeId then
    local baseId = state.lastPresetId or resolveDefault()
    return registeredTheme(baseId) or state.themes.morrowind
  end
  return registeredTheme(selected) or registeredTheme(resolveDefault()) or state.themes.morrowind
end

local function configuredPalette(entry, section)
  local canonical = paletteFor(entry.theme)
  local palette = {}
  section = section or state.section
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    palette[key] = normalizeHex(section:get(key)) or canonical[key]
  end
  return palette
end

local function restoreCustomPalette()
  local entry = registeredTheme(state.lastPresetId or resolveDefault()) or state.themes.morrowind
  local palette = ensureCustomPalette()
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    if normalizeHex(state.section:get(key)) ~= palette[key] then
      state.section:set(key, palette[key])
    end
  end
  state.lastPresetId = entry.id
  invalidate()
end

local function currentThemeId()
  initializeSettings()
  local selected = settingValue 'theme'
  if selected == customThemeId then return customThemeId end
  if registeredTheme(selected) then return selected end
  return resolveDefault()
end

local function morrowindPalette() return paletteFor(state.themes.morrowind.theme) end

local function activeTheme()
  ensureInitialized()
  initializeSettings()
  if state.active then return state.active end

  local entry = activeEntry()
  local palette = settingValue 'theme' == customThemeId
      and configuredPalette(entry, state.customSection)
    or configuredPalette(entry)
  local transparency = menuTransparency()
  local chromeAlpha = chromeTransparency()
  local normalTextSize = textSize(normalTextSizeKey, defaultNormalTextSize)
  local headerTextSize = textSize(headerTextSizeKey, defaultHeaderTextSize)
  local chrome = selectedChrome(entry)

  local tokens = {
    color = {},
    textSize = { normal = normalTextSize, header = headerTextSize },
    transparency = { menu = transparency, chrome = chromeAlpha },
  }
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    tokens.color[key] = util.color.hex(palette[key])
  end

  state.active = themeModule.new(
    { name = entry.name, tokens = tokens, chrome = chrome },
    state.registry,
    entry.theme
  )
  return state.active
end

local function token(path) return activeTheme().token(path) end

local function chrome(path) return builtinChrome.resolve(activeTheme(), path) end

local function scheduleThemeUpdate(id, expectedTheme)
  state.pendingTheme = { id = id, expectedTheme = expectedTheme }
  if state.themeUpdateScheduled then return end

  state.themeUpdateScheduled = true
  async:newUnsavableSimulationTimer(0, function()
    state.themeUpdateScheduled = false
    local pending = state.pendingTheme
    state.pendingTheme = nil
    if not pending or settingValue 'theme' ~= pending.expectedTheme then return end

    if pending.id == customThemeId then
      state.section:set('theme', customThemeId)
      restoreCustomPalette()
    elseif validPreset(pending.id) then
      writePreset(pending.id)
    end
  end)
end

local function onStorageChanged(_, key)
  invalidate()

  if key == 'theme' then
    local selected = settingValue 'theme'
    if validPreset(selected) then scheduleThemeUpdate(selected, selected) end
  end
end

local function onCustomStorageChanged() invalidate() end

local function registerThemeEntry(id, spec, compiled)
  assert(type(id) == 'string' and id ~= '', 'H3 UI theme id must be a non-empty string')
  assert(state.themes[id] == nil, 'H3 UI theme id is already registered: ' .. id)
  assert(type(spec) == 'table', 'H3 UI theme specification must be a table')
  assert(type(spec.name) == 'string' and spec.name ~= '', 'H3 UI theme requires a name')

  local theme = compiled
  if not theme then
    local parent = spec.extends
    if type(parent) == 'string' then
      parent = state.themes[parent] and state.themes[parent].theme
      assert(parent, 'Unknown H3 UI theme parent: ' .. spec.extends)
    end
    local themeSpec = {}
    for key, value in next, spec do
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

local function initialize(registry, builtins)
  if state then return end
  state = {
    registry = registry,
    section = storage.playerSection(sectionName),
    customSection = storage.playerSection(customSectionName),
    themes = {},
    initialized = false,
    themeUpdateScheduled = false,
  }

  for index = 1, #builtins do
    local builtin = builtins[index]
    registerThemeEntry(builtin.id, builtin.spec, builtin.theme)
  end

  state.section:subscribe(async:callback(onStorageChanged))
  state.customSection:subscribe(async:callback(onCustomStorageChanged))
end

local function themeEntries()
  local result = {}
  for id, entry in next, state.themes do
    result[#result + 1] = {
      id = id,
      name = entry.name,
      description = entry.description,
      author = entry.author,
    }
  end
  table.sort(result, function(left, right) return left.name < right.name end)
  return result
end

local function selectMaterialFamily(family, set)
  local stems = builtinChrome.materialStems(family)
  assert(#stems > 0, 'Unknown H3 UI material family: ' .. tostring(family))
  if set then
    set(family)
  else
    state.section:set(chromeMaterialFamilyKey, family)
  end
  state.section:set(chromeMaterialKey, stems[1])
  invalidate()
end

local function selectTheme(id, set)
  assert(id == customThemeId or validPreset(id), 'Unknown H3 UI theme: ' .. tostring(id))
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

local function setColor(key, value, set)
  assert(colorKeySet[key], 'Unknown H3 UI color: ' .. tostring(key))
  local hex = normalizeHex(value)
  assert(hex, 'H3 UI colors must be six-digit hexadecimal strings')
  local palette = ensureCustomPalette()
  palette[key] = hex
  writeCustomPalette(palette)
  if set then
    set(hex)
  else
    state.section:set('theme', customThemeId)
    restoreCustomPalette()
  end
  if set then
    state.section:set('theme', customThemeId)
    restoreCustomPalette()
  end
  invalidate()
end

local function reset()
  local result = writePreset 'morrowind'
  if result then
    state.section:set(menuTransparencyKey, defaultMenuTransparency)
    state.section:set(chromeTransparencyKey, defaultChromeTransparency)
    state.section:set(normalTextSizeKey, defaultNormalTextSize)
    state.section:set(headerTextSizeKey, defaultHeaderTextSize)
    state.section:set(chromeSourceKey, defaultChromeSource)
    state.section:set(chromeMaterialFamilyKey, defaultMaterialFamily)
    state.section:set(chromeMaterialKey, defaultMaterial)
  end
  return result
end

---@param spec H3UI.ThemeSpec
---@return nil
local function registerTheme(spec)
  assert(state, 'H3 UI appearance is not initialized')
  registerThemeEntry(spec.id, spec)
end

---@param value string
---@return openmw.util.Color
local function color(value) return util.color.hex(normalizeHex(value) or '000000') end

return {
  colorKeys = colorKeys,
  customThemeId = customThemeId,
  defaultMenuTransparency = defaultMenuTransparency,
  defaultChromeTransparency = defaultChromeTransparency,
  defaultNormalTextSize = defaultNormalTextSize,
  defaultHeaderTextSize = defaultHeaderTextSize,
  defaultChromeSource = defaultChromeSource,
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
  defaultMaterialFamily = defaultMaterialFamily,
  defaultMaterial = defaultMaterial,
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
