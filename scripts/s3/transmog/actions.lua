local I = require('openmw.interfaces')

local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local camera = require('openmw.camera')
local common = require('scripts.s3.transmog.ui.common')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local MainWidget = require('scripts.s3.transmog.ui.mainwidget')
local ItemContainer = require('scripts.s3.transmog.ui.rightpanel.itemcontainer')

local playerSettings = storage.playerSection('Settingss3_transmogMenuGroup'):asTable()

local prevCam = nil
local prevStance = nil
local rotateStopFn = {
  funcLeft = nil,
  funcRight = nil,
}

local outInterface = {
  message = {},
  consoleOpen = false,
  messageBox = common.messageBoxSingleton,
}

local function rotateWarning()
  common.messageBoxSingleton("Rotate Warning", "Use the "
                             .. string.upper(playerSettings.TransmogMenuRotateRight)
                             ..  " and " .. string.upper(playerSettings.TransmogMenuRotateLeft)
                             .. " keys to rotate your character")
end

outInterface.restoreUserInterface = function()
  if prevCam then
    types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Controls, true)
    types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Looking, true)
    I.Controls.overrideUiControls(false)
    camera.showCrosshair(true)
    camera.setMode(prevCam)
    I.UI.setHudVisibility(true)
    I.UI.setPauseOnMode(I.UI.MODE.Interface, true)
    I.UI.setMode()
    prevCam = nil
  end
end

-- Now we set up the callback
local menuStateSwitch = async:callback(function()
    if not input.getBooleanActionValue("transmogMenuKey")
      or not types.Actor.isOnGround(self)
      or types.Actor.isSwimming(self)
      or outInterface.message.confirmScreen
      or I.UI.getMode() == I.UI.MODE.MainMenu
      or outInterface.consoleOpen
    then return end

    if not prevCam then
      types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Controls, false)
      types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Looking, false)
      I.Controls.overrideUiControls(true)
      self.controls.sneak = false -- This is a special case, it's not covered by the control switch
      camera.showCrosshair(false)
      camera.setYaw(3.14)
      camera.setPitch(0)
      camera.setRoll(0)
      prevCam = camera.getMode()
      camera.setMode(camera.MODE.Static)
      camera.setStaticPosition(self.position + util.vector3(25, 75, 75))
      I.UI.setHudVisibility(false)
      I.UI.setPauseOnMode(I.UI.MODE.Interface, false)
      I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    else
      outInterface.restoreUserInterface()
    end

    if not outInterface.menu then
      outInterface.menu = MainWidget()
      outInterface.leftPane = outInterface.menu.layout.content[1].content[1]
      outInterface.rightPane = outInterface.menu.layout.content[1].content[3]
      outInterface.baseItemContainer = outInterface.leftPane.content[2]
      outInterface.newItemContainer = outInterface.leftPane.content[4]
      outInterface.itemContainer = outInterface.rightPane.content[1].content[3].content[1].content[1]
      outInterface.originalInventory = types.Actor.getEquipment(self)
      outInterface.message.singleton = nil
      outInterface.message.confirmScreen = nil
      outInterface.message.hasShowedPreviewWarning = false
      prevStance = types.Actor.getStance(self)
      rotateWarning()
    else
      outInterface.menu.layout.props.visible = not outInterface.menu.layout.props.visible
      if outInterface.menu.layout.props.visible then
        common.resetPortraits()
        outInterface.itemContainer.content = ui.content(ItemContainer.updateContent("Apparel"))
        outInterface.originalInventory = types.Actor.getEquipment(self)
        prevStance = types.Actor.getStance(self)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        rotateWarning()
      else
        outInterface.message.hasShowedPreviewWarning = false
        types.Actor.setEquipment(self, outInterface.originalInventory)
        types.Actor.setStance(self, prevStance)
      end
      outInterface.menu:update()
    end
end)

input.registerActionHandler("transmogMenuRotateRight", async:callback(function()
    if not outInterface.menu or outInterface.message.confirmScreen or not outInterface.menu.layout.props.visible then return end
    if not input.getBooleanActionValue("transmogMenuRotateRight") and rotateStopFn.funcRight then
        rotateStopFn.funcRight()
        return
    end
    rotateStopFn.funcRight = time.runRepeatedly(function()
                                             self.controls.yawChange = 0.3
    end,
      0.1,
      {})
end))

input.registerActionHandler("transmogMenuRotateLeft", async:callback(function()
    if not outInterface.menu or outInterface.message.confirmScreen or not outInterface.menu.layout.props.visible then return end
    if not input.getBooleanActionValue("transmogMenuRotateLeft") and rotateStopFn.funcLeft then
        rotateStopFn.funcLeft()
        return
    end

    rotateStopFn.funcLeft = time.runRepeatedly(function()
        self.controls.yawChange = -0.3
    end,
      0.1,
      {})
end))

-- And this is where we actually bind the action to the callback
input.registerActionHandler("transmogMenuKey", menuStateSwitch)

local consolePressed = false

return {
  interface = outInterface,
  interfaceName = 'transmogActions',
  engineHandlers = {
    onFrame = function()
      -- Close the menu if opened and the escape key is pressed
      -- also track closures of the console via escape (which fortunately seems hardcoded)
      if input.isKeyPressed(input.KEY.Escape) then
        if outInterface.consoleOpen then
          outInterface.consoleOpen = false
        end
        if outInterface.menu and outInterface.menu.layout.props.visible then
          common.teardownTransmog(prevStance)
        end
        return
      end

      if input.isActionPressed(input.ACTION.Console) and not consolePressed then
        consolePressed = true
      end

      -- Intercept attemtps to reopen the HUD and override them
      if input.isActionPressed(input.ACTION.ToggleHUD)
        and I.UI.isHudVisible()
        and outInterface.menu
        and outInterface.menu.layout.props.visible then
        I.UI.setHudVisibility(false)
      end

      -- close the menu if the console is opened
      if consolePressed and not input.isActionPressed(input.ACTION.Console) then
        consolePressed = false
        outInterface.consoleOpen = not outInterface.consoleOpen
        if outInterface.consoleOpen
          and outInterface.menu
          and outInterface.menu.layout.props.visible then
          common.teardownTransmog(prevStance)
        end
      end
    end,
  }
}
