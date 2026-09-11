---@omw-context global

local async = require 'openmw.async'
local interfaces = require 'openmw.interfaces'
local storage = require 'openmw.storage'
local types = require 'openmw.types'
local world = require 'openmw.world'

local miscellaneous = types.Miscellaneous
local miscellaneousRecords = miscellaneous.records
local createMiscellaneousDraft = miscellaneous.createRecordDraft
local itemData = types.Item.itemData

local createObject = world.createObject
local createRecord = world.createRecord
local Error, Random, StrFormat = error, math.random, string.format

local modelPathFormat = 'meshes/s3/%s/%s.nif'

local soulGemRecordIds = {
  'misc_soulgem_common',
  'misc_soulgem_grand',
  'misc_soulgem_greater',
  'misc_soulgem_lesser',
  'misc_soulgem_petty',
}

local soulGemVariants = {
  'particles',
  'particles & static glow',
  'static glow',
  'ultra glow',
}

local variantCount = #soulGemVariants

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
      name = 'SoulGemVariantNames',
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

local ReplacementMap
local TemplateTable = { template = '', model = '' }

local function generateReplacementRecords()
  if ReplacementMap then return end

  ReplacementMap = {}

  for i = 1, #soulGemRecordIds do
    local soulGemRecordId = soulGemRecordIds[i]
    local originalRecord = miscellaneousRecords[soulGemRecordId]
    if not originalRecord then Error(StrFormat('Missing soul gem record: %s', soulGemRecordId)) end

    local replacementVariants = {}

    for j = 1, #soulGemVariants do
      local variant = soulGemVariants[j]

      TemplateTable.template, TemplateTable.model =
        originalRecord, StrFormat(modelPathFormat, variant, soulGemRecordId)

      local replacementRecord = createRecord(createMiscellaneousDraft(TemplateTable))

      replacementVariants[variant] = replacementRecord.id
    end

    ReplacementMap[soulGemRecordId] = replacementVariants
  end
end

---@param item openmw.GObject
local function replaceSoulGem(item)
  local replacementVariants = ReplacementMap and ReplacementMap[item.recordId]
  if not replacementVariants then return end

  local soul = itemData(item).soul
  if not soul then return end

  local variant = selectedVariant
  if randomize then variant = soulGemVariants[Random(variantCount)] end

  local targetRecordId = replacementVariants[variant]
  if not targetRecordId then Error(StrFormat('Unknown soul gem variant: %s', variant)) end

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
    onPlayerAdded = generateReplacementRecords,
    onSave = function() return ReplacementMap end,
    onLoad = function(data)
      if data then ReplacementMap = data end
    end,
    onItemActive = replaceSoulGem,
  },
}
