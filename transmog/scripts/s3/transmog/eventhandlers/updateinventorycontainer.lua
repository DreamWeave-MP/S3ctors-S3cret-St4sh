local self = require('openmw.self')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local common = require('scripts.s3.transmog.ui.common')

--- Self-sent event to refresh the inventory ui
--- @param createdObject openmw.core#GameObject: newly mogged item
--- @param resetPortraits boolean: whether to reset the new/base portraits
--- @param equip boolean: whether to equip the new item or just refresh the ui
local function updateInventoryContainer(containerUpdateData)
  local Aliases = I.transmogActions.MenuAliases
  local inventoryContainer = Aliases('inventory container')
  if not inventoryContainer then
    error('received container update event, but it does not exist')
  end

  if containerUpdateData then
    if containerUpdateData.createdObject and containerUpdateData.equip then
      common.refreshEquipment(containerUpdateData.createdObject)
    end

    if containerUpdateData.updateEquipment then common.updateOriginalEquipment() end

    if containerUpdateData.resetPortraits then I.transmogActions.MogMenuEvent({action = 'clear'}) end
  end

  I.transmogActions.MogMenuEvent({
      targetName = 'inventory container',
  })

  types.Actor.setEquipment(self, Aliases('original equipment'))
end

return {
  eventHandlers = {
    updateInventoryContainer = updateInventoryContainer
  }
}
