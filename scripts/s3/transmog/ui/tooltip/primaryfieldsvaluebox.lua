local const = require("scripts.s3.transmog.ui.common").const
local ui = require("openmw.ui")
local util = require("openmw.util")

local I = require("openmw.interfaces")

return function()
  return {
    template = I.MWUI.templates.boxTransparentThick,
    props = {
      name = "Primary Fields Value Border",
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Primary Fields Value Flex",
          align = ui.ALIGNMENT.Start,
          arrange = ui.ALIGNMENT.Center,
          size = util.vector2(const.TOOLTIP_PRIMARY_FIELDS_WIDTH, 0),
          horizontal = true,
        },
        content = ui.content {
          {
            type = ui.TYPE.Image,
            props = {
              name = "Primary Fields Value Image",
              size = util.vector2(24, 24),
              resource = ui.texture { path = "icons\\gold.tga" },
            },
          },
          { external = { grow = 1 } },
          {
            type = ui.TYPE.Text,
            external = {
              grow = 1,
              stretch = 1,
            },
            props = {
              name = "Primary Fields Value Text",
              text = "Value",
              textColor = const.TEXT_COLOR,
              textSize = 16,
              textAlignV = ui.ALIGNMENT.Center,
              autoSize = false,
            },
          },
          { external = { grow = 1 } },
        }
      },
    }
  }
end
