local const = require("scripts.s3.transmog.ui.common").const

local ui = require("openmw.ui")

local I = require("openmw.interfaces")

return function()
  return {
    template = I.MWUI.templates.boxTransparentThick,
    props = {
      name = "Primary Fields Type Box",
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        props = {
          name = "Primary Fields Type Text",
          text = "Primary Fields",
          size = const.TOOLTIP_TYPE_TEXT_SIZE,
          textColor = const.TEXT_COLOR,
          textSize = 14,
          textAlignH = ui.ALIGNMENT.Center,
          textAlignV = ui.ALIGNMENT.Center,
          wordWrap = true,
          autoSize = false,
        },
      }
    }
  }
end
