-- local aux_util = require('openmw_aux.util')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local ui = require('openmw.ui')
local util = require('openmw.util')

local ItemPortraitContainer = require('scripts.s3.transmog.ui.leftpanel.itemportraitcontainer')
local GlamourButton = require('scripts.s3.transmog.ui.leftpanel.glamourbutton').createButton

return {
  type = ui.TYPE.Flex,
  props = {
    name = "leftpanel",
    size = util.vector2(const.LEFT_PANE_WIDTH, 1),
    arrange = ui.ALIGNMENT.Center,
    },
  content = ui.content {
      { external = { grow = 1 } },
      ItemPortraitContainer("Base Item"),
      { external = { grow = 0.5 } },
      ItemPortraitContainer("New Item"),
      { external = { grow = 0.2 } },
      GlamourButton(),
      { external = { grow = 1 } },
  },
  external = {
    stretch = 1,
  }
}
