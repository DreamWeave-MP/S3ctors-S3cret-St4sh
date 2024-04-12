-- Instances of this should probably be replaced by an interface?
local Body = require('scripts.s3.transmog.ui.rightpanel.body')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local Footer = require('scripts.s3.transmog.ui.rightpanel.footer')
local Header = require('scripts.s3.transmog.ui.rightpanel.header')
local ui = require('openmw.ui')
local util = require('openmw.util')
return {
    --type = ui.TYPE.Flex,
    props = {
      name = "Right Pane",
      size = util.vector2(const.RIGHT_PANE_WIDTH, 0),
      --resource = ui.texture { path = "white" },
      --color = util.color.hex('000000'),
    },
    external = {
      stretch = 1,
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          relativeSize = util.vector2(1.0, 1.0),
        },
        external = {
          stretch = 1,
          grow = 1,
        },
        content = ui.content {
          Header,
          {external = { grow = 0.2 }},
          Body,
          {external = { grow = 0.2 }},
          Footer,
          {external = { grow = 0.2 }},
        }
      }
    }
  }
