local I = require('openmw.interfaces')
local common = require('scripts.s3.transmog.ui.common')
local input = require('openmw.input')

--- Intercept attempts to reopen the HUD and override them while 'mogging
--- @param isHud boolean: AND result of the input action
local function forceCloseHud(isHud)
  if isHud and I.UI.isHudVisible() and (common.mainIsVisible() or common.confirmIsVisible())
  then I.UI.setHudVisibility(false)
  end
end

return {
  engineHandlers = {
    onInputAction = function(action)
      forceCloseHud(action == input.ACTION.ToggleHUD)
    end,
  },
}
