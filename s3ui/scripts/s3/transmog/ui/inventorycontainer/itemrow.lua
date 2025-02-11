local ui = require('openmw.ui')

-- local common = require('scripts.s3.transmog.ui.common')
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

  local itemRecord = item.type.records[item.recordId]
  assert(itemRecord, 'Item Row generator failed to locate record for ' .. item.recordId)

  return {
    record = itemRecord,
    recordId = item.recordId,
    type = item.type,
  }
end

function ItemRow.new(typedInventory, itemIndex)
  local newRow = BaseUI.new(ItemRow)

  newRow.type = ui.TYPE.Flex
  newRow.props = {
    name = "Right Panel: Item Row ",
    -- horizontal = true,
    -- autoSize = false,
    relativeSize = sizes.RPANEL.INVENTORY_ROW,
  }
  newRow.external = {
    grow = 1,
    stretch = 1,
  }
  newRow.content = {}

  newRow.props.name = newRow.props.name .. itemIndex
  local objectData = newRow.getItemData(typedInventory, itemIndex)

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

  newRow.content = ui.content(newRow.content)

  return newRow
end

return ItemRow
