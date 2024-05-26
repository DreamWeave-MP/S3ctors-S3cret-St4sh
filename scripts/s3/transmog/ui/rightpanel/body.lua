local ui = require('openmw.ui')
local sizes = require('scripts.s3.transmog.const.size')
local InventoryContainer = require('scripts.s3.transmog.ui.inventorycontainer.main')

local function Body(_bodyArgs)
  local inventoryContainer = InventoryContainer.new()

  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Body",
      arrange = ui.ALIGNMENT.End,
      align = ui.ALIGNMENT.Center,
      autoSize = false,
      horizontal = true,
      relativeSize = sizes.BODY,
    },
    external = {
      stretch = 1,
      grow = 0.75,
    },
    content = ui.content {
      inventoryContainer,
    },
  }
end

return Body
