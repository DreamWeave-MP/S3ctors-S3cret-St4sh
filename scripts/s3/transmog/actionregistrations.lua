local async = require("openmw.async")
local input = require("openmw.input")
local self = require('openmw.self')
local time = require('openmw_aux.time')

local I = require("openmw.interfaces")

local common = require("scripts.s3.transmog.ui.common")
local ConfirmScreen = require('scripts.s3.transmog.ui.leftpanel.glamourbutton').createCallback

local group = {
  rotateStopFn = nil,
}

-- Use this key to finish the 'mog
-- Only if either of the two relevant menus is open
-- Guess we'll also need to do this for enhancements as well.
-- I decided I like doing it this way better than attaching
-- callbacks to the widget directly because I can't actually correlate a keybind to a widget there
group.transmogMenuConfirmImpl = function()
  if common.mainIsVisible() then
    ConfirmScreen()
  elseif common.confirmIsVisible() then
    I.transmogActions.acceptTransmog()
  end
end

group.rotateImpl = function(isLeft)
  if not common.mainIsVisible() and not common.confirmIsVisible() then
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

-- And this is where we actually bind the action to the callback
-- Do it on a delay so we wait for the interface to be ready
group.registerActions = function()
  if not I.transmogActions then async:newUnsavableGameTimer(1, async:callback(group.registerActions)) return end
  input.registerActionHandler("transmogMenuActivePreview", async:callback(I.transmogActions.updatePreview))
  input.registerActionHandler("transmogMenuRotateLeft", async:callback(function() group.rotateImpl(true) end))
  input.registerActionHandler("transmogMenuRotateRight", async:callback(function() group.rotateImpl(false) end))
  input.registerTriggerHandler("transmogMenuConfirm", async:callback(group.transmogMenuConfirmImpl))
  input.registerTriggerHandler("transmogMenuOpen", async:callback(I.transmogActions.menuStateSwitch))
end

group.registerActions()
