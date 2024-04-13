local ui = require("openmw.ui")
local util = require("openmw.util")
local common = require("scripts.s3.transmog.ui.common")

local I = require("openmw.interfaces")

return {
  template = I.MWUI.templates.boxTransparentThick,
  layer = 'Notification',
  props = {
    name = "Tooltip",
    -- relativePosition = util.vector2(0.5, 0.5),
    -- anchor = util.vector2(0.5, 0.5)
  },
  content = ui.content {
    {
      type = ui.TYPE.Flex,
      props = {
        align = ui.ALIGNMENT.End,
        size = util.vector2(256, 256),
      },
      content = ui.content {
        {
          type = ui.TYPE.Image,
          props = {
            size = util.vector2(256, 85),
            resource = ui.texture { path = "white" },
            color = util.color.hex('0000ff'),
          },
        },
        {
          type = ui.TYPE.Image,
          props = {
            size = util.vector2(256, 85),
            resource = ui.texture { path = "white" },
            color = util.color.hex('00ff00'),
          },
        },
        {
          type = ui.TYPE.Image,
          props = {
            size = util.vector2(256, 85),
            resource = ui.texture { path = "white" },
            color = util.color.hex('ff0000'),
          },
        },
      }
    }
  }
}
