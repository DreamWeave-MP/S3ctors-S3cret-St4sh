local async = require('openmw.async')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local world = require('openmw.world')

local ASSASSIN_LIST_ID = 'affass_asslist'

return {
  eventHandlers = {
    S3_AffAss_NewFargothMinion = function(eventTarget)
      local equipment = eventTarget.type.getEquipment(eventTarget)
      print(eventTarget, #equipment)
      local equipmentTable = {}

      local assassinList = types.LevelledCreature.records[ASSASSIN_LIST_ID]
      local randomAssassin = assassinList.getRandomId(assassinList, 100)

      local weaponSlot = eventTarget.type.EQUIPMENT_SLOT.CarriedRight

      local assassin = world.createObject(randomAssassin)
      local assassinInventory = assassin.type.inventory(assassin)

      for slot, gameObject in pairs(equipment) do
        if slot ~= weaponSlot then
          equipmentTable[slot] = gameObject.recordId
          world.createObject(gameObject.recordId):moveInto(assassinInventory)
        end
      end

      local pos, rot, cell
      pos = eventTarget.position
      rot = eventTarget.rotation
      cell = eventTarget.cell

      async:newUnsavableGameTimer(5 * time.minute, function()
                                    assassin:teleport(cell, pos, rot)
                                    assassin:sendEvent('S3_AffAss_MinionEquip', equipmentTable)
      end)
    end,
  }
}
