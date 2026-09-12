---@omw-context global

local globalSettings = require 'scripts.s3.VSG.globalSettings'
local recordData = require 'scripts.s3.VSG.records'
local types = require 'openmw.types'
local world = require 'openmw.world'

local miscellaneous = types.Miscellaneous
local miscellaneousRecords = miscellaneous.records
local itemData = types.Item.itemData

local createObject = world.createObject
local Error, StrFormat = error, string.format

local variantSuffixes = {}
for i = 1, #recordData.variants do
  local variant = recordData.variants[i]
  variantSuffixes[variant.setting] = variant.suffix
end

local replacementNames = {}
for i = 1, #recordData.records do
  local record = recordData.records[i]
  replacementNames[record.sourceId] = record.replacementName
end

---@param item openmw.GObject
local function replaceSoulGem(item)
  local replacementName = replacementNames[item.recordId]
  if not replacementName then return end

  local soul = itemData(item).soul
  if not soul then return end

  local variant = globalSettings.getSelectedVariant()

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
  eventHandlers = globalSettings.eventHandlers,
  engineHandlers = {
    onItemActive = replaceSoulGem,
  },
}
