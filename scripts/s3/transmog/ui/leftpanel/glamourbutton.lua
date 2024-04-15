local async = require("openmw.async")
local common = require("scripts.s3.transmog.ui.common")
local ui = require("openmw.ui")

local I = require("openmw.interfaces")

local ConfirmScreen = require("scripts.s3.transmog.ui.leftpanel.confirmscreen")

local _confirmScreen = {}

_confirmScreen.createCallback = function()
  local baseItem = I.transmogActions.menus.baseItemContainer.content[2].userData
  local newItem = I.transmogActions.menus.newItemContainer.content[2].userData
  if baseItem and newItem then
    if not I.transmogActions.message.confirmScreen then
      I.transmogActions.message.confirmScreen = ui.create(ConfirmScreen(baseItem))
    elseif not I.transmogActions.message.confirmScreen.layout.props.visible then
      I.transmogActions.message.confirmScreen.layout.props.visible = true
      I.transmogActions.message.confirmScreen.layout.content[2].content[1].props.text = baseItem.record.name
      I.transmogActions.message.confirmScreen:update()
    end
    I.transmogActions.message.toolTip.layout.props.visible = false
    common.mainMenu().layout.props.visible = false
    I.transmogActions.message.toolTip:update()
    common.mainMenu():update()
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
