local common = require("scripts.s3.transmog.ui.common")
local const = common.const

local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")

local I = require("openmw.interfaces")

return function()
  return {
    template = I.MWUI.templates.boxTransparent,
    props = {
      name = "Primary Fields Type Box",
    },
    external = {
      -- grow = 1,
      -- stretch = 1,
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Primary Fields Type Flex",
          align = ui.ALIGNMENT.Start,
          arrange = ui.ALIGNMENT.Center,
          size = util.vector2(const.TOOLTIP_PRIMARY_FIELDS_WIDTH, 0),
          horizontal = true,
        },
        content = ui.content {
          {
            type = ui.TYPE.Image,
            external = {
              stretch = 1,
              -- grow = 1,
            },
            props = {
              size = util.vector2(32, 32),
              name = "Primary Fields Skill Image",
              -- relativeSize = util.vector2(0.5, 1),
              resource = ui.texture { path = "white" },
            },
          },
          -- { external = { grow = 1 } },
          -- common.templateImage(util.color.hex("ffffff"), nil, nil),
          {
            type = ui.TYPE.Text,
            external = {
              grow = 1,
              stretch = 1,
            },
            props = {
              name = "Primary Fields Type Text",
              text = "Primary Fields",
              -- size = util.vector2(const.TOOLTIP_TYPE_TEXT_SIZE.x, 0),
              textColor = const.TEXT_COLOR,
              textSize = 14,
              textAlignH = ui.ALIGNMENT.Center,
              textAlignV = ui.ALIGNMENT.Center,
              wordWrap = true,
              autoSize = false,
            },
          },
        }
      },
    }
  }
end
