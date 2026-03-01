local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local templates = I.MWUI.templates

-- local LeftPanel = require('scripts.s3.transmog.ui.leftpanel.main')
local RightPanel = require('scripts.s3.transmog.ui.rightpanel.main')

local function MainWidget()
  -- local leftPanel = LeftPanel()
  local rightPanel = RightPanel()
  -- I.transmogActions.menus.leftPane = leftPanel
  I.transmogActions.menus.rightPane = rightPanel

  local backgroundImage = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = 'white' },
      relativeSize = util.vector2(1, 1),
      alpha = .5,
      color = util.color.rgb(0, 0, 0),
    },
    external = { stretch = 1, grow = 1, },
  }

  local containerBody = {
    type = ui.TYPE.Flex,
    props = {
      autosize = false,
      horizontal = true,
      relativeSize = util.vector2(1, 1),
    },
    content = ui.content{ rightPanel }
    -- {
      -- leftPanel,
      -- { template = templates.verticalLineThick },
    -- }
  }

  local topLevelWidget = {
    layer = 'Windows',
    template = templates.bordersThick,
    props = {
      anchor = util.vector2(0, .5),
      relativePosition = util.vector2(0, 0.5),
      relativeSize = util.vector2(.5, 1),
      visible = true,
    },
    content = ui.content {
      backgroundImage,
      containerBody,
    }
  }

  I.transmogActions.menus.main = ui.create(topLevelWidget)
end

return MainWidget
