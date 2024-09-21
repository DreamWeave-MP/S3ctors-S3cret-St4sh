local ui = require('openmw.ui')
local util = require('openmw.util')

local const = require('scripts.s3.transmog.ui.common').const
local NameInputBox = require('scripts.s3.transmog.ui.leftpanel.nameinputbox')
local CancelButton = require('scripts.s3.transmog.ui.leftpanel.cancelbutton')
local ClearButton = require('scripts.s3.transmog.ui.leftpanel.clearbutton')
local CreateButton = require('scripts.s3.transmog.ui.leftpanel.createbutton')
local I = require('openmw.interfaces')

return function(itemData)
  local nameInputBox = NameInputBox.new(itemData)
  nameInputBox.props.inheritAlpha = false
  local confirmScreen = {
    type = ui.TYPE.Flex,
    layer = 'HUD',
    props = {
      name = "Confirm Screen",
      relativeSize = util.vector2(.25, .25),
      relativePosition = util.vector2(0.5, 0.5),
      anchor = util.vector2(0.5, 0.5),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      visible = true,
      autoSize = false,
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        props = {
          text = "Pick a name and confirm",
          relativeSize = util.vector2(1, .15),
          textColor = const.TEXT_COLOR,
          textSize = const.FONT_SIZE + 2,
          textAlignH = ui.ALIGNMENT.Center,
          autoSize = false,
        }
      },
      {
        template = I.MWUI.templates.bordersThick,
        props = {
          relativeSize = util.vector2(.8, .15),
        },
        content = ui.content {
          {
            type = ui.TYPE.Image,
            props = {
              name = "Name Input Box",
              relativeSize = util.vector2(1, 1),
              resource = ui.texture { path = 'white' },
              color = util.color.rgb(0, 0, 0),
              alpha = .5,
            },
            content = ui.content {
              nameInputBox,
            }
          },
        },
      },
      {
        type = ui.TYPE.Flex,
        props = {
          name = "Confirm Screen Buttons",
          relativeSize = util.vector2(.75, .45),
          arrange = ui.ALIGNMENT.Center,
          align = ui.ALIGNMENT.Center,
          horizontal = true,
        },
        content = ui.content {
          CancelButton(),
          { external = { grow = 1 } },
          ClearButton(),
          { external = { grow = 1 } },
          CreateButton(),
        }
      }
    }
  }
  I.transmogActions.menus.confirmScreenInput = nameInputBox
  I.transmogActions.menus.confirmScreen = confirmScreen
  return confirmScreen
end
