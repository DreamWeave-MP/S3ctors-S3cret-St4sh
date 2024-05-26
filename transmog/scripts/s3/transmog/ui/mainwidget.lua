-- Interfaces first
local templates = require('openmw.interfaces').MWUI.templates
-- System code after
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
-- Local code after
local common = require('scripts.s3.transmog.ui.common')
local LeftPanel = require('scripts.s3.transmog.ui.leftpanel.main')
local RightPanel = require('scripts.s3.transmog.ui.rightpanel.main')
-- Local vars after
local const = common.const
local sizes = require('scripts.s3.transmog.const.size')

local function getWidgetOrigin()
  local resCenter = ui.screenSize().x / 2
  local widgetWidth = const.RIGHT_PANE_WIDTH + const.LEFT_PANE_WIDTH + 4 -- we toss an extra 4px for the border
  local widgetOriginAbsolute = resCenter - widgetWidth
  local widgetOriginRelative = (widgetOriginAbsolute / ui.screenSize().x) * .7
  if widgetOriginRelative < 0.1 then
    widgetOriginRelative = 0
  end
  return  widgetOriginRelative
end

-- Don't forget we need to update the inventory when we are reopened!
local function MainWidget()
  local leftPanel = LeftPanel()
  local rightPanel = RightPanel()
  I.transmogActions.menus.leftPane = leftPanel
  I.transmogActions.menus.rightPane = rightPanel
  local divisor = {
    type = ui.TYPE.Image,
    props = {
      name = "mainDivisor",
      resource = ui.texture{ path = 'textures/menu_thick_border_right' .. '.dds' },
      size = util.vector2(4, const.WINDOW_HEIGHT),
    },
  }

  I.transmogActions.menus.main = ui.create {
    layer = 'HUD',
    template = templates.boxTransparentThick,
    props = {
      relativePosition = util.vector2(getWidgetOrigin(), 0.5),
      anchor = util.vector2(0, 0.5),
      visible = true, -- Not strictly needed, but we do this
      -- because if you don't set it, it's nil
      -- and then when you try to disable the widget, it's made visible
      -- (because you inverted the result of the nil)
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          horizontal = true,
          size = util.vector2(0, sizes.WINDOW_HEIGHT),
        },
        content = ui.content {
          leftPanel,
          divisor,
          rightPanel,
        }
      }
    }
  }
end

return MainWidget
