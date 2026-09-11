---@omw-context global

local async = require 'openmw.async'
local interfaces = require 'openmw.interfaces'
local recordData = require 'scripts.s3.VSG.records'
local storage = require 'openmw.storage'
local types = require 'openmw.types'
local world = require 'openmw.world'

local miscellaneous = types.Miscellaneous
local miscellaneousRecords = miscellaneous.records
local itemData = types.Item.itemData

local createObject = world.createObject
local Error, Random, StrFormat = error, math.random, string.format

local soulGemVariants, variantSuffixes = {}, {}
for i = 1, #recordData.variants do
  local variant = recordData.variants[i]
  soulGemVariants[i] = variant.setting
  variantSuffixes[variant.setting] = variant.suffix
end

local variantCount = #soulGemVariants

local replacementNames = {}
for i = 1, #recordData.records do
  local record = recordData.records[i]
  replacementNames[record.sourceId] = record.replacementName
end

interfaces.Settings.registerGroup {
  key = 'SettingsGlobalVisualSoulGems',
  page = 'VisualSoulGemsPage',
  l10n = 'VisualSoulGems',
  name = 'VisualSoulGemsGroupName',
  description = 'VisualSoulGemsGroupDesc',
  permanentStorage = true,
  settings = {
    {
      key = 'SoulGemVariant',
      renderer = 'select',
      name = 'SoulGemVariantName',
      description = 'SoulGemVariantDesc',
      default = soulGemVariants[variantCount],
      argument = {
        l10n = 'VisualSoulGems',
        items = soulGemVariants,
      },
    },
    {
      key = 'SoulGemRandomize',
      renderer = 'checkbox',
      name = 'SoulGemRandomizeName',
      description = 'SoulGemRandomizeDesc',
      default = false,
    },
  },
}

local settings = storage.globalSection 'SettingsGlobalVisualSoulGems'
local randomize = settings:get 'SoulGemRandomize'
local selectedVariant = settings:get 'SoulGemVariant'

settings:subscribe(async:callback(function(_, key)
  local value = settings:get(key)

  if key == 'SoulGemVariant' then
    selectedVariant = value
  elseif key == 'SoulGemRandomize' then
    randomize = value
  end
end))

---@param item openmw.GObject
local function replaceSoulGem(item)
  local replacementName = replacementNames[item.recordId]
  if not replacementName then return end

  local soul = itemData(item).soul
  if not soul then return end

  local variant = selectedVariant
  if randomize then variant = soulGemVariants[Random(variantCount)] end

  local variantSuffix = variantSuffixes[variant]
  if not variantSuffix then Error(StrFormat('Unknown soul gem variant: %s', variant)) end

  local targetRecordId = recordData.replacementPrefix .. replacementName .. '_' .. variantSuffix
  if not miscellaneousRecords[targetRecordId] then
    Error(StrFormat('Missing VSG replacement record: %s', targetRecordId))
  end

  local count = item.count
  local owner = item.owner

  local replacement = createObject(targetRecordId, count)
  local replacementOwner = replacement.owner

  replacementOwner.recordId = owner.recordId
  replacementOwner.factionId = owner.factionId
  replacementOwner.factionRank = owner.factionRank

  itemData(replacement).soul = soul
  replacement:setScale(item.scale)
  replacement:teleport(item.cell, item.position, item.rotation)

  item:remove(count)
end

return {
  engineHandlers = {
    onItemActive = replaceSoulGem,
  },
}
