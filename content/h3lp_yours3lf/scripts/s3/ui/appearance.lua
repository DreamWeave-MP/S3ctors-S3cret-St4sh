---@omw-context menu|player

local async = require 'openmw.async'
local core = require 'openmw.core'
local storage = require 'openmw.storage'
local util = require 'openmw.util'

local themeModule = require 'scripts.s3.ui.theme'

local sectionName = 'SettingsPlayerH3UI'
local customSectionName = 'SettingsPlayerH3UICustom'
local customThemeId = 'custom'
local menuTransparencyKey = 'menuTransparency'
local normalTextSizeKey = 'textSizeNormal'
local headerTextSizeKey = 'textSizeHeader'
local defaultMenuTransparency = 0.84
local defaultNormalTextSize = 16
local defaultHeaderTextSize = 18
local StrFormat = string.format

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
}

local colorKeySet = {}
for index = 1, #colorKeys do
  colorKeySet[colorKeys[index]] = true
end

local state

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

local function colorHex(value)
  if type(value) == 'string' then return normalizeHex(value) end
  if type(value) == 'userdata' then return normalizeHex(value:asHex()) end
  return nil
end

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

local function paletteFingerprint(palette)
  local result = {}
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    result[#result + 1] = key .. '=' .. palette[key]
  end
  return table.concat(result, ';')
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

local function ensureCustomPalette(source)
  local existing = customPalette()
  if existing then return existing end

  local fallback = paletteFor(state.themes.morrowind.theme)
  local palette = {}
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    palette[key] = normalizeHex(source and source[key]) or fallback[key]
  end
  return writeCustomPalette(palette)
end

local function rawStorageValues() return state.section:asTable() end

local function settingValue(key) return state.section:get(key) end

local function menuTransparency()
  return normalizeTransparency(settingValue(menuTransparencyKey)) or defaultMenuTransparency
end

local function textSize(key, default) return normalizeTextSize(settingValue(key)) or default end

local function registeredTheme(id) return state.themes[id] end

local function validPreset(id)
  return id ~= nil and id ~= customThemeId and registeredTheme(id) ~= nil
end

local function defaultHint()
  local ok, hint = pcall(require, 'scripts.s3.ui.defaultTheme')
  if ok and type(hint) == 'string' and registeredTheme(hint) then return hint end
  return nil
end

local function detectedDefault()
  local contentFiles = core.contentFiles
  if
    contentFiles
    and (contentFiles.has 'StarwindRemasteredV1.15.esm' or contentFiles.has 'Star_Data.omwaddon')
  then
    return 'starwind'
  end
  return 'morrowind'
end

local function resolveDefault() return defaultHint() or detectedDefault() end

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
  state.active = nil
  state.activeFingerprint = nil
  state.generation = state.generation + 1
  return true
end

local function initializeSettings()
  if state.initialized then return end
  state.initialized = true

  local raw = rawStorageValues()
  local storedTransparency = normalizeTransparency(raw[menuTransparencyKey])
    or defaultMenuTransparency
  if storedTransparency ~= raw[menuTransparencyKey] then
    state.section:set(menuTransparencyKey, storedTransparency)
  end
  local storedNormalTextSize = normalizeTextSize(raw[normalTextSizeKey]) or defaultNormalTextSize
  if storedNormalTextSize ~= raw[normalTextSizeKey] then
    state.section:set(normalTextSizeKey, storedNormalTextSize)
  end
  local storedHeaderTextSize = normalizeTextSize(raw[headerTextSizeKey]) or defaultHeaderTextSize
  if storedHeaderTextSize ~= raw[headerTextSizeKey] then
    state.section:set(headerTextSizeKey, storedHeaderTextSize)
  end
  local explicitTheme = raw.theme
  if validPreset(explicitTheme) then
    writePreset(explicitTheme)
    return
  end

  for index = 1, #colorKeys do
    if raw[colorKeys[index]] ~= nil then
      ensureCustomPalette(raw)
      state.section:set('theme', customThemeId)
      return
    end
  end

  local defaultId = resolveDefault()
  local defaultPalette = paletteFor(registeredTheme(defaultId).theme)
  ensureCustomPalette()
  state.section:set('theme', defaultId)
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    if raw[key] == nil then state.section:set(key, defaultPalette[key]) end
  end
  state.active = nil
  state.activeFingerprint = nil
  state.generation = state.generation + 1
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
  state.active = nil
  state.activeFingerprint = nil
  state.generation = state.generation + 1
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
  initializeSettings()

  local entry = activeEntry()
  local palette = settingValue 'theme' == customThemeId
      and configuredPalette(entry, state.customSection)
    or configuredPalette(entry)
  local transparency = menuTransparency()
  local normalTextSize = textSize(normalTextSizeKey, defaultNormalTextSize)
  local headerTextSize = textSize(headerTextSizeKey, defaultHeaderTextSize)
  local fingerprint = StrFormat(
    '%s:%s;menuTransparency=%s;textSizeNormal=%s;textSizeHeader=%s',
    entry.id,
    paletteFingerprint(palette),
    transparency,
    normalTextSize,
    headerTextSize
  )
  if state.active and state.activeFingerprint == fingerprint then return state.active end

  local tokens = {
    color = {},
    textSize = { normal = normalTextSize, header = headerTextSize },
    transparency = { menu = transparency },
  }
  for index = 1, #colorKeys do
    local key = colorKeys[index]
    tokens.color[key] = util.color.hex(palette[key])
  end

  state.active =
    themeModule.new({ name = entry.name, tokens = tokens }, state.registry, entry.theme)
  state.activeFingerprint = fingerprint
  return state.active
end

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
  state.active = nil
  state.activeFingerprint = nil
  state.generation = state.generation + 1

  if key == 'theme' then
    local selected = settingValue 'theme'
    if validPreset(selected) then scheduleThemeUpdate(selected, selected) end
  end
end

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
    theme = theme,
  }
  state.generation = state.generation + 1
end

local function initialize(registry, builtins)
  if state then return end
  state = {
    registry = registry,
    section = storage.playerSection(sectionName),
    customSection = storage.playerSection(customSectionName),
    themes = {},
    generation = 0,
    initialized = false,
    themeUpdateScheduled = false,
  }

  for index = 1, #builtins do
    local builtin = builtins[index]
    registerThemeEntry(builtin.id, builtin.spec, builtin.theme)
  end

  state.section:subscribe(async:callback(onStorageChanged))
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
  state.active = nil
  state.activeFingerprint = nil
  state.generation = state.generation + 1
end

local function reset()
  local result = writePreset 'morrowind'
  if result then
    state.section:set(menuTransparencyKey, defaultMenuTransparency)
    state.section:set(normalTextSizeKey, defaultNormalTextSize)
    state.section:set(headerTextSizeKey, defaultHeaderTextSize)
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
  defaultNormalTextSize = defaultNormalTextSize,
  defaultHeaderTextSize = defaultHeaderTextSize,
  initialize = initialize,
  activeTheme = activeTheme,
  registerTheme = registerTheme,
  themeEntries = themeEntries,
  currentThemeId = currentThemeId,
  morrowindPalette = morrowindPalette,
  selectTheme = selectTheme,
  setColor = setColor,
  reset = reset,
  color = color,
  normalizeHex = normalizeHex,
}
