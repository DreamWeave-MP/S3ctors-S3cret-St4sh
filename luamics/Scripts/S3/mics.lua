local types = require('openmw.types')
local world = require('openmw.world')


local MIMIC_LIST = 'concit_levc_mimic_tower'
local LIST_RECORD = types.LevelledCreature.records[MIMIC_LIST]

local MIMIC_CHANCE = math.random(.05, .1)
local MIMIC_DISALLOWED_IDS = {}

return {
  interfaceName = 's3_luamics',
  interface = {
    addDisallowedChest = function(chest_id)
      if type(chest_id) ~= 'string' then
        error(string.format('Chest recordId %s was not a string!', chest_id))
      elseif MIMIC_DISALLOWED_IDS[chest_id] then
        error(string.format('Chest recordId %s already registered!', chest_id))
      elseif types.Container.records[chest_id:lower()] then
        MIMIC_DISALLOWED_IDS[chest_id:lower()] = true
      end
    end,
  },
  engineHandlers = {
    onObjectActive = function(toReplace)
      if not types.Container.objectIsInstance(toReplace)
        or MIMIC_DISALLOWED_IDS[toReplace.recordId]
        or toReplace.type.records[toReplace.recordId].mwscript
        or (toReplace.owner.recordId and toReplace.owner.recordId ~= 'player')
        or toReplace.owner.factionId
        or not string.find(toReplace.recordId, 'chest')
        or string.find(toReplace.recordId, 'trader')
      then return end

      if math.random() > MIMIC_CHANCE then return end

      local mimicId = LIST_RECORD:getRandomId(100)

      local newMimic = world.createObject(mimicId)
      newMimic:teleport(toReplace.cell, toReplace.position, toReplace.rotation)
      newMimic:setScale(toReplace.scale)

      local mimicInventory = newMimic.type.inventory(newMimic)

      local oldInventory = toReplace.type.content(toReplace):getAll()
      for index = #oldInventory, 1, -1 do
        oldInventory[index]:moveInto(mimicInventory)
      end

      toReplace.enabled = false
      toReplace:remove()

    end,
  }
}
