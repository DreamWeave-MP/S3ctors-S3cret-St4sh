local ui = require('openmw.ui')
local InventoryContainer = require('scripts.s3.transmog.ui.inventorycontainer.main')

local function Body()
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Right Panel: Body",
      arrange = ui.ALIGNMENT.End,
      align = ui.ALIGNMENT.Center,
      autoSize = false,
      horizontal = true,
    },
    external = {
      stretch = 1,
      grow = 0.75,
    },
    content = ui.content {
      InventoryContainer.new(),
    },
  }
end

return Body
