---@omw-context player

local async = require 'openmw.async'
local aux_util = require 'openmw_aux.util'
local camera = require 'openmw.camera'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf, GetUIMode = I.s3.lf, I.UI.getMode

local CastRay = nearby.castRay
local GetBoundingBox, Vec3Normalize = s3lf.getBoundingBox, s3lf.position.normalize
local GetCamPitch, GetCamPosition, GetCamYaw, SetCamPitch, SetCamYaw, GetTrackedPosition =
  camera.getPitch,
  camera.getPosition,
  camera.getYaw,
  camera.setPitch,
  camera.setYaw,
  camera.getTrackedPosition
local SetCamStaticPosition, GetCamMode, SetCamMode, CamInstantTransition =
  camera.setStaticPosition, camera.getMode, camera.setMode, camera.instantTransition
local GetFocalOffset, SetFocalOffset =
  camera.getFocalPreferredOffset, camera.setFocalPreferredOffset

local GetPitch, GetStance, GetYaw, Health, IsActor, IsDead =
  s3lf.rotation.getPitch,
  types.Actor.getStance,
  s3lf.rotation.getYaw,
  types.Actor.stats.dynamic.health,
  types.Actor.objectIsInstance,
  types.Actor.isDead

local RGBColor = util.color.rgb

local SLOT_WEAPON = s3lf.EQUIPMENT_SLOT.CarriedRight

local STANCE_NONE, STANCE_SPELL, STANCE_WEAPON =
  s3lf.STANCE.Nothing, s3lf.STANCE.Spell, s3lf.STANCE.Weapon

local ModInfo = require 'scripts.s3.target.modinfo'

local Abs, Atan2, Cos, Max, Min, Rad, Sin, Sqrt =
  math.abs, math.atan2, math.cos, math.max, math.min, math.rad, math.sin, math.sqrt

local StrFormat, TableRemove = string.format, table.remove

local Clamp, NormalizeAngle, Remap, Round =
    --- Use Rubic0n extensions or OpenMW built-ins
  --- But why the fuck doesn't my rubic0nMeta folder work?
  ---@diagnostic disable-next-line: undefined-field
math.clamp or util.clamp,
  ---@diagnostic disable-next-line: undefined-field
  math.normalizeAngle or util.normalizeAngle,
  math.remap or util.remap,
  ---@diagnostic disable-next-line: undefined-field
  math.round or util.round

local Vector2, Vector3 = util.vector2, util.vector3
local CenterVector2 = Vector2(0.5, 0.5)
local ZeroVector2 = Vector2(0, 0)
local Vec2Len = CenterVector2.length
local UpVec3 = Vector3(0, 0, 1)
local Vec3Cross = UpVec3.cross

---@type fun(element: openmw.ui.Element)
local UIUpdate

local MaxRot, MaxPitchRot = Rad(12.0), Rad(10.0)

local NPC_HEIGHT_OFFSET = 1.6

local CAM_DISTANCE = 120
local CAM_HEIGHT = 25
local CAM_SIDE_OFFSET = 90
local CAM_SIDE_LERP_SPEED = 0.1

local EPS = 0.001

local RayOpts = { ignore = { gameSelf } }

local ActiveCombatTargets = {}

local function isWielding() return s3lf.getStance() ~= STANCE_NONE end

