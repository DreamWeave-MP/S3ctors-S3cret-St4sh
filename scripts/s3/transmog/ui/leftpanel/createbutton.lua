local async = require('openmw.async')

local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')

return function()
  local button = common.createButton("Create")
  button.events.mousePress = async:callback(I.transmogActions.acceptTransmog)
  if not I.transmogActions.message.createExplain then
    common.messageBoxSingleton("Create Explanation", "Press the create button or press enter to confirm the glamour.", 2)
  end
  I.transmogActions.message.createExplain = true
  return button
end
