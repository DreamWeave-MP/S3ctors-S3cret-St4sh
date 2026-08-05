---@omw-context player

local require = require

local MakeEquipmentTracker = require 'scripts.s3.dr1p.equipment'
local MakeInterface = require 'scripts.s3.dr1p.interface'
local MakeRuntime = require 'scripts.s3.dr1p.runtime'
local StateMachine = require 'scripts.s3.statemachine'

local s3lf = require('openmw.interfaces').s3.lf
local camera = require 'openmw.camera'
local storage = require 'openmw.storage'

local FirstPersonMode, GetCameraMode, ReloadLua, SetCameraMode, ThirdPersonMode =
  camera.MODE.FirstPerson,
  camera.getMode,
  require('openmw.debug').reloadLua,
  camera.setMode,
  camera.MODE.ThirdPerson

---@type DR1PRuntime
local Runtime = MakeRuntime(function() return GetCameraMode() == FirstPersonMode end)

---@type DR1PEquipmentTracker
local Equipment = MakeEquipmentTracker(Runtime)

---@type DR1PInterfaceDefinition
local PublicInterface = MakeInterface(Runtime)

local wasFirstPerson = false
---@type openmw.camera.Mode
local detourMode, restoreMode
local cameraRebuild = StateMachine.new()

---@param newDetourMode openmw.camera.Mode
---@param newRestoreMode openmw.camera.Mode
local function beginRebuild(newDetourMode, newRestoreMode)
  detourMode = newDetourMode
  restoreMode = newRestoreMode
  cameraRebuild:jump 'detour'
end

cameraRebuild:state('equipment_check', function()
  Equipment.checkNextSlot()
  cameraRebuild:transition 'camera_check'
end)

cameraRebuild:state('camera_check', function()
  local isFirstPerson = GetCameraMode() == FirstPersonMode
  if isFirstPerson == wasFirstPerson then
    cameraRebuild:transition 'equipment_check'
    return
  end

  wasFirstPerson = isFirstPerson
  cameraRebuild:transition 'perspective_barrier'
end)

cameraRebuild:state('perspective_barrier', function()
  Equipment.reapplyTrackedVfx()
  cameraRebuild:transition 'equipment_check'
end)

cameraRebuild:state('detour', {
  on_enter = function() SetCameraMode(detourMode, true) end,
  tick = function()
    if GetCameraMode() == detourMode then cameraRebuild:transition 'detour_barrier' end
  end,
})

cameraRebuild:state('detour_barrier', function() cameraRebuild:transition 'restore' end)

cameraRebuild:state('restore', {
  on_enter = function() SetCameraMode(restoreMode, true) end,
  tick = function()
    if GetCameraMode() == restoreMode then cameraRebuild:transition 'restore_barrier' end
  end,
})

cameraRebuild:state('restore_barrier', function()
  wasFirstPerson = restoreMode == FirstPersonMode
  Equipment.reapplyTrackedVfx()
  cameraRebuild:jump 'equipment_check'
end)

cameraRebuild:start 'equipment_check'

local section = storage.playerSection 'DR1PTESTSTORAGE'

if section:get 'RELOAD' then
  if GetCameraMode() == FirstPersonMode then
    s3lf.sendObjectEvent 'DR1PSetThird'
  else
    s3lf.sendObjectEvent 'DR1PSetFirst'
  end

  section:set('RELOAD', false)
end

return {
  eventHandlers = {
    DR1PSetFirst = function() beginRebuild(FirstPersonMode, ThirdPersonMode) end,
    DR1PSetThird = function() beginRebuild(ThirdPersonMode, FirstPersonMode) end,
  },
  engineHandlers = {
    onLoad = function(data) Equipment.onLoad(data and data.equipment) end,
    onFrame = function() cameraRebuild:tick() end,
    onKeyPress = function(key)
      if key.symbol ~= ' ' or not key.withShift then return end
      section:set('RELOAD', true)
      ReloadLua()
    end,
    onSave = function() return { equipment = Equipment.onSave() } end,
  },
  interfaceName = PublicInterface.interfaceName,
  interface = PublicInterface.interface,
}
