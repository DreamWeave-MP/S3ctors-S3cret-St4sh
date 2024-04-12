local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')

local const = require('scripts.s3.transmog.ui.common').const
local CancelButton = require('scripts.s3.transmog.ui.leftpanel.cancelbutton')
local CreateButton = require('scripts.s3.transmog.ui.leftpanel.createbutton')
local I = require('openmw.interfaces')

return function(itemData)
  I.transmogActions.message.confirmScreen = true
  return {
    type = ui.TYPE.Flex,
    layer = 'HUD',
    props = {
      name = "Confirm Screen",
      size = util.vector2(512, 256),
      relativePosition = util.vector2(0.5, 0.5),
      anchor = util.vector2(0.5, 0.5),
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        props = {
          text = "Pick a name and confirm",
          size = util.vector2(256, 64),
          textColor = const.TEXT_COLOR,
          textSize = const.FONT_SIZE + 2,
          textAlignH = ui.ALIGNMENT.Center,
          autoSize = false,
        }
      },
      {
        template = I.MWUI.templates.boxSolidThick,
        props = {
          name = "Name Input Box",
        },
        content = ui.content {
          {
            type = ui.TYPE.TextEdit,
            events = {
              textChanged = async:callback(
                function (text, layout)
                  layout.props.text = text
                end)
            },
            props = {
              name = "Name Input",
              size = util.vector2(384, 32),
              textSize = const.FONT_SIZE,
              text = itemData.record.name,
              textColor = const.TEXT_COLOR,
              textAlignH = ui.ALIGNMENT.Center,
              textAlignV = ui.ALIGNMENT.Center,
              autoSize = false,
            }
          }
        }
      },
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Confirm Screen Buttons",
          size = util.vector2(256, 64),
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        content = ui.content {
          CancelButton(),
          { external = { grow = 1 } },
          CreateButton(),
        }
      }
    }
  }
end