--- TODO: Make a subscript function to reconstruct the vectors for the size remapping instead of reconstructing vectors on every call expensive!
--- Refer to globalSettings.lua for field default values
---
---@class LockOnManager:ProtectedTable
---@field SwitchOnDeadTarget boolean whether or not to automatically select the nearest (screen-space) target when the current one dies
---@field CheckLOS boolean whether to use line-of-sight when deciding whether to break a target lock
---@field TargetLockIcon string baseName of the texture file used for the lock-on icon
---@field TargetMinSize integer minimum size of the target lock icon
---@field TargetMaxSize integer maximum size of the target lock icon
---@field TargetMinDistance integer Distance from the target to the camera at which the target lock icon will be minimum size
---@field TargetMaxDistance integer Distance from the target to the camera at which the target lock icon will be maximum size
---@field TargetColorF openmw.util.Color Color applied to the target icon when target has >= 100% health. Mixes with TargetColorVH below 100%.
---@field TargetColorVH openmw.util.Color Color applied to the target icon when target has 60% - 80% health. Mixes with TargetColorH below 80%.
---@field TargetColorH openmw.util.Color Color applied to the target icon when target has 40% - 60% health. Mixes with TargetColorW below 60%.
---@field TargetColorW openmw.util.Color Color applied to the target icon when target has 20% - 40% health. Mixes with TargetColorVW below 40%.
---@field TargetColorVW openmw.util.Color Color applied to the target icon when target has 0% - 20% health. Mixes with TargetColorD below 20%.
---@field TargetColorD openmw.util.Color Color applied to the target icon when target has <= 0% health.
---@field EnableFlickSwitch boolean Whether or not to allow changing targets by quickly flicking the mouse
---@field FlickSwitchDistance number how far the mouse has to move to flick-switch targets
---@field EnableHitBounce boolean Whether or not to dynamically increase the icon size when a target has been hit
---@field HitBounceSize number How much the icon size should increase/decrease when bouncing
---@field DisableLockWhenSheathing boolean whether to un-set the locked target when sheathing your own weapon
---@field LockOnCombatStart boolean whether or not to automatically lock onto whatever target started combat with you
local LockOnManager = I.S3ProtectedTable.new {
  inputGroupName = ModInfo.groupName,
  logPrefix = ModInfo.logPrefix,
  managerName = ModInfo.name,
  storageSection = require('openmw.storage').playerSection(ModInfo.groupName),
}

LockOnManager.state = {
  targetObject = nil,
  targetHealth = nil,
  npcHeightOffset = nil,
  lockOnMarker = nil,
  currentTexture = nil,
  canDoLockOn = false,
  flickTriggered = false,
  cumulativeXMove = 0,
  isBouncing = false,
  bouncedSize = 0,
  bounceUpOrDown = true,
  trackTarget = true,
  isThirdPersonLock = false,
  prevCameraMode = nil,
  prevFocalOffset = nil,
  cameraSide = 1,
}

---@alias MarkerTransform openmw.util.Vector3 info about the marker; z element is distance from camera, xy are normalized screenpos of target

---@class MarkerUpdateInfo
---@field doUpdate boolean? whether to redraw or not
---@field transform MarkerTransform Onscreen position to place the marker at

function LockOnManager.getLockOnFileName(baseName)
  return StrFormat('textures/s3/crosshair/%s.dds', baseName)
end

function LockOnManager.canLockOn() return LockOnManager.state.canDoLockOn end

---@param state boolean
function LockOnManager.setCanLockOn(state) LockOnManager.state.canDoLockOn = state end

---@param state boolean
function LockOnManager.setTrackingState(state) LockOnManager.state.trackTarget = state end

---@return boolean shouldTrack
function LockOnManager.shouldTrack() return LockOnManager.state.trackTarget end

---@param desiredYaw number
---@param desiredPitch number
---@param currentYaw number
---@param currentPitch number
function LockOnManager.getAngleDiff(desiredYaw, desiredPitch, currentYaw, currentPitch)
  local yawDiff = NormalizeAngle(desiredYaw - currentYaw)
  local pitchDiff = NormalizeAngle(desiredPitch - currentPitch)

  local finalYaw = Clamp(yawDiff * 0.6, -MaxRot, MaxRot)
  local finalPitch = Clamp(pitchDiff * 0.4, -MaxPitchRot, MaxPitchRot)

  return finalYaw, finalPitch
end

---@param targetObject openmw.LObject
---@param shouldTrack boolean
function LockOnManager.trackTarget(targetObject, shouldTrack)
  if not targetObject then return end

  local playerPos = GetCamPosition()
  local targetPos = I.S3CamHelper.targetPosition(
    targetObject,
    targetObject.position,
    LockOnManager.state.npcHeightOffset
  )
  local toTarget = Vec3Normalize(targetPos - playerPos)

  local currentYaw, currentPitch = GetCamYaw(), GetCamPitch()

  local desiredYaw = Atan2(toTarget.x, toTarget.y)
  local desiredPitch = Atan2(-toTarget.z, Sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y))

  local camYaw, camPitch =
    LockOnManager.getAngleDiff(desiredYaw, desiredPitch, currentYaw, currentPitch)

  if Abs(camYaw) >= EPS then SetCamYaw(currentYaw + camYaw) end

  if Abs(camPitch) >= EPS then SetCamPitch(currentPitch + camPitch) end

  if not shouldTrack then return end

  local rotation = s3lf.rotation
  local playerYaw, playerPitch =
    LockOnManager.getAngleDiff(desiredYaw, desiredPitch, GetYaw(rotation), GetPitch(rotation))

  if Abs(playerYaw) >= EPS then s3lf.controls.yawChange = playerYaw end

  if Abs(playerPitch) >= EPS then s3lf.controls.pitchChange = playerPitch end
