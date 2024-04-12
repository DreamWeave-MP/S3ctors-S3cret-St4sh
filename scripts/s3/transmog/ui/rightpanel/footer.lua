local ui = require('openmw.ui')
local util = require('openmw.util')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const

return {
  type = ui.TYPE.Flex,
  props = {
    name = "Right Panel: Footer",
    size = util.vector2(0, const.WINDOW_HEIGHT * const.FOOTER_REL_SIZE),
    arrange = ui.ALIGNMENT.Center,
    horizontal = true,
  },
  external = {
    stretch = 1,
  },
  content = ui.content {
    { external = { grow = 1.0 } },
    common.createButton("Next Page"), -- We'll probably need to have some helper functions in here that
    { external = { grow = 0.5 } },
    common.createButton("Previous Page"),
    { external = { grow = 1 } },
  }
}
