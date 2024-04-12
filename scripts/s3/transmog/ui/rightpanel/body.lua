local ui = require('openmw.ui')
local util = require('openmw.util')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local ItemContainer = require('scripts.s3.transmog.ui.rightpanel.itemcontainer')
local templates = require('openmw.interfaces').MWUI.templates

return {
  type = ui.TYPE.Flex,
  props = {
    name = "Right Panel: Body",
    arrange = ui.ALIGNMENT.Center,
    size = util.vector2(const.RIGHT_PANE_WIDTH, 0),
  },
  external = {
    stretch = 1,
  },
  content = ui.content {
    {
      template = templates.boxSolidThick,
      props = {
        name = "Right Panel: Item Container",
      },
      content = ui.content {
        ItemContainer.ItemContainer(),
      },
    }
  },
}