end

--- Replacement over-the-shoulder camera implementation for 3P
---@param targetObject openmw.LObject
function LockOnManager.trackTargetThirdPerson(targetObject)
  local targetPos = I.S3CamHelper.targetPosition(
    targetObject,
    targetObject.position,
    LockOnManager.state.npcHeightOffset
  )

  local orbitCenter = GetTrackedPosition()

  local lookDir = Vec3Normalize(targetPos - orbitCenter)
  local right = Vec3Normalize(Vec3Cross(lookDir, UpVec3))

  local basePos = orbitCenter - lookDir * CAM_DISTANCE + UpVec3 * CAM_HEIGHT

  local rightCamPos = basePos + right * CAM_SIDE_OFFSET
  local blocked = CastRay(targetPos, rightCamPos, RayOpts).hit
  local desiredSide = blocked and -1 or 1
  local currentSide = LockOnManager.state.cameraSide or desiredSide
  currentSide = currentSide + (desiredSide - currentSide) * CAM_SIDE_LERP_SPEED
  if Abs(desiredSide - currentSide) < 0.01 then currentSide = desiredSide end
  LockOnManager.state.cameraSide = currentSide

  local desiredPos = basePos + right * CAM_SIDE_OFFSET * currentSide

  SetCamStaticPosition(desiredPos)

  local camLookDir = Vec3Normalize(targetPos - desiredPos)
  SetCamYaw(Atan2(camLookDir.x, camLookDir.y))
  SetCamPitch(Atan2(-camLookDir.z, Sqrt(camLookDir.x * camLookDir.x + camLookDir.y * camLookDir.y)))

  if LockOnManager.shouldTrack() then
    local toTarget = Vec3Normalize(targetPos - orbitCenter)
    local yaw = Atan2(toTarget.x, toTarget.y)
    local pitch = Atan2(-toTarget.z, Sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y))

    local rot = s3lf.rotation
    local yawChange, pitchChange =
      LockOnManager.getAngleDiff(yaw, pitch, GetYaw(rot), GetPitch(rot))

    if Abs(yawChange) >= EPS then s3lf.controls.yawChange = yawChange end
    if Abs(pitchChange) >= EPS then s3lf.controls.pitchChange = pitchChange end
  end
end

---@param markerUpdateData MarkerUpdateInfo
function LockOnManager:updateMarker(markerUpdateData)
  local element = assert(
    self.getLockOnMarker(),
    'LockOnManager: Failed to locate lock on marker to set its position!'
  )

  local elementSize = self:getIconSize(markerUpdateData.transform.z) + self.state.bouncedSize
  element.layout.props.size = Vector2(elementSize, elementSize)
  element.layout.props.color = self:getIconColor()

  --- Vector swizzles are legit but documenting them sucks
  ---@diagnostic disable-next-line: undefined-field
  element.layout.props.relativePosition = markerUpdateData.transform.xy

  local configuredTexture = LockOnManager.TargetLockIcon
  if configuredTexture ~= LockOnManager.state.currentTexture then
    LockOnManager.state.currentTexture = configuredTexture

    element.layout.props.resource =
      ui.texture { path = LockOnManager.getLockOnFileName(configuredTexture) }
  end

  if markerUpdateData.doUpdate ~= true then return end

  UIUpdate(element)
end

function LockOnManager.getLockOnMarker() return LockOnManager.state.lockOnMarker end

---@return openmw.LObject lockTarget
function LockOnManager.getTargetObject() return LockOnManager.state.targetObject end

--- Returns false if the target doesn't exist, or isn't an NPC/Creature
---@return boolean isActor
function LockOnManager.targetIsActor()
  local target = LockOnManager.getTargetObject()
  if not target then return false end

  return IsActor(target)
