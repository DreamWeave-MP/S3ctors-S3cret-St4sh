local ui = require('openmw.ui')

local I = require('openmw.interfaces')
local ItemPortraitContainer = require('scripts.s3.transmog.ui.leftpanel.itemportraitcontainer')
local GlamourButton = require('scripts.s3.transmog.ui.leftpanel.glamourbutton').createButton

local function LeftPanel()
  local baseItemContainer = ItemPortraitContainer.new("Base Item")
  local newItemContainer = ItemPortraitContainer.new("New Item")
  local glamourButton = GlamourButton()
  I.transmogActions.menus.baseItemContainer = baseItemContainer
  I.transmogActions.menus.newItemContainer = newItemContainer
  I.transmogActions.menus.glamourButton = glamourButton
  return {
    type = ui.TYPE.Flex,
    name = "leftpanel",
    props = {
      arrange = ui.ALIGNMENT.Center,
      autoSize = false,
    },
    external = { grow = .25, stretch = 1, },
    content = ui.content {
      { external = { grow = 1 } },
      baseItemContainer,
      { external = { grow = 0.5 } },
      newItemContainer,
      { external = { grow = 0.2 } },
      glamourButton,
      { external = { grow = 1 } },
    },
  }
end

return LeftPanel
