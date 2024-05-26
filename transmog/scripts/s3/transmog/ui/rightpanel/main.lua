local common = require('scripts.s3.transmog.ui.common')
-- local const = common.const
local sizes = require('scripts.s3.transmog.const.size')
local Body = require('scripts.s3.transmog.ui.rightpanel.body')
local Footer = require('scripts.s3.transmog.ui.rightpanel.footer')
local Header = require('scripts.s3.transmog.ui.rightpanel.header')
local ui = require('openmw.ui')
local util = require('openmw.util')

-- remove the rest of the hardcoded sizes before fixing the tooltip
-- original inventory is still kinda fucked up too
local function RightPanel()
return {
    props = {
      name = "Right Pane",
      -- relativeSize = util.vector2(1, 1),
      size = util.vector2(sizes.RIGHT_PANE_WIDTH, 0),
    },
    external = {
      stretch = 1,
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          autoSize = false,
          relativeSize = util.vector2(1.0, 1.0),
        },
        external = {
          stretch = 1,
          grow = 1,
        },
        content = ui.content {
          Header(),
          -- {external = { grow = 0.2 }},
          Body(),
          -- {external = { grow = 0.2 }},
          Footer,
          -- {external = { grow = 0.2 }},
        }
      }
    }
  }
end

return RightPanel