end

---@return boolean isMarkerVisible
function LockOnManager.getMarkerVisibility()
  local marker = LockOnManager.getLockOnMarker()
  if marker == nil then return false end

  local visibility = true

  if marker.layout.props.visible ~= nil then visibility = marker.layout.props.visible end

  return visibility
end

---@param goLeft boolean? whether to check the right or left side of screen space. Nil indicates both sides should be checked.
function LockOnManager:selectNearestTarget(goLeft)
  local result = aux_util.findMinScore(ActiveCombatTargets, function(actor)
    if
      actor.recordId == 'player'
      or actor == self.state.targetObject
      or IsDead(actor)
      or GetStance(actor) == actor.type.STANCE.Nothing
    then
      return false
    end

    local screenPos = I.S3CamHelper.objectIsOnscreen(actor)

    if
      not screenPos
      or screenPos.z > self.TargetMaxDistance
      or (goLeft == true and screenPos.x > 0.5)
      or (goLeft == false and screenPos.x < 0.5)
    then
      return false
    end

    local LOSCheckPos = Vector3(
      actor.position.x,
      actor.position.y,
      actor.position.z + GetBoundingBox(actor).halfSize.z * 2
    )

    local checkLOSRay = CastRay(GetCamPosition(), LOSCheckPos, RayOpts)

    -- What if there's no hit...?
    if checkLOSRay.hit then
      if not checkLOSRay.hitObject or checkLOSRay.hitObject ~= actor then return false end
    end

    ---@diagnostic disable-next-line: undefined-field
    return Vec2Len(screenPos.xy - CenterVector2)
  end)

  if not result then return end

  s3lf.sendObjectEvent('S3TargetLockOnto', result)

  return result
end

--- Depending on whether it already exists or not, creates the lock on marker
--- or simply toggles its visibility
function LockOnManager.toggleLockOnMarkerDisplay()
  local marker = LockOnManager.getLockOnMarker()

  if not marker then
    LockOnManager.state.currentTexture =
      LockOnManager.getLockOnFileName(LockOnManager.TargetLockIcon)

    LockOnManager.state.lockOnMarker = ui.create {
      layer = 'HUD',
      type = ui.TYPE.Image,
      props = {
        anchor = CenterVector2,
        relativePosition = ZeroVector2,
        size = ZeroVector2,
        resource = ui.texture { path = LockOnManager.state.currentTexture },
        visible = false,
      },
    }

    UIUpdate = LockOnManager.state.lockOnMarker.update
  else
    LockOnManager.setMarkerVisibility(false)
  end
end

local function disable3PCamera()
  I.Camera.enableModeControl(ModInfo.name)

  local prevMode = LockOnManager.state.prevCameraMode
  local prevOffset = LockOnManager.state.prevFocalOffset

  SetCamMode(prevMode or camera.MODE.ThirdPerson, true)
  CamInstantTransition()

  if prevOffset then SetFocalOffset(prevOffset) end

  LockOnManager.state.isThirdPersonLock = false
  LockOnManager.state.prevCameraMode = nil
  LockOnManager.state.prevFocalOffset = nil
end

---@param target openmw.LObject
local function enable3PCamera(target)
  assert(IsActor(target), 'LockOnManager.setTarget only accepts actor types!!')

  local mode = GetCamMode()
  if mode ~= camera.MODE.FirstPerson then
    if not LockOnManager.state.isThirdPersonLock then
      LockOnManager.state.prevCameraMode = mode
      LockOnManager.state.prevFocalOffset = GetFocalOffset()
      I.Camera.disableModeControl(ModInfo.name)
    end
    SetCamMode(camera.MODE.Static, true)
    LockOnManager.state.isThirdPersonLock = true
  end
end

---@param target openmw.LObject?
function LockOnManager.setTarget(target)
  if target then
    enable3PCamera(target)
  elseif LockOnManager.state.isThirdPersonLock then
    disable3PCamera()
  end

  LockOnManager.state.targetObject = target
  LockOnManager.state.targetHealth = target and Health(target) or nil
  LockOnManager.state.npcHeightOffset = target
      and IsActor(target)
      and GetBoundingBox(target).halfSize.z * NPC_HEIGHT_OFFSET
    or nil
