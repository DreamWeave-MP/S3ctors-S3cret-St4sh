local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local time = require('openmw_aux.time')


-- async:newUnsavableSimulationTimer(0.1, function()
--   print('Record Generator loaded')
--   async:newUnsavableGameTimer(0.1, function()
--                                 print('Record Generator loaded')
--   end)
-- end)



return {
  engineHandlers = {
    onPlayerAdded = function()
      print("a player was added")
    end,
    onActivate = function()
      print("Activating object...")
    end,
    onInit = function()
      -- local caiusCell = nil
      -- for _, cell in ipairs(world.cells) do
      --   print(cell.name)
      --   if cell.name == 'Balmora, Caius Cosades\' House' then
      --     print('\n\n\n\n\n\n\n\n\nFound Caius\' house\n\n\n\n\n\n\n\n\n')
      --     caiusCell = cell
      --     break
      --   end
      -- end
      -- if not caiusCell then return end
      -- for _, object in ipairs(caiusCell:getAll()) do
        -- print(object.id, object.recordId)
        -- if object.recordId == 'caius cosades' then
          -- local newObject = world.createObject("daedric dagger_soultrap")
          -- newObject:moveInto(types.Actor.inventory(object))
          -- print('\n\n\n\n\n\n\n\nMoved daedric dagger_soultrap into Caius\n\n\n\n\n\n\n\n\n')
         -- end
      -- end
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
      -- Fix bug when removing original items in a 'mog
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
