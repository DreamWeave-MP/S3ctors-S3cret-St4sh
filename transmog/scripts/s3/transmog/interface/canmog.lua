local self = require('openmw.self')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local common = require('scripts.s3.transmog.ui.common')

local function canMog()
  local messageStore = I.transmogActions.message
    if not types.Actor.isOnGround(self) then
      if not messageStore.cantUseControls then
        messageStore.cantUseControls = true
        common.messageBoxSingleton("Ground Warning", "You must be on the ground to use the glamour menu!", 2)
      end
      return false
    elseif types.Actor.isSwimming(self) then
      if not messageStore.cantUseSwimming then
        messageStore.cantUseSwimming = true
        common.messageBoxSingleton("Swimming Warning", "You use the glamour menu while swimming!", 2)
      end
      return false
    elseif I.UI.getMode() == I.UI.MODE.MainMenu then
      if not messageStore.cantUseMainMenu then
        messageStore.message.cantUseMainMenu = true
        common.messageBoxSingleton("Main Menu Warning", "You must not be in the main menu to use the glamour menu!", 2)
      end
      return false
    elseif I.transmogActions.consoleOpen then
      if not messageStore.cantUseConsole then
        messageStore.cantUseConsole = true
        common.messageBoxSingleton("Console Warning", "You must close the console before opening the glamour menu!", 2)
      end
      return false
    elseif common.isVisible('confirm screen') then
      if not messageStore.cantUseConfirm then
        messageStore.cantUseConfirm = true
        common.messageBoxSingleton("Confirm Warning", "You must confirm or cancel your current choices before opening the glamour menu!", 2)
      end
      return false
    end
    return true
end

return {
  interface = {
    canMog = canMog
  }
}
