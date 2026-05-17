local types = require('openmw.types')
local world = require('openmw.world')

return {
  engineHandlers = {
    onPlayerAdded = function()
    end,
    onActivate = function()
    end,
    onInit = function()
    end,
    onUpdate = function()
    end,
  },
  eventHandlers = {
    mogOnWeaponCreate = function(mogData)
      print('mog request received')
      local recordTable = mogData.item
      local target = mogData.target
      local toRemove = types.Actor.inventory(target):find(mogData.toRemove)

      assert(toRemove, "Item not found in inventory")

      toRemove:remove(1)
      recordTable.template = types.Weapon.records[toRemove.recordId]
      local recordDraft = types.Weapon.createRecordDraft(recordTable)
      local newRecord = world.createRecord(recordDraft)
      world.createObject(newRecord.id):moveInto(target)
    end,
    mogOnBookCreate = function(mogData)
      local recordTable = mogData.item
      local target = mogData.target
      local toRemoveBook = types.Actor.inventory(target):find(mogData.toRemoveBook)
      local toRemoveItem = types.Actor.inventory(target):find(mogData.toRemoveItem)

      assert(toRemoveBook and toRemoveItem, "Item not found in inventory")

      toRemoveBook:remove(1)
      toRemoveItem:remove(1)

      local bookRecord = types.Book.records[toRemoveBook.recordId]

      recordTable.enchant = bookRecord.enchant
      recordTable.enchantCapacity = bookRecord.enchantCapacity

      local recordDraft
      if toRemoveItem.type == types.Clothing then
        recordTable.template = types.Clothing.records[toRemoveItem.recordId]
        recordDraft = types.Clothing.createRecordDraft(recordTable)
      elseif toRemoveItem.type == types.Armor then
        recordTable.template = types.Armor.records[toRemoveItem.recordId]
        recordDraft = types.Armor.createRecordDraft(recordTable)
      elseif toRemoveItem.type == types.Weapon then
        recordTable.template = types.Weapon.record[toRemoveItem.recordId]
        recordDraft = types.Weapon.createRecordDraft(recordTable)
      end

      local newRecord = world.createRecord(recordDraft)
      world.createObject(newRecord.id):moveInto(target)
    end,
    mogOnApparelCreate = function(mogData)
      local recordTable = mogData.item
      local target = mogData.target
      local oldItem = types.Actor.inventory(target):find(mogData.oldItem)
      local newItem = types.Actor.inventory(target):find(mogData.newItem)

      assert(oldItem and newItem, "Item not found in inventory")

      oldItem:remove(1)

      local recordDraft

      if newItem.type == types.Clothing then
        local oldItemRecord
        print(oldItem.recordId)

        if oldItem.type == types.Clothing then
          oldItemRecord = types.Clothing.records[oldItem.recordId]
        elseif oldItem.type == types.Armor then
          oldItemRecord = types.Armor.records[oldItem.recordId]
        end

        recordTable.template = types.Clothing.records[newItem.recordId]
        recordTable.enchant = oldItemRecord.enchant
        recordTable.enchantCapacity = oldItemRecord.enchantCapacity
        recordTable.mwscript = oldItemRecord.mwscript
        recordTable.value = oldItemRecord.value
        recordTable.weight = oldItemRecord.weight
        recordDraft = types.Clothing.createRecordDraft(recordTable)

      elseif newItem.type == types.Armor then
        local oldItemRecord

        if oldItem.type == types.Clothing then
          oldItemRecord = types.Clothing.records[oldItem.recordId]
        elseif oldItem.type == types.Armor then
          oldItemRecord = types.Armor.records[oldItem.recordId]
          recordTable.baseArmor = oldItemRecord.baseArmor
          recordTable.health = oldItemRecord.health
        end

        recordTable.template = types.Armor.records[newItem.recordId]
        recordTable.enchant = oldItemRecord.enchant
        recordTable.enchantCapacity = oldItemRecord.enchantCapacity
        recordTable.mwscript = oldItemRecord.mwscript
        recordTable.value = oldItemRecord.value
        recordTable.weight = oldItemRecord.weight
        recordDraft = types.Armor.createRecordDraft(recordTable)
      end

      local createdRecord = world.createRecord(recordDraft)
      local createdObject = world.createObject(createdRecord.id)
      createdObject:moveInto(target)
      target:sendEvent('updateInventoryContainer', {
                         sender = 'transmogFinished',
                         resetPortraits = true,
                         equip = true,
                         createdObject = createdObject
      })
    end,
  }
}
