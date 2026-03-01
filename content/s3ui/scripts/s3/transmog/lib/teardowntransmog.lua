local self = require('openmw.self')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local common = require('scripts.s3.transmog.ui.common')

--- Restores the user interface to its original state and force-closes the transmog menu
--- @field prevStance types.Actor.STANCE
local function tearDownTransmog(prevStance)
  if not common.isVisible('main menu') then error('glamour menu is already closed, ignoring teardown request') end

  if common.isVisible('tooltip') then
    I.transmogActions.message.toolTip.layout.props.visible = false
    I.transmogActions.message.toolTip:update()
  end

  self:sendEvent('switchTransmogMenu')
  I.transmogActions.message.hasShowedPreviewWarning = false
  types.Actor.setEquipment(self, I.transmogActions.originalEquipment)
  types.Actor.setStance(self, prevStance or types.Actor.STANCE.Nothing)

  local mainMenu = I.transmogActions.MenuAliases('main menu')
  if not mainMenu then error('main menu not found') end

  mainMenu.layout.props.visible = false
  mainMenu:update()
end

return tearDownTransmog
