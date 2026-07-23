local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')

local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')
local Aliases = require('scripts.s3.transmog.ui.menualiases')

local function acceptTransmog()
  if not Aliases('confirm screen') then return end

  local newItemName = Aliases('confirm screen input').props.text

  if newItemName == "" then
    common.messageBoxSingleton("No Name Warning", "You must name your item!")
    return
  end

  local baseItem = Aliases('base item'):getUserData()
  local newItem = Aliases('new item'):getUserData()

  -- we should add the capability of stacking ammunition
  for slot, item in pairs(Aliases()['original equipment']) do
    if item.recordId == baseItem.recordId and item.count <= 1 then
      Aliases()['original equipment'][slot] = nil
      break
    end
  end
  types.Actor.setEquipment(self, I.transmogActions.originalEquipment)

  -- A weapon is used as base, with the appearance of a non-equippable item
  -- In this case we only apply the model from the new item on the new record.
  if baseItem.type == types.Weapon then
    local weaponTable = {name = newItemName, model = newItem.record.model, icon = newItem.record.icon}
    core.sendGlobalEvent("mogOnWeaponCreate",
                         {
                           target = self,
                           item = weaponTable,
                           toRemove = baseItem.recordId
    })
  elseif baseItem.type == types.Book then
    local bookTable = { name = newItemName }
    core.sendGlobalEvent("mogOnBookCreate",
                         {
                           target = self,
                           item = bookTable,
                           toRemoveBook = baseItem.recordId,
                           toRemoveItem = newItem.recordId,
    })
  elseif baseItem.type == types.Clothing or baseItem.type == types.Armor then
    local apparelTable = { name = newItemName }
    core.sendGlobalEvent("mogOnApparelCreate",
                         {
                           target = self,
                           item = apparelTable,
                           oldItem = baseItem.recordId,
                           newItem = newItem.recordId,
    })
  end
  I.transmogActions.MogMenuEvent({action = 'clear'})
  Aliases('main menu').layout.props.visible = true
  local confirmScreen = Aliases('confirm screen')
  if not confirmScreen then error('confirm screen update called but it does not exist') end
  confirmScreen.layout.props.visible = false
  confirmScreen:update()
end

return {
  interface = {
    acceptTransmog = acceptTransmog
  }
}
