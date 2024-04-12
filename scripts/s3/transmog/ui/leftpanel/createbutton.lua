local async = require('openmw.async')

local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')

local playerSettings = require('openmw.storage').playerSection('Settingss3_transmogMenuGroup'):asTable()

return function()
  local button = common.createButton("Create")
  button.events.mousePress = async:callback(I.transmogActions.acceptTransmog)
  if not I.transmogActions.message.createExplain then
    common.messageBoxSingleton("Confirm Explanation",
                               "Click the confirm button or press the "
                               .. string.upper(playerSettings.TransmogMenuConfirm)
                               .. " key to apply the glamour.\n"
                               .. "Close with cancel or the escape key.", 1)
  end
  I.transmogActions.message.createExplain = true
  return button
end
