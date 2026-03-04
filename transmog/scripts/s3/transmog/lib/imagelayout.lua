local common = require('scripts.s3.transmog.ui.common')
local util = require('openmw.util')

return {
    common.templateImage(util.color.hex('ff0000'), nil, util.vector2(1, 1)),
    common.templateImage(util.color.hex('fcba03'), nil, util.vector2(0.75, 0.5)),
    common.templateImage(util.color.hex('00f00f'), nil, util.vector2(0.25, 1.0)),
    common.templateImage(util.color.hex('0000ff'), nil, util.vector2(0.25, 0.75)),
    common.templateImage(util.color.hex('f0f000'), nil, util.vector2(0.25, 0.5)),
    common.templateImage(util.color.hex('ff00ff'), nil, util.vector2(0.25, 0.25)),
  }
