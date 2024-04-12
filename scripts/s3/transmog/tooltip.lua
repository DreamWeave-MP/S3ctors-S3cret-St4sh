local ui = require("openmw.ui")
local util = require("openmw.util")
local common = require("scripts.s3.transmog.ui.common")

local I = require("openmw.interface")

return {
  template = ui.templates.boxTransparentThick,
  layer = 'Notification',
  content = ui.content {
    {
      type = ui.TYPE.Text,
      props = {
        text = "Empty",
        size = util.vector2(128, 64),
        textColor = common.const.TEXT_COLOR,
        textSize = common.const.FONT_SIZE,
        textAlignH = ui.ALIGNMENT.Center,
        multiline = true,
        autoSize = false,
        wordWrap = true,
      }
    }
  }
}
