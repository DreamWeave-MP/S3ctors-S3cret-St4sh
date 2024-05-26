local async = require('openmw.async')

local common = require('scripts.s3.transmog.ui.common')

local I = require('openmw.interfaces')

local playerSettings = require('openmw.storage').playerSection('Settingss3_transmogMenuGroup'):asTable()

return function()
  local button = common.createButton("Create")
  button.events.mousePress = async:callback(I.transmogActions.acceptTransmog)
  if not I.transmogActions.message.createExplain then
    common.messageBoxSingleton("Confirm Explanation",
                               "Click the confirm button \nor press the "
                               .. string.upper(playerSettings.SettingsTransmogMenuKeyConfirm)
                               .. " key to apply the glamour.", 2)
    common.messageBoxSingleton("Create Explanation", "Close with cancel or the escape key.", 2)
  end
  I.transmogActions.message.createExplain = true
  return button
end
