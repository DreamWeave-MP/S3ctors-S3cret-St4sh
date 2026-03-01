local ui = require("openmw.ui")
local util = require("openmw.util")

local common = require("scripts.s3.transmog.ui.common")

local PrimaryFieldsTypeBox = require("scripts.s3.transmog.ui.tooltip.primaryfieldstypebox")
local PrimaryFieldsValueBox = require("scripts.s3.transmog.ui.tooltip.primaryfieldsvaluebox")
local PrimaryFieldsWeightBox = require("scripts.s3.transmog.ui.tooltip.primaryfieldsweightbox")
local PrimaryFieldsGoldPerBox = require("scripts.s3.transmog.ui.tooltip.primaryfieldsgoldperbox")

return function()
  return {
    type = ui.TYPE.Flex,
    props = {
      name = "Tooltip: Primary Fields Row",
      align = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    external = {
      grow = 1,
      stretch = 1,
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          align = ui.ALIGNMENT.Center,
          arrange = ui.ALIGNMENT.Center,
          size = util.vector2(120, 0),
        },
        external = {
          stretch = 1.0,
          -- grow = 1.0,
        },
        content = ui.content {
          PrimaryFieldsTypeBox(),
          { external = { grow = 1 } },
          PrimaryFieldsValueBox(),
          { external = { grow = 1 } },
          PrimaryFieldsWeightBox(),
          { external = { grow = 1 } },
          PrimaryFieldsGoldPerBox(),
          { external = { grow = 1 } },
        }
      },
      {
        type = ui.TYPE.Image,
        props = {
          name = "Primary Fields Divisor",
          size = util.vector2(4, 0),
          resource = ui.texture{ path = 'textures/menu_thick_border_right' .. '.dds' },
          relativePosition = util.vector2(0.5, 0),
        },
        external = {
          stretch = 1,
        },
      },
      {
        type = ui.TYPE.Flex,
        props = {
          align = ui.ALIGNMENT.Center,
          arrange = ui.ALIGNMENT.Center,
          name = "Tooltip: Secondary Fields Row",
        },
        external = {
          stretch = 1.0,
          grow = 1.0,
        },
        content = ui.content {
        }
      },
    },
  }
end
