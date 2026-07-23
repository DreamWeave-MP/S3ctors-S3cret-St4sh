local ui = require('openmw.ui')

local common = require('scripts.s3.transmog.ui.common')
local sizes = require('scripts.s3.transmog.const.size')

local I = require('openmw.interfaces')
local BaseUI = require('scripts.s3.transmog.ui.baseobject')
local ItemPortrait = require('scripts.s3.transmog.ui.inventorycontainer.itemportrait')

local ItemRow = {}

function ItemRow.getItemData(typedInventory, itemIndex)
  local item = typedInventory[itemIndex]

  if not item then
    return
  end

  local itemRecord = common.recordAliases[item.type].recordGenerator(item)

  if not itemRecord then
    error("Unequippable item type, you dun goofed")
  end

  return {
    record = itemRecord,
    recordId = item.recordId,
    type = item.type,
  }
end

function ItemRow.new(maxRows, typedInventory, itemIndex)
  local newRow = BaseUI.new(ItemRow)

  newRow.type = ui.TYPE.Flex
  newRow.props = {
    name = "Right Panel: Item Row ",
    horizontal = true,
    autoSize = false,
    relativeSize = sizes.RPANEL.INVENTORY_ROW,
  }
  newRow.external = {
    grow = 1,
    stretch = 1,
  }
  newRow.content = {}

  for rowIndex = 1, maxRows do
    newRow.props.name = newRow.props.name .. rowIndex
    local objectData = newRow.getItemData(typedInventory, itemIndex + rowIndex)
    if objectData then
      newRow.content[#newRow.content + 1] = ItemPortrait.new(objectData)
    else
      newRow.content[#newRow.content + 1] = {
        template = I.MWUI.templates.Interval,
        external = {
          grow = 1,
          stretch = 1,
        },
      }
    end
  end

  newRow.content = ui.content(newRow.content)

  return newRow
end

return ItemRow
