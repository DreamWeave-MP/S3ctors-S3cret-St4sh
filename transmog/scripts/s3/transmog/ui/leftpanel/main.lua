-- local aux_util = require('openmw_aux.util')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local sizes = require('scripts.s3.transmog.const.size')
local ui = require('openmw.ui')
local util = require('openmw.util')

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
  local testImage = common.templateImage(util.color.hex('0000ff'), 'white', util.vector2(1, 1))
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "leftpanel",
      size = util.vector2(sizes.LEFT_PANE_WIDTH, 0),
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content {
      { external = { grow = 1 } },
      -- testImage,
      baseItemContainer,
      { external = { grow = 0.5 } },
      newItemContainer,
      { external = { grow = 0.2 } },
      glamourButton,
      { external = { grow = 1 } },
    },
    external = {
      stretch = 1,
    }
  }
end

return LeftPanel
