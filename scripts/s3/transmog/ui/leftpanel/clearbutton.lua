local async = require('openmw.async')

local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')

return function()
  local button = common.createButton("Clear")
  button.events.mousePress = async:callback(function()
      local confirmScreen = I.transmogActions.message.confirmScreen
      if confirmScreen.layout.content[2].content[1].props.text == "" then return end
      confirmScreen.layout.content[2].content[1].props.text = ""
      confirmScreen:update()
      end)
  return button
end
