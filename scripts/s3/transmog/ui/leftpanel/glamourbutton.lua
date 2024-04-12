local async = require("openmw.async")
local common = require("scripts.s3.transmog.ui.common")
local ui = require("openmw.ui")

local I = require("openmw.interfaces")

local ConfirmScreen = require("scripts.s3.transmog.ui.leftpanel.confirmscreen")

local _confirmScreen = {}

_confirmScreen.createCallback = function()
  local baseItem = I.transmogActions.baseItemContainer.content[2].userData
  local newItem = I.transmogActions.newItemContainer.content[2].userData
  if baseItem and newItem then
    if not I.transmogActions.message.confirmScreen then
      I.transmogActions.message.confirmScreen = ui.create(ConfirmScreen(baseItem))
      I.transmogActions.menu.layout.props.visible = false
      I.transmogActions.menu:update()
    end
  else
    common.messageBoxSingleton("No Glamour Warning", "You must choose two items!")
  end
end

_confirmScreen.createButton = function()
  local button = common.createButton("Apply Glamour")
  button.events.mousePress = async:callback(_confirmScreen.createCallback)
  return button
end

return _confirmScreen
