local const = require("scripts.s3.transmog.ui.common").const
local ui = require("openmw.ui")
local util = require("openmw.util")

local I = require("openmw.interfaces")

return function()
  return {
    template = I.MWUI.templates.boxTransparentThick,
    props = {
      name = "Primary Fields GoldPer Border",
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Primary Fields GoldPer Flex",
          align = ui.ALIGNMENT.Start,
          arrange = ui.ALIGNMENT.Center,
          size = util.vector2(const.TOOLTIP_PRIMARY_FIELDS_WIDTH, 0),
          horizontal = true,
        },
        content = ui.content {
          {
            type = ui.TYPE.Image,
            props = {
              name = "Primary Fields GoldPer Image 1",
              size = util.vector2(20, 20),
              resource = ui.texture { path = "icons\\gold.tga" },
            },
          },
          {
            type = ui.TYPE.Image,
            external = {
              -- grow = 1,
              stretch = 1,
            },
            props = {
              name = "Primary Fields GoldPer Divisor",
              size = util.vector2(4, 0),
              resource = ui.texture { path = 'textures/menu_thick_border_right' .. '.dds' }
            },
          },
          {
            type = ui.TYPE.Image,
            props = {
              name = "Primary Fields GoldPer Image 2",
              size = util.vector2(20, 20),
              resource = ui.texture { path = "icons\\weight.tga" },
            },
          },
          { external = { grow = 0.3 } },
          {
            type = ui.TYPE.Text,
            external = {
              grow = 1,
              stretch = 1,
            },
            props = {
              name = "Primary Fields GoldPer Text",
              text = "Gold per weight",
              textColor = const.TEXT_COLOR,
              textSize = 16,
              textAlignV = ui.ALIGNMENT.Center,
              -- autoSize = false,
            },
          },
          { external = { grow = 0.25 } },
        }
      },
    }
  }
end
