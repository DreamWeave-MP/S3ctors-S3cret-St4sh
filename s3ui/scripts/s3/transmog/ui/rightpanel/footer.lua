local common = require('scripts.s3.transmog.ui.common')
local ui = require('openmw.ui')

local ClearButton = require('scripts.s3.transmog.ui.rightpanel.clearbutton')

return {
  type = ui.TYPE.Flex,
  props = {
    name = "Right Panel: Footer",
    arrange = ui.ALIGNMENT.Center,
    horizontal = true,
  },
  external = { stretch = 1, grow = .05, },
  content = ui.content {
    { external = { grow = 1.0 } },
    common.createButton("Previous Page", true),
    { external = { grow = 0.25 } },
    ClearButton(),
    { external = { grow = 0.25 } },
    common.createButton("Next Page", true),
    { external = { grow = 1 } },
  }
}
