local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')

return function()
  local button = common.createButton("Cancel")
  button.events.mousePress = async:callback(
    function (_, _layout)
      I.transmogActions.message.confirmScreen:destroy()
      I.transmogActions.message.confirmScreen = nil
      I.transmogActions.menu.layout.props.visible = true
      I.transmogActions.menu:update()
    end)
  return button
end