end

--- Responds to the 'SW4_TargetLock' action, engaging or disengaging target locking as appropriate
--- Toggle type action, but, maybe we could make it a hold??
function LockOnManager.lockOnHandler()
  if LockOnManager.getMarkerVisibility() then
    s3lf.sendObjectEvent 'S3TargetLockOnto'
    return LockOnManager.toggleLockOnMarkerDisplay()
  end

  LockOnManager:selectNearestTarget()
end

--- sets marker visibility. Always triggers a redraw
---@param state boolean whether or not the marker should be visible
---@return boolean? changed whether or not the state actually updated (due to the marker not existing)
function LockOnManager.setMarkerVisibility(state)
  local marker = LockOnManager.getLockOnMarker()
  if not marker then return end

  if state then LockOnManager.state.trackTarget = true end

  local markerState = LockOnManager.state
  markerState.isBouncing = false
  markerState.bouncedSize = 0
  markerState.bounceUpOrDown = true

  marker.layout.props.visible = state
  UIUpdate(marker)
  return true
end

---@param targetIsActor boolean whether or not the target is an actor
---@return boolean? updated whether or not the marker was hidden due to the target being dead
function LockOnManager.checkForDeadTarget(targetIsActor)
  local targetObject = LockOnManager.getTargetObject()

  if not targetObject or not targetIsActor then return end
  if not IsDead(targetObject) then return end

  if LockOnManager.setMarkerVisibility(false) then
    s3lf.sendObjectEvent 'S3TargetLockOnto'
    return true
  end
end

--- Given both the old and new ranges, map a numeric value from one to the other and round it.
---@param inputValue number
---@param oldRange openmw.util.Vector2
---@param newRange openmw.util.Vector2
local function remapFromRange(inputValue, oldRange, newRange)
  return Round(
    Max(
      Min(Remap(inputValue, oldRange.x, oldRange.y, newRange.x, newRange.y), newRange.y),
      newRange.x
    )
  )
end

---@param distanceFromCamera number distance in todd units from targeted object to the camera
---@return number iconSize rounded icon size, remapped from the camera distance range to the size range
function LockOnManager:getIconSize(distanceFromCamera)
  local markerSizeRange = Vector2(self.TargetMinSize, self.TargetMaxSize)
  local markerDistanceRange = Vector2(self.TargetMinDistance, self.TargetMaxDistance)
  return remapFromRange(distanceFromCamera, markerDistanceRange, markerSizeRange)
end

