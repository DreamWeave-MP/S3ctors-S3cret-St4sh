local self = require('openmw.self')
local types = require('openmw.types')

local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')

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
  -- also put all the input related shit into its own script
  -- maybe do that first since it's not actively used yet
  -- Then commit all this shit and try placing the category buttons on the left
  -- in a vertical stack
  -- Make equipping more configurable?

  if containerUpdateData then
    if containerUpdateData.createdObject and containerUpdateData.equip then
      common.refreshEquipment()
    end

    if containerUpdateData.updateEquipment then common.updateOriginalEquipment() end

    if containerUpdateData.resetPortraits then I.transmogActions.MogMenuEvent({action = 'clear'}) end
  end

  --- With this setup, we let the container itself do the element update when it's ready
  --- I'm not sure if that's the best way to do things, but it seems to make sense atm
  I.transmogActions.MogMenuEvent({
      targetName = 'inventory container',
  })

  -- do we really want to revert back to the original equipment
  -- every single time the container updates?
  types.Actor.setEquipment(self, Aliases('original equipment'))
end

return {
  eventHandlers = {
    updateInventoryContainer = updateInventoryContainer
  }
}
