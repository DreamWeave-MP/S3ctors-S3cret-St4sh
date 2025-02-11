local gameSelf = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local sizes = require('scripts.s3.transmog.const.size')
local Aliases = require('scripts.s3.transmog.ui.menualiases')
local BaseUI = require('scripts.s3.transmog.ui.baseobject')
local ItemRow = require('scripts.s3.transmog.ui.inventorycontainer.itemrow')

local I = require('openmw.interfaces')

local InventoryContainer = {
  type = ui.TYPE.Flex,
  props = {
    name = "Right Panel: Inventory Container",
    autoSize = false,
    relativeSize = sizes.RPANEL.INVENTORY,
  },
  userData = const.DEFAULT_ITEM_TYPES,
}

function InventoryContainer:updateContent()
  if not self.userData then error('InventoryContainer:updateContent called without type filter in userData') end

  local acceptedTypes = self.userData
  local typedInventory = {}

  local maxRows = const.MAX_ITEMS.y

  local typedItems = types.Actor.inventory(gameSelf):getAll()

  for _, item in ipairs(typedItems) do
    if not item:isValid() then print("Invalid item in inventory")
    elseif acceptedTypes[item.type] then
      typedInventory[#typedInventory + 1] = item
    end
  end

  local itemIndex = 0
  local newContent = {}

  for rowIndex = 1, maxRows do
    newContent[#newContent + 1] = ItemRow.new(typedInventory, itemIndex + rowIndex)
  end

  self.content = ui.content(newContent)
end

function InventoryContainer.new(acceptedTypes)
  local newContainer = BaseUI.new(InventoryContainer)

  if acceptedTypes then newContainer.userData = acceptedTypes end

  I.transmogActions.menus.inventoryContainer = newContainer

  newContainer:updateContent()

  return newContainer
end

function InventoryContainer:mogMenuEvent(mogArgs)
  if not mogArgs.itemType and not self.userData then error('Inventory update requested without item type') end
  self.userData = mogArgs.itemType or self.userData
  self:updateContent()
  Aliases('main menu'):update()
end

return InventoryContainer
