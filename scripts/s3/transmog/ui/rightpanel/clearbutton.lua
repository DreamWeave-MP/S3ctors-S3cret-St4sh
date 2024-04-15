local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

local ItemContainer = require('scripts.s3.transmog.ui.rightpanel.itemcontainer')

local I = require('openmw.interfaces')

return function()
  local button = common.createButton("Clear")
  button.props.name =  "Clear Button"
  button.events.mousePress = async:callback(function()
    local itemContainer = I.transmogActions.menus.itemContainer
    itemContainer.userData = common.const.DEFAULT_ITEM_TYPES
    itemContainer.content = ui.content(ItemContainer.updateContent(itemContainer.userData))
    types.Actor.setEquipment(self, I.transmogActions.menus.originalInventory)
    common.resetPortraits()
    common.mainMenu():update()
  end)
  return button
end
