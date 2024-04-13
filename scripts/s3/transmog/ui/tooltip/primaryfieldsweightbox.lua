local const = require("scripts.s3.transmog.ui.common").const
local ui = require("openmw.ui")
local util = require("openmw.util")

local I = require("openmw.interfaces")

return function()
  return {
    template = I.MWUI.templates.boxTransparentThick,
    props = {
      name = "Primary Fields Weight Border",
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Primary Fields Weight Flex",
          align = ui.ALIGNMENT.Start,
          arrange = ui.ALIGNMENT.Center,
          size = util.vector2(90, 0),
          horizontal = true,
        },
        content = ui.content {
          {
            type = ui.TYPE.Image,
            props = {
              name = "Primary Fields Weight Image",
              size = util.vector2(24, 24),
              resource = ui.texture { path = "icons\\weight.tga" },
            },
          },
          { external = { grow = 0.5 } },
          {
            type = ui.TYPE.Text,
            external = {
              grow = 1,
              stretch = 1,
            },
            props = {
              name = "Primary Fields Weight Text",
              text = "Weight",
              textColor = const.TEXT_COLOR,
              textSize = 16,
              textAlignV = ui.ALIGNMENT.Center,
              autoSize = false,
            },
          },
          { external = { grow = 0.25 } },
        }
      },
    }
  }
end
