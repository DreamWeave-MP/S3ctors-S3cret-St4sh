local ui = require('openmw.ui')

local Body = require('scripts.s3.transmog.ui.rightpanel.body')
local Footer = require('scripts.s3.transmog.ui.rightpanel.footer')
local Header = require('scripts.s3.transmog.ui.rightpanel.header')

local function RightPanel()
  return {
    name = "Right Pane",
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
    },
    external = { stretch = 1, grow = 1, },
    content = ui.content {
      Header,
      Body(),
      Footer,
    }
  }
end

return RightPanel
