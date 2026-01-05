local async = require("openmw.async")
local input = require("openmw.input")
local self = require('openmw.self')
local time = require('openmw_aux.time')
local types = require('openmw.types')

local I = require("openmw.interfaces")

local common = require("scripts.s3.transmog.ui.common")
local MainWidget = require('scripts.s3.transmog.ui.mainwidget')
local ConfirmScreen = require('scripts.s3.transmog.ui.leftpanel.glamourbutton').createCallback

local mogBinds = require('openmw.storage').playerSection('Settingss3_transmogMenuGroup'):asTable()

local group = {
  rotateStopFn = nil,
}

-- Use this key to finish the 'mog
-- Only if either of the two relevant menus is open
-- Guess we'll also need to do this for enhancements as well.
-- I decided I like doing it this way better than attaching
-- callbacks to the widget directly because I can't actually correlate a keybind to a widget there
group.transmogMenuConfirmImpl = function()
  if common.isVisible('main menu') then
    ConfirmScreen()
  elseif common.isVisible('confirm screen') then
    I.transmogActions.acceptTransmog()
  end
end


local function rotateWarning()
  local messageStore = I.transmogActions.message
  if messageStore.hasShowedControls then return end
  common.messageBoxSingleton("Rotate Warning", "Use the "
                             .. string.upper(mogBinds.SettingsTransmogMenuRotateRight)
                             ..  " and " .. string.upper(mogBinds.SettingsTransmogMenuRotateLeft)
                             .. " keys to rotate your character.", 2)
  common.messageBoxSingleton("Confirm Warning", "Confirm your choices with the "
                             .. string.upper(mogBinds.SettingsTransmogMenuKeyConfirm) .. " key", 2)
  messageStore.hasShowedControls = true
end

group.rotateImpl = function(isLeft)
  if not common.isVisible('main menu') and not common.isVisible('confirm screen') then
    if group.rotateStopFn then group.rotateStopFn() end
    return
  end

  local targetAction = isLeft and "transmogMenuRotateLeft" or "transmogMenuRotateRight"
  local targetChange = isLeft and -common.const.CHAR_ROTATE_SPEED or common.const.CHAR_ROTATE_SPEED

  if not input.getBooleanActionValue(targetAction) and group.rotateStopFn then
    group.rotateStopFn()
  else
    if group.rotateStopFn then group.rotateStopFn() end
    group.rotateStopFn = time.runRepeatedly(function() self.controls.yawChange = targetChange end, 0.1, {})
  end
end

local prevStance = nil
-- Now we set up the callback
group.menuStateSwitch = function()
  if not I.transmogActions.canMog() then return end
  local Aliases = I.transmogActions.MenuAliases
  local mainMenu = Aliases('main menu')

  self:sendEvent('switchTransmogMenu')

  if not mainMenu then
    MainWidget()
    common.updateOriginalEquipment()
    prevStance = types.Actor.getStance(self)
    rotateWarning()
    return
  end

  local mainIsVisible = not common.isVisible('main menu')
  mainMenu.layout.props.visible = mainIsVisible

  if mainIsVisible then
    prevStance = types.Actor.getStance(self)
    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    rotateWarning()
    self:sendEvent('updateInventoryContainer', {resetPortraits = true, updateEquipment = true})
  else
    I.transmogActions.message.hasShowedPreviewWarning = false
    types.Actor.setEquipment(self, Aliases()['original equipment'])
    types.Actor.setStance(self, prevStance)
    mainMenu:update()
  end

  if common.isVisible('tooltip') then
    I.transmogActions.message.toolTip.layout.props.visible = false
    I.transmogActions.message.toolTip:update()
  end
end

-- And this is where we actually bind the action to the callback
-- Do it on a delay so we wait for the interface to be ready
group.registerActions = function()
  if not I.transmogActions then async:newUnsavableGameTimer(1, async:callback(group.registerActions)) return end
  input.registerActionHandler("transmogMenuActivePreview", async:callback(function() self:sendEvent('updatePreview') end))
  input.registerActionHandler("transmogMenuRotateLeft", async:callback(function() group.rotateImpl(true) end))
  input.registerActionHandler("transmogMenuRotateRight", async:callback(function() group.rotateImpl(false) end))
  input.registerTriggerHandler("transmogMenuConfirm", async:callback(group.transmogMenuConfirmImpl))
  input.registerTriggerHandler("transmogMenuOpen", async:callback(group.menuStateSwitch))
end

group.registerActions()
