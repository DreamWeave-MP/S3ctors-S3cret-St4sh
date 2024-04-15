local I = require('openmw.interfaces')
local common = require('scripts.s3.transmog.ui.common')
local input = require('openmw.input')
return {
  engineHandlers = {
    onInputAction = function(action)
        -- Intercept attempts to reopen the HUD and override them while 'mogging
        -- Not sure if this one can be made into an action?
      if action == input.ACTION.ToggleHUD
        and I.UI.isHudVisible()
        and (common.mainIsVisible() or common.confirmIsVisible()) then
        print('overriding hud input')
          I.UI.setHudVisibility(false)
      end
    end,
  },
}
