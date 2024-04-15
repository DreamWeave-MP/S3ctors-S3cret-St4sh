local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local const = common.const
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')

-- This contains the items to be modified
-- It's composed of a flex container with two elements - the image and the text
-- We specify its elements should be centered and it has a max width of 200px
local function ItemPortraitContainer(widgetName)
  return {
    type = ui.TYPE.Flex,
    props = {
      name = widgetName,
      size = util.vector2(const.LEFT_PANE_WIDTH, 0),
      arrange = ui.ALIGNMENT.Center,
    },
    events = {
      mousePress = async:callback(
        function (_, layout)
          local name = layout.props.name

          if name ~= "Default" then
            layout.content = ui.content(common.defaultPortraitContent())
            I.transmogActions.menus.main:update()
            if name == "New Item" then
              types.Actor.setEquipment(self, I.transmogActions.menus.originalInventory)
            end
          end
      end)
    },
    content = ui.content {
      common.portraitDefault(),
      common.portraitTextDefault(),
    },
  }
end

return ItemPortraitContainer
