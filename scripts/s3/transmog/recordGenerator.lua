local types = require('openmw.types')
local world = require('openmw.world')

return {
  eventHandlers = {
    mogOnWeaponCreate = function(mogData)
      local recordTable = mogData.item
      local target = mogData.target
      local toRemove = types.Actor.inventory(target):find(mogData.toRemove)
      if not toRemove then error("Item not found in inventory") end
      toRemove:remove(1)
      recordTable.template = types.Weapon.record(toRemove)
      local recordDraft = types.Weapon.createRecordDraft(recordTable)
      local newRecord = world.createRecord(recordDraft)
      world.createObject(newRecord.id):moveInto(target)
    end,
    mogOnBookCreate = function(mogData)
      local recordTable = mogData.item
      local target = mogData.target
      local toRemoveBook = types.Actor.inventory(target):find(mogData.toRemoveBook)
      local toRemoveItem = types.Actor.inventory(target):find(mogData.toRemoveItem)
      if not toRemoveBook or not toRemoveItem then error("Item not found in inventory") end
      toRemoveBook:remove(1)
      toRemoveItem:remove(1)

      recordTable.enchant = types.Book.record(toRemoveBook).enchant
      recordTable.enchantCapacity = types.Book.record(toRemoveBook).enchantCapacity

      local recordDraft
      if toRemoveItem.type == types.Clothing then
        recordTable.template = types.Clothing.record(toRemoveItem)
        recordDraft = types.Clothing.createRecordDraft(recordTable)
      elseif toRemoveItem.type == types.Armor then
        recordTable.template = types.Armor.record(toRemoveItem)
        recordDraft = types.Armor.createRecordDraft(recordTable)
      elseif toRemoveItem.type == types.Weapon then
        recordTable.template = types.Weapon.record(toRemoveItem)
        recordDraft = types.Weapon.createRecordDraft(recordTable)
      end

      local newRecord = world.createRecord(recordDraft)
      world.createObject(newRecord.id):moveInto(target)
    end,
    mogOnApparelCreate = function(mogData)
      -- print(aux_util.deepToString(mogData.item), 2)
      local recordTable = mogData.item
      local target = mogData.target
      local oldItem = types.Actor.inventory(target):find(mogData.oldItem)
      local newItem = types.Actor.inventory(target):find(mogData.newItem)
      if not oldItem or not newItem then error("Item not found in inventory") end
      oldItem:remove(1)

      local recordDraft
      if newItem.type == types.Clothing then
        local oldItemRecord
        if oldItem.type == types.Clothing then
          oldItemRecord = types.Clothing.record(oldItem)
        elseif oldItem.type == types.Armor then
          oldItemRecord = types.Armor.record(oldItem)
        end
        recordTable.template = types.Clothing.record(mogData.newItem)
        recordTable.enchant = oldItemRecord.enchant
        recordTable.enchantCapacity = oldItemRecord.enchantCapacity
        recordTable.mwscript = oldItemRecord.mwscript
        recordTable.value = oldItemRecord.value
        recordTable.weight = oldItemRecord.weight
        recordDraft = types.Clothing.createRecordDraft(recordTable)
      elseif newItem.type == types.Armor then
        local oldItemRecord
        if oldItem.type == types.Clothing then
          oldItemRecord = types.Clothing.record(oldItem)
          -- recordTable.baseArmor = 0
        elseif oldItem.type == types.Armor then
          oldItemRecord = types.Armor.record(oldItem)
          recordTable.baseArmor = oldItemRecord.baseArmor
          recordTable.health = oldItemRecord.health
        end
        recordTable.template = types.Armor.record(mogData.newItem)
        recordTable.enchant = oldItemRecord.enchant
        recordTable.enchantCapacity = oldItemRecord.enchantCapacity
        recordTable.mwscript = oldItemRecord.mwscript
        recordTable.value = oldItemRecord.value
        recordTable.weight = oldItemRecord.weight
        recordDraft = types.Armor.createRecordDraft(recordTable)
      end

      local newRecord = world.createRecord(recordDraft)
      world.createObject(newRecord.id):moveInto(target)
    end,
  }
}
