---@omw-context player

local require = require

local Enum = require 'scripts.s3.dr1p.enum'
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

cameraRebuild:state('idle', function()
  local isFirstPerson = GetCameraMode() == FirstPersonMode
  if isFirstPerson == wasFirstPerson then return end

  wasFirstPerson = isFirstPerson
  cameraRebuild:transition 'perspective_barrier'
end)

cameraRebuild:state('perspective_barrier', function()
  Runtime.addRing(Enum.Hand.Left, Enum.Finger.Index, false)
  cameraRebuild:transition 'idle'
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
  Runtime.addRing(Enum.Hand.Left, Enum.Finger.Index, false)
  cameraRebuild:jump 'idle'
end)

cameraRebuild:start 'idle'

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
    onFrame = function() cameraRebuild:tick() end,
    onKeyPress = function(key)
      if key.symbol ~= ' ' or not key.withShift then return end
      section:set('RELOAD', true)
      ReloadLua()
    end,
  },
  interfaceName = PublicInterface.interfaceName,
  interface = PublicInterface.interface,
}
