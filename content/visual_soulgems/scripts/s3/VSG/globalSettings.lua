---@omw-context global

local async = require 'openmw.async'
local core = require 'openmw.core'
local interfaces = require 'openmw.interfaces'
local recordData = require 'scripts.s3.VSG.records'
local storage = require 'openmw.storage'

local soulGemVariants = {}
for i = 1, #recordData.variants do
  soulGemVariants[i] = recordData.variants[i].setting
end

local variantCount = #soulGemVariants
local variantSettingKeys = {}
for i = 1, variantCount do
  variantSettingKeys[recordData.variants[i].settingKey] = i
end

local settings = storage.globalSection 'SettingsGlobalVisualSoulGems'
local legacySelectedVariant = settings:get 'SoulGemVariant'
local settingsOptions = {
  {
    key = 'SoulGemRandomize',
    renderer = 'checkbox',
    name = 'SoulGemRandomizeName',
    description = 'SoulGemRandomizeDesc',
    default = true,
  },
}

for i = 1, variantCount do
  local variant = recordData.variants[i]
  settingsOptions[#settingsOptions + 1] = {
    key = variant.settingKey,
    renderer = 'checkbox',
    name = variant.setting,
    default = true,
  }
end

interfaces.Settings.registerGroup {
  key = 'SettingsGlobalVisualSoulGems',
  page = 'VisualSoulGemsPage',
  l10n = 'VisualSoulGems',
  name = 'VisualSoulGemsGroupName',
  description = 'VisualSoulGemsGroupDesc',
  permanentStorage = true,
  settings = settingsOptions,
}

local randomize = settings:get 'SoulGemRandomize'
local selectedVariant = legacySelectedVariant or soulGemVariants[variantCount]
local variantValues = {}
local enabledVariants = {}

for i = 1, variantCount do
  local settingKey = recordData.variants[i].settingKey
  variantValues[settingKey] = settings:get(settingKey)
end

local function selectVariant(variantIndex)
  local settingKey = recordData.variants[variantIndex].settingKey
  local changed = false

  for i = 1, variantCount do
    local value = i == variantIndex
    local key = recordData.variants[i].settingKey

    if variantValues[key] ~= value then changed = true end
    variantValues[key] = value
  end

  selectedVariant = soulGemVariants[variantIndex]
  enabledVariants = { selectedVariant }
  if changed then core.sendGlobalEvent('S3VSG_SetVariantState', settingKey) end
end

local function enableAllVariants()
  local changed = false
  enabledVariants = {}

  for i = 1, variantCount do
    local settingKey = recordData.variants[i].settingKey
    if not variantValues[settingKey] then changed = true end
    variantValues[settingKey] = true
    enabledVariants[#enabledVariants + 1] = soulGemVariants[i]
  end

  if changed then core.sendGlobalEvent 'S3VSG_EnableAllVariants' end
end

local function variantIndex(value)
  for i = 1, variantCount do
    if soulGemVariants[i] == value then return i end
  end
end

local function updateEnabledVariants(changedSettingKey, enableAll)
  local changedVariantIndex = variantSettingKeys[changedSettingKey]
  enabledVariants = {}

  for i = 1, variantCount do
    if variantValues[recordData.variants[i].settingKey] then
      enabledVariants[#enabledVariants + 1] = soulGemVariants[i]
    end
  end

  if randomize then
    if enableAll then
      enableAllVariants()
    elseif #enabledVariants == 0 then
      local fallbackIndex = changedVariantIndex or 1
      selectVariant(fallbackIndex)
    elseif changedVariantIndex and variantValues[changedSettingKey] then
      selectedVariant = soulGemVariants[changedVariantIndex]
    end

    return
  end

  local selectedIndex = changedVariantIndex
    and variantValues[changedSettingKey]
    and changedVariantIndex
  selectedIndex = selectedIndex or variantIndex(selectedVariant)
  if not selectedIndex or not variantValues[recordData.variants[selectedIndex].settingKey] then
    selectedIndex = enabledVariants[1] and variantIndex(enabledVariants[1])
      or changedVariantIndex
      or variantCount
  end
  selectVariant(selectedIndex)
end

updateEnabledVariants()

settings:subscribe(async:callback(function(_, key)
  if key == 'SoulGemRandomize' then
    local wasRandomized = randomize
    randomize = settings:get(key)
    updateEnabledVariants(nil, randomize and not wasRandomized)
  elseif variantSettingKeys[key] then
    variantValues[key] = settings:get(key)
    updateEnabledVariants(key)
  end
end))

return {
  getSelectedVariant = function()
    if randomize then return enabledVariants[math.random(#enabledVariants)] end

    return selectedVariant
  end,
  eventHandlers = {
    ['S3VSG_EnableAllVariants'] = function()
      for i = 1, variantCount do
        local key = recordData.variants[i].settingKey

        variantValues[key] = true
        if settings:get(key) ~= true then settings:set(key, true) end
      end
    end,
    ['S3VSG_SetVariantState'] = function(settingKey)
      for i = 1, variantCount do
        local key = recordData.variants[i].settingKey
        local value = key == settingKey

        variantValues[key] = value
        if value then selectedVariant = soulGemVariants[i] end

        if settings:get(key) ~= value then settings:set(key, value) end
      end
    end,
  },
}