function LockOnManager:getIconColor()
  --- Figure out which of the existing log functions is most appropriate to use when this happens, as it shouldn't
  if self.state.targetHealth == nil then return self.TargetColorD end

  local normalizedHealth = self.state.targetHealth.current / self.state.targetHealth.base

  if normalizedHealth >= 1.0 then
    return self.TargetColorF
  elseif normalizedHealth < 0.0 then
    return self.TargetColorD
  end

  local targetColorMin, targetColorMax, bandLow, bandHigh

  if normalizedHealth < 1.0 and normalizedHealth >= 0.8 then
    targetColorMin = self.TargetColorVH:asRgb()
    targetColorMax = self.TargetColorF:asRgb()
    bandLow, bandHigh = 0.8, 1.0
  elseif normalizedHealth < 0.8 and normalizedHealth >= 0.6 then
    targetColorMin = self.TargetColorH:asRgb()
    targetColorMax = self.TargetColorVH:asRgb()
    bandLow, bandHigh = 0.6, 0.8
  elseif normalizedHealth < 0.6 and normalizedHealth >= 0.4 then
    targetColorMin = self.TargetColorW:asRgb()
    targetColorMax = self.TargetColorH:asRgb()
    bandLow, bandHigh = 0.4, 0.6
  elseif normalizedHealth < 0.4 and normalizedHealth >= 0.2 then
    targetColorMin = self.TargetColorVW:asRgb()
    targetColorMax = self.TargetColorW:asRgb()
    bandLow, bandHigh = 0.2, 0.4
  elseif normalizedHealth < 0.2 and normalizedHealth >= 0.0 then
    targetColorMin = self.TargetColorD:asRgb()
    targetColorMax = self.TargetColorVW:asRgb()
    bandLow, bandHigh = 0.0, 0.2
  end

  local colorMix = {}
  colorMix[#colorMix + 1] =
    Remap(normalizedHealth, bandLow, bandHigh, targetColorMin.x, targetColorMax.x)
  colorMix[#colorMix + 1] =
    Remap(normalizedHealth, bandLow, bandHigh, targetColorMin.y, targetColorMax.y)
  colorMix[#colorMix + 1] =
    Remap(normalizedHealth, bandLow, bandHigh, targetColorMin.z, targetColorMax.z)

  return RGBColor(colorMix[1], colorMix[2], colorMix[3])
end

function LockOnManager:onFrameBegin()
  if GetUIMode() or not LockOnManager.getMarkerVisibility() then return end

  local mouseMoveThisFrame = Vector2(input.getMouseMoveX(), input.getMouseMoveY())

  self.state.cumulativeXMove = self.state.cumulativeXMove + mouseMoveThisFrame.x

  if
    self.EnableFlickSwitch
    and self.getMarkerVisibility()
    and Abs(self.state.cumulativeXMove) >= self.FlickSwitchDistance
    and not self.state.flickTriggered
  then
    self:selectNearestTarget(self.state.cumulativeXMove < 0)
    self.state.flickTriggered = true
  end

  if Vec2Len(mouseMoveThisFrame) == 0 then
    self.state.cumulativeXMove = 0
    self.state.flickTriggered = false
  end
end

function LockOnManager:onFrame()
  local targetIsActor = LockOnManager.targetIsActor()
  local targetWasDead = LockOnManager.checkForDeadTarget(targetIsActor)

  if targetWasDead and self.SwitchOnDeadTarget then self:selectNearestTarget() end

  local targetObject = LockOnManager.getTargetObject()

  if self.CheckLOS and targetObject then
    local stablePos = I.S3CamHelper.targetPosition(
      targetObject,
      targetObject.position,
      LockOnManager.state.npcHeightOffset
    )

    if not I.S3CamHelper.objectIsOnscreen(targetObject, LockOnManager.state.npcHeightOffset) then
      s3lf.sendObjectEvent 'S3TargetLockOnto'
    else
      local LOStest = CastRay(GetCamPosition(), stablePos, RayOpts)

      if not LOStest.hit or not LOStest.hitObject or LOStest.hitObject ~= targetObject then
        s3lf.sendObjectEvent 'S3TargetLockOnto'
      end
    end
  end

  local uiMode = GetUIMode()
  local validMode = not uiMode or uiMode == 'MainMenu'

  LockOnManager.setCanLockOn(targetObject ~= nil and (targetIsActor and isWielding()) and validMode)

  local markerExists = LockOnManager.getLockOnMarker() ~= nil
  local markerIsVisible = LockOnManager.getMarkerVisibility()

  if LockOnManager.canLockOn() then
    assert(targetObject)
    if not markerExists then
      LockOnManager.toggleLockOnMarkerDisplay()
    elseif not markerIsVisible then
      LockOnManager.setMarkerVisibility(true)
    end

    local normalizedPos =
      I.S3CamHelper.objectIsOnscreen(targetObject, LockOnManager.state.npcHeightOffset)

    if normalizedPos and normalizedPos.z <= self.TargetMaxDistance then
      if s3lf.canMove() then
        if GetCamMode() ~= camera.MODE.FirstPerson then
          if not LockOnManager.state.isThirdPersonLock then
            enable3PCamera(LockOnManager.state.targetObject)
          end

          LockOnManager.trackTargetThirdPerson(targetObject)
        else
          LockOnManager.trackTarget(targetObject, LockOnManager.shouldTrack())
        end
      end

      LockOnManager:updateMarker {
        transform = normalizedPos,
        doUpdate = true,
      }
      camera.showCrosshair(false)
    else
      LockOnManager.setMarkerVisibility(false)
      camera.showCrosshair(true)
    end
  else
    if markerIsVisible then
      LockOnManager.setMarkerVisibility(false)
      camera.showCrosshair(true)
    end

    if LockOnManager.state.isThirdPersonLock then disable3PCamera() end
  end

  return LockOnManager.canLockOn()
end

--- Checks whether the lock-on icon is currently "bouncing" from a hit
---@return boolean isBouncing whether or not a target has already been hit and started a "bounce"
function LockOnManager.isBouncing() return LockOnManager.state.isBouncing end

function LockOnManager:startBounce()
  if self.state.isBouncing or not self.getMarkerVisibility() then return end

  self.state.isBouncing = true
end

function LockOnManager:bounce()
  if not self.isBouncing() or not self.getMarkerVisibility() then return end

  local state = LockOnManager.state

  if state.bounceUpOrDown then
    state.bouncedSize = state.bouncedSize + 1
  else
    state.bouncedSize = state.bouncedSize - 1
  end

  if state.bouncedSize == LockOnManager.HitBounceSize then
    state.bounceUpOrDown = false
  elseif state.bouncedSize == 0 then
    state.isBouncing = false
    state.bounceUpOrDown = true
  end
end

--- Handle late-stage actions such as un-targeting when the weapon is sheathed,
--- bouncing, and other stuff that depends on earlier frame interactions
function LockOnManager:onFrameEnd()
  self:bounce()

  if self.DisableLockWhenSheathing and not isWielding() and self.getTargetObject() then
    s3lf.sendObjectEvent 'S3TargetLockOnto'
  end
end

---@class TargetChangeData
---@field targets openmw.LObject[]
---@field actor openmw.LObject

---@param targetChangeData TargetChangeData
function LockOnManager.lockOnCombatStart(targetChangeData)
  local targetIsFighting = not not targetChangeData.targets[1]

  if targetIsFighting then
    ActiveCombatTargets[#ActiveCombatTargets + 1] = targetChangeData.actor
  else
    local targetId = targetChangeData.actor.id
    for i = #ActiveCombatTargets, 1, -1 do
      local toRemove = ActiveCombatTargets[i]

      if toRemove.id == targetId then
        TableRemove(ActiveCombatTargets, i)
        break
      end
    end
  end

  if
    not LockOnManager.LockOnCombatStart
    or LockOnManager.getMarkerVisibility()
    or not targetIsFighting
  then
    return
  end

  local targetIsMe = false
  for i = 1, #targetChangeData.targets do
    local target = targetChangeData.targets[i]

    if target.id == s3lf.id then
      targetIsMe = true
      break
    end
  end

  local hasWeapon = s3lf.getEquipment(SLOT_WEAPON) ~= nil
  local hasSpell = s3lf.getSelectedEnchantedItem() ~= nil or s3lf.getSelectedSpell() ~= nil

  if not targetIsMe or (not hasWeapon and not hasSpell) then return end

  if not isWielding() then
    local stance = hasWeapon and STANCE_WEAPON or STANCE_SPELL

    s3lf.setStance(stance)
  end

  s3lf.sendObjectEvent('S3TargetLockOnto', targetChangeData.actor)

  if GetCamMode() == camera.MODE.FirstPerson then
    local myYaw, theirYaw = GetYaw(s3lf.rotation), GetYaw(targetChangeData.actor.rotation)

    theirYaw = theirYaw - Rad(180)
    local difference = theirYaw - myYaw

    s3lf.controls.yawChange = Atan2(Sin(difference), Cos(difference))
  end
end

function LockOnManager.bounceOnHit(target)
  if
    --- Maybe we also want to bail if the marker isn't visible... ?
    not LockOnManager.EnableHitBounce or LockOnManager.isBouncing()
  then
    return
  end

  local targetObject = LockOnManager.getTargetObject()

  --- Don't screw around and switch targets when we hit someone else on accident, but have a locked-on target already.
  if targetObject and targetObject ~= target then return end

  LockOnManager:startBounce()
end

input.registerTriggerHandler('S3TargetLock', async:callback(LockOnManager.lockOnHandler))

return {
  engineHandlers = {
    onFrame = function()
      LockOnManager:onFrameBegin()
      LockOnManager:onFrame()
      LockOnManager:onFrameEnd()
    end,
  },
  eventHandlers = {
    OMWMusicCombatTargetsChanged = LockOnManager.lockOnCombatStart,
    S3TargetLockOnto = LockOnManager.setTarget,
    S3TargetLockHit = LockOnManager.bounceOnHit,
  },
  interfaceName = 'S3LockOn',
  interface = {
    version = 1,
    Manager = LockOnManager,
  },
}
