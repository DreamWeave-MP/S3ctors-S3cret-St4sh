local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')
local Aliases = require('scripts.s3.transmog.ui.menualiases')

return function()
  local button = common.createButton("Cancel")
  button.events.mousePress = async:callback(
    function (_, _layout)
      local mainMenu = Aliases('main menu')
      I.transmogActions.menus.confirmScreen.layout.props.visible = false
      I.transmogActions.menus.confirmScreen:update()
      mainMenu.layout.props.visible = true
      mainMenu:update()
    end)
  return button
end
