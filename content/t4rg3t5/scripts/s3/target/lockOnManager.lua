---@omw-context player

local async = require 'openmw.async'
local aux_util = require 'openmw_aux.util'
local camera = require 'openmw.camera'
local core = require 'openmw.core'
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
local GetCamPitch, GetCamPosition, GetCamYaw, SetCamPitch, SetCamYaw, ShowCrosshair, GetTrackedPosition =
  camera.getPitch,
  camera.getPosition,
  camera.getYaw,
  camera.setPitch,
  camera.setYaw,
  camera.showCrosshair,
  camera.getTrackedPosition
local GetFrameDuration = core.getRealFrameDuration
local SetCamStaticPosition, GetCamMode, SetCamMode, CamInstantTransition =
  camera.setStaticPosition, camera.getMode, camera.setMode, camera.instantTransition
local GetFocalOffset, SetFocalOffset =
  camera.getFocalPreferredOffset, camera.setFocalPreferredOffset
local GetFieldOfView, SetFieldOfView = camera.getFieldOfView, camera.setFieldOfView

local GetMouseMoveX, GetMouseMoveY = input.getMouseMoveX, input.getMouseMoveY

local GetPitch, GetStance, GetYaw, Health, IsActor, IsDead =
  s3lf.rotation.getPitch,
  types.Actor.getStance,
  s3lf.rotation.getYaw,
  types.Actor.stats.dynamic.health,
  types.Actor.objectIsInstance,
  types.Actor.isDead
local IsNPC = types.NPC.objectIsInstance

local RGBColor = util.color.rgb

local CAM_FP = camera.MODE.FirstPerson
local SLOT_WEAPON = s3lf.EQUIPMENT_SLOT.CarriedRight
local STANCE_NONE, STANCE_SPELL, STANCE_WEAPON =
  s3lf.STANCE.Nothing, s3lf.STANCE.Spell, s3lf.STANCE.Weapon

local ModInfo = require 'scripts.s3.target.modinfo'

local Abs, Atan2, Cos, Exp, Log, Max, Min, Rad, Sin, Sqrt =
  math.abs,
  math.atan2,
  math.cos,
  math.exp,
  math.log,
  math.max,
  math.min,
  math.rad,
  math.sin,
  math.sqrt

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
local UpVec3 = Vector3(0, 0, 1)
local ZeroVector3 = Vector3(0, 0, 0)
local Vec3Cross = UpVec3.cross
local Vec3Len = UpVec3.length

---@type fun(element: openmw.ui.Element)
local UIUpdate

-- Preserve the old 60 FPS response (0.6/0.4 gain, 12°/10° caps) in time-based form.
local CameraYawResponse, CameraPitchResponse = -Log(0.4) * 60, -Log(0.6) * 60
local MaxYawRate, MaxPitchRate = Rad(12.0 * 60), Rad(10.0 * 60)
local HIT_BOUNCE_DURATION = 0.15

local NPC_HEIGHT_OFFSET = 1.6

local CAM_COLLISION_RATIO = 0.85
local CAM_COLLISION_SKIN = 1

local EPS = 0.001
local DEFAULT_LOCK_LOSS_DELAY = 0.25
local MAX_LOCK_LOSS_DELAY = 1

local RayOpts = { ignore = { gameSelf } }

local ActiveCombatTargets = {}

local function isWielding() return s3lf.getStance() ~= STANCE_NONE end

--- Refer to globalSettings.lua for field default values
---
---@class LockOnManager:ProtectedTable
---@field TargetLockToggle boolean whether or not targeting is enabled
---@field SwitchOnDeadTarget boolean whether or not to automatically select the nearest (screen-space) target when the current one dies
---@field CheckLOS boolean whether to use line-of-sight when deciding whether to break a target lock
---@field ThirdPersonLockCamera boolean whether to use the custom third-person lock camera
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
---@field CameraDistance integer Base orbit distance from the player center
---@field CameraHeight integer Vertical offset of the camera orbit
---@field CameraSideOffset integer Horizontal shoulder offset strength
---@field CameraPreferredShoulder string Shoulder to prefer when a lock camera session begins
---@field CameraFOV integer Vertical field of view in degrees while the lock camera is active, or 0 to inherit
---@field CameraMinDistance integer Minimum orbit distance when collision-pinned
---@field CameraResponsiveness integer Critically-damped position spring frequency in rad/s
---@field CameraLookResponsiveness integer Critically-damped look-target spring frequency in rad/s
---@field CameraLookBias integer Look-target bias toward target vs player center, 0-100 percent
---@field TargetFramingHeight integer Percentage of target height used by the lock camera's look target
---@field LockLossDelay number Seconds a temporarily invalid target remains locked
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
  targetHalfHeight = nil,
  markerVisible = false,
  lockInvalidTime = 0,
  lockOnMarker = nil,
  currentTexture = nil,
  canDoLockOn = false,
  flickTriggered = false,
  cumulativeXMove = 0,
  isBouncing = false,
  bouncedSize = 0,
  bounceElapsed = 0,
  trackTarget = true,
  isThirdPersonLock = false,
  prevCameraMode = nil,
  prevFocalOffset = nil,
  prevFieldOfView = nil,
  appliedFieldOfView = nil,
  cameraPosition = nil,
  cameraVelocity = nil,
  lookTarget = nil,
  lookTargetVelocity = nil,
  frameDt = 0,
  goLeft = false,
  cameraSide = 1,
}

local function getPreferredCameraSide()
  return LockOnManager.CameraPreferredShoulder == 'Left' and -1 or 1
end

local function getTrackingTargetPosition(targetObject)
  return I.S3CamHelper.targetPosition(
    targetObject,
    targetObject.position,
    LockOnManager.state.npcHeightOffset
  )
end

local function getCameraFramingPosition(targetObject)
  local state = LockOnManager.state
  local framing = Clamp(LockOnManager.TargetFramingHeight or 80, 0, 100) / 100

  if IsNPC(targetObject) then
    local position = targetObject.position
    local halfHeight = state.targetHalfHeight
    if not halfHeight then halfHeight = GetBoundingBox(targetObject).halfSize.z end
    return Vector3(position.x, position.y, position.z + halfHeight * 2 * framing)
  end

  local boundingBox = GetBoundingBox(targetObject)
  local halfHeight = state.targetHalfHeight or boundingBox.halfSize.z
  local center = boundingBox.center
  return Vector3(center.x, center.y, center.z + (framing - 0.5) * halfHeight * 2)
end

local function getLookDirection(origin, target)
  local offset = target - origin
  if Vec3Len(offset) <= EPS then
    local yaw = GetCamYaw()
    return Vector3(Sin(yaw), Cos(yaw), 0)
  end

  return Vec3Normalize(offset)
end

local function getCameraRight(lookDirection)
  local right = Vec3Cross(lookDirection, UpVec3)
  if Vec3Len(right) <= EPS then
    local yaw = GetCamYaw()
    return Vector3(Cos(yaw), -Sin(yaw), 0)
  end

  return Vec3Normalize(right)
end

local function releaseLockCameraFOV()
  local state = LockOnManager.state
  local ownsFieldOfView = state.prevFieldOfView
    and state.appliedFieldOfView
    and Abs(GetFieldOfView() - state.appliedFieldOfView) <= EPS

  if ownsFieldOfView then SetFieldOfView(state.prevFieldOfView) end
  state.prevFieldOfView = nil
  state.appliedFieldOfView = nil
end

local function updateLockCameraFOV()
  local state = LockOnManager.state
  local configuredFOV = Clamp(LockOnManager.CameraFOV or 0, 0, 120)

  if configuredFOV == 0 then
    if state.prevFieldOfView then releaseLockCameraFOV() end
    return
  end

  if not state.prevFieldOfView then state.prevFieldOfView = GetFieldOfView() end

  local targetFOV = Rad(configuredFOV)
  state.appliedFieldOfView = targetFOV
  if Abs(GetFieldOfView() - targetFOV) > EPS then SetFieldOfView(targetFOV) end
end

-- T4RG3T5 owns vanilla crosshair presentation while enabled; it does not restore prior state.
local function updateCrosshairPresentation()
  local state = LockOnManager.state
  ShowCrosshair(not state.targetObject)
end

---@alias MarkerTransform openmw.util.Vector3 info about the marker; z element is distance from camera, xy are normalized screenpos of target

---@class MarkerUpdateInfo
---@field doUpdate boolean? whether to redraw or not
---@field transform MarkerTransform Onscreen position to place the marker at

function LockOnManager.getLockOnFileName(baseName)
  return StrFormat('textures/s3/crosshair/%s.dds', baseName)
end

function LockOnManager:clearTarget()
  local state = self.state

  state.targetObject = nil
  state.targetHealth = nil
  state.npcHeightOffset = nil
  state.targetHalfHeight = nil
  state.lockInvalidTime = 0
  state.canDoLockOn = false
  state.flickTriggered = false
  state.cumulativeXMove = 0
  updateCrosshairPresentation()

  self.setMarkerVisibility(false)
  self:endLockCamera()
end

local function notifyTargetChanged(target) s3lf.sendObjectEvent('S3TargetLockOnto', target) end

local function changeAndNotifyTarget(target)
  if not LockOnManager.setTarget(target) then return false end

  notifyTargetChanged(target)
  return true
end

function LockOnManager:ensureTargetingEnabled()
  if self.TargetLockToggle then return true end

  changeAndNotifyTarget()
  return false
end

---@param state boolean
function LockOnManager.setTrackingState(state) LockOnManager.state.trackTarget = state end

---@return boolean shouldTrack
function LockOnManager.shouldTrack() return LockOnManager.state.trackTarget end

---@param desiredYaw number
---@param desiredPitch number
---@param currentYaw number
---@param currentPitch number
---@param dt number? elapsed real time in seconds
function LockOnManager.getAngleDiff(desiredYaw, desiredPitch, currentYaw, currentPitch, dt)
  dt = dt or 1 / 60
  if dt <= 0 then return 0, 0 end

  local yawDiff = NormalizeAngle(desiredYaw - currentYaw)
  local pitchDiff = NormalizeAngle(desiredPitch - currentPitch)
  local yawAlpha = 1 - Exp(-CameraYawResponse * dt)
  local pitchAlpha = 1 - Exp(-CameraPitchResponse * dt)

  local finalYaw = Clamp(yawDiff * yawAlpha, -MaxYawRate * dt, MaxYawRate * dt)
  local finalPitch = Clamp(pitchDiff * pitchAlpha, -MaxPitchRate * dt, MaxPitchRate * dt)

  return finalYaw, finalPitch
end

---@param targetObject openmw.LObject
---@param shouldTrack boolean
function LockOnManager.trackTarget(targetObject, shouldTrack)
  if not targetObject then return end

  local frameDt = LockOnManager.state.frameDt
  local playerPos = GetCamPosition()
  local targetPos = getTrackingTargetPosition(targetObject)
  local toTarget = targetPos - playerPos

  local currentYaw, currentPitch = GetCamYaw(), GetCamPitch()

  local desiredYaw = Atan2(toTarget.x, toTarget.y)
  local desiredPitch = Atan2(-toTarget.z, Sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y))

  local camYaw, camPitch =
    LockOnManager.getAngleDiff(desiredYaw, desiredPitch, currentYaw, currentPitch, frameDt)

  if Abs(camYaw) >= EPS then SetCamYaw(currentYaw + camYaw) end

  if Abs(camPitch) >= EPS then SetCamPitch(currentPitch + camPitch) end

  if not shouldTrack then return end

  local rotation = s3lf.rotation
  local playerYaw, playerPitch = LockOnManager.getAngleDiff(
    desiredYaw,
    desiredPitch,
    GetYaw(rotation),
    GetPitch(rotation),
    frameDt
  )

  if Abs(playerYaw) >= EPS then s3lf.controls.yawChange = playerYaw end

  if Abs(playerPitch) >= EPS then s3lf.controls.pitchChange = playerPitch end
end

local function resolveCameraCandidate(
  orbitCenter,
  lookDir,
  shoulderOffset,
  cameraDistance,
  cameraHeight,
  cameraMinDistance,
  side
)
  local candidateVector = lookDir * -cameraDistance + UpVec3 * cameraHeight + shoulderOffset * side
  local candidate = orbitCenter + candidateVector
  local ray = CastRay(orbitCenter, candidate, RayOpts)

  if not ray.hit then return candidate, cameraDistance end

  local candidateDistance = Vec3Len(candidateVector)
  local hitDistance = Vec3Len(ray.hitPos - orbitCenter)
  local safeDistance =
    Max(hitDistance * CAM_COLLISION_RATIO - CAM_COLLISION_SKIN, cameraMinDistance)
  safeDistance = Min(safeDistance, Max(hitDistance - CAM_COLLISION_SKIN, 0))
  local scale = safeDistance / candidateDistance
  return orbitCenter + candidateVector * scale, cameraDistance * scale
end

local function getTargetObstructionDistanceSquared(targetPos, cameraPosition, targetObject)
  if not targetObject then return end

  local ray = CastRay(cameraPosition, targetPos, RayOpts)
  if not ray.hit or ray.hitObject == targetObject then return end

  local offset = ray.hitPos - targetPos
  return offset.x * offset.x + offset.y * offset.y + offset.z * offset.z
end

--- Compute the collision-corrected camera position and shoulder side for the lock-on camera orbit.
---@param orbitCenter openmw.util.Vector3
---@param targetPos openmw.util.Vector3
---@param targetObject openmw.LObject?
---@return number effectiveDist effective camera distance
---@return number desiredSide
---@return openmw.util.Vector3 desiredPosition collision-corrected camera position
function LockOnManager.computeOrbitParams(orbitCenter, targetPos, targetObject)
  local cameraDistance = LockOnManager.CameraDistance
  local cameraHeight = LockOnManager.CameraHeight
  local cameraMinDistance = LockOnManager.CameraMinDistance
  local cameraSideOffset = LockOnManager.CameraSideOffset
  local state = LockOnManager.state

  local targetBad = cameraDistance * 0.5
  local targetGood = cameraDistance * 0.8
  local targetBadSquared = targetBad * targetBad
  local targetGoodSquared = targetGood * targetGood

  local lookDir = getLookDirection(orbitCenter, targetPos)
  local right = getCameraRight(lookDir)
  local shoulderOffset = right * cameraSideOffset

  local desiredSide = state.cameraSide or 1
  local currentPosition, currentDistance = resolveCameraCandidate(
    orbitCenter,
    lookDir,
    shoulderOffset,
    cameraDistance,
    cameraHeight,
    cameraMinDistance,
    desiredSide
  )

  local currentIsBad = currentDistance < targetBad
  if not currentIsBad then
    local obstructionDistanceSquared =
      getTargetObstructionDistanceSquared(targetPos, currentPosition, targetObject)
    currentIsBad = obstructionDistanceSquared ~= nil
      and obstructionDistanceSquared < targetBadSquared
  end

  if currentIsBad then
    local alternateSide = -desiredSide
    local alternatePosition, alternateDistance = resolveCameraCandidate(
      orbitCenter,
      lookDir,
      shoulderOffset,
      cameraDistance,
      cameraHeight,
      cameraMinDistance,
      alternateSide
    )

    if alternateDistance > targetGood then
      local obstructionDistanceSquared =
        getTargetObstructionDistanceSquared(targetPos, alternatePosition, targetObject)

      if not obstructionDistanceSquared or obstructionDistanceSquared > targetGoodSquared then
        state.cameraSide = alternateSide
        return alternateDistance, alternateSide, alternatePosition
      end
    end
  end

  state.cameraSide = desiredSide
  return currentDistance, desiredSide, currentPosition
end

--- Step an analytical critically-damped spring toward a target position.
---@param pos openmw.util.Vector3
---@param vel openmw.util.Vector3
---@param target openmw.util.Vector3
---@param dt number
---@param omega number Spring natural frequency in rad/s
---@return openmw.util.Vector3 newPos
---@return openmw.util.Vector3 newVel
function LockOnManager.criticallyDampedSpring(pos, vel, target, dt, omega)
  if dt <= 0 then return pos, vel end

  local offset = pos - target
  local j = vel + offset * omega
  local decay = Exp(-omega * dt)

  local newPosition = target + (offset + j * dt) * decay
  local newVelocity = (vel - j * omega * dt) * decay

  return newPosition, newVelocity
end

--- Spring the look-target toward a point between the orbit center and the target,
--- biased toward the target by CAM_LOOK_BIAS. The look-target springs independently
--- from the camera position, which gives the camera a subtle trailing feel.
---@param lookTarget openmw.util.Vector3?
---@param lookVel openmw.util.Vector3?
---@param orbitCenter openmw.util.Vector3
---@param targetPos openmw.util.Vector3
---@param dt number
---@return openmw.util.Vector3 newLookTarget
---@return openmw.util.Vector3 newLookVel
function LockOnManager.springLookTarget(lookTarget, lookVel, orbitCenter, targetPos, dt)
  local cameraLookBias = LockOnManager.CameraLookBias / 100
  local cameraLookResponsiveness = LockOnManager.CameraLookResponsiveness
  local desiredLookTarget = orbitCenter + (targetPos - orbitCenter) * cameraLookBias

  if not lookTarget then
    lookTarget = targetPos
    lookVel = ZeroVector3
  end

  return LockOnManager.criticallyDampedSpring(
    lookTarget,
    lookVel or ZeroVector3,
    desiredLookTarget,
    dt,
    cameraLookResponsiveness
  )
end

--- Orient the camera's yaw and pitch to look at a world-space target position.
---@param cameraPos openmw.util.Vector3
---@param lookTarget openmw.util.Vector3
function LockOnManager.lookToward(cameraPos, lookTarget)
  local viewDir = lookTarget - cameraPos
  SetCamYaw(Atan2(viewDir.x, viewDir.y))
  SetCamPitch(Atan2(-viewDir.z, Sqrt(viewDir.x * viewDir.x + viewDir.y * viewDir.y)))
end

--- Rotate the player character's yaw and pitch toward the lock-on target.
---@param targetPos openmw.util.Vector3
---@param orbitCenter openmw.util.Vector3
function LockOnManager.rotatePlayerTowardTarget(targetPos, orbitCenter)
  local toTarget = targetPos - orbitCenter
  local yaw = Atan2(toTarget.x, toTarget.y)
  local pitch = Atan2(-toTarget.z, Sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y))
  local rot = s3lf.rotation
  local yawChange, pitchChange =
    LockOnManager.getAngleDiff(yaw, pitch, GetYaw(rot), GetPitch(rot), LockOnManager.state.frameDt)
  if Abs(yawChange) >= EPS then s3lf.controls.yawChange = yawChange end
  if Abs(pitchChange) >= EPS then s3lf.controls.pitchChange = pitchChange end
end

--- Replacement over-the-shoulder camera implementation for 3P.
---@param targetObject openmw.LObject
function LockOnManager.trackTargetThirdPerson(targetObject)
  local trackingTargetPos = getTrackingTargetPosition(targetObject)
  local framingTargetPos = getCameraFramingPosition(targetObject)
  local orbitCenter = GetTrackedPosition()
  local state = LockOnManager.state

  local _, _, desiredPos =
    LockOnManager.computeOrbitParams(orbitCenter, trackingTargetPos, targetObject)

  if not state.cameraPosition then
    state.cameraPosition = GetCamPosition()
    state.cameraVelocity = ZeroVector3
    state.lookTarget = framingTargetPos
    state.lookTargetVelocity = ZeroVector3
  end

  state.cameraPosition, state.cameraVelocity = LockOnManager.criticallyDampedSpring(
    state.cameraPosition,
    state.cameraVelocity,
    desiredPos,
    state.frameDt,
    LockOnManager.CameraResponsiveness
  )
  SetCamStaticPosition(state.cameraPosition)

  state.lookTarget, state.lookTargetVelocity = LockOnManager.springLookTarget(
    state.lookTarget,
    state.lookTargetVelocity,
    orbitCenter,
    framingTargetPos,
    state.frameDt
  )

  LockOnManager.lookToward(state.cameraPosition, state.lookTarget)

  if LockOnManager.shouldTrack() then
    LockOnManager.rotatePlayerTowardTarget(trackingTargetPos, orbitCenter)
  end
end

---@param transform MarkerTransform
---@param drawUpdate boolean
function LockOnManager:updateMarker(transform, drawUpdate)
  local element = assert(
    self.getLockOnMarker(),
    'LockOnManager: Failed to locate lock on marker to set its position!'
  )

  local elementSize = self:getIconSize(transform.z) + self.state.bouncedSize
  element.layout.props.size = Vector2(elementSize, elementSize)
  element.layout.props.color = self:getIconColor()

  --- Vector swizzles are legit but documenting them sucks
  ---@diagnostic disable-next-line: undefined-field
  element.layout.props.relativePosition = transform.xy

  local configuredTexture = LockOnManager.TargetLockIcon
  if configuredTexture ~= LockOnManager.state.currentTexture then
    LockOnManager.state.currentTexture = configuredTexture

    element.layout.props.resource =
      ui.texture { path = LockOnManager.getLockOnFileName(configuredTexture) }
  end

  if not drawUpdate then return end

  UIUpdate(element)
end

function LockOnManager.getLockOnMarker() return LockOnManager.state.lockOnMarker end

---@return openmw.LObject lockTarget
function LockOnManager.getTargetObject() return LockOnManager.state.targetObject end

--- Returns false if the target doesn't exist, or isn't an NPC/Creature
---@return boolean isActor
function LockOnManager.targetIsActor()
  local target = LockOnManager.getTargetObject()
  if not target or not target:isValid() then return false end

  return IsActor(target)
end

---@return boolean isMarkerVisible
function LockOnManager.getMarkerVisibility() return LockOnManager.state.markerVisible end

---@param actor openmw.LObject
function LockOnManager.selectNearestTargetImpl(actor)
  if
    not actor:isValid()
    or actor.recordId == 'player'
    or actor == LockOnManager.state.targetObject
    or IsDead(actor)
    or GetStance(actor) == STANCE_NONE
  then
    return false
  end

  local screenPos = I.S3CamHelper.objectIsOnscreen(actor)

  local goLeft = LockOnManager.state.goLeft

  if
    not screenPos
    or screenPos.z > LockOnManager.TargetMaxDistance
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

  local dx = screenPos.x - 0.5
  local dy = screenPos.y - 0.5
  return dx * dx + dy * dy
end

---@param goLeft boolean? whether to check the right or left side of screen space. Nil indicates both sides should be checked.
function LockOnManager.selectNearestTarget(goLeft)
  if not LockOnManager.TargetLockToggle then return end

  LockOnManager.state.goLeft = goLeft

  local result = aux_util.findMinScore(ActiveCombatTargets, LockOnManager.selectNearestTargetImpl)

  if result then changeAndNotifyTarget(result) end

  return result
end

function LockOnManager.ensureLockOnMarker()
  local marker = LockOnManager.getLockOnMarker()

  if marker then return marker end

  LockOnManager.state.currentTexture = LockOnManager.getLockOnFileName(LockOnManager.TargetLockIcon)

  LockOnManager.state.lockOnMarker = ui.create {
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
      anchor = CenterVector2,
      relativePosition = ZeroVector2,
      size = ZeroVector2,
      resource = ui.texture { path = LockOnManager.state.currentTexture },
      visible = LockOnManager.state.markerVisible,
    },
  }

  UIUpdate = LockOnManager.state.lockOnMarker.update
  return LockOnManager.state.lockOnMarker
end

function LockOnManager:endLockCamera()
  local state = self.state
  if not state.isThirdPersonLock then return false end

  local prevMode = state.prevCameraMode
  local prevOffset = state.prevFocalOffset
  local stillInStaticMode = GetCamMode() == camera.MODE.Static

  I.Camera.enableModeControl(ModInfo.name)

  if stillInStaticMode and I.Camera.isModeControlEnabled() then
    SetCamMode(prevMode or camera.MODE.ThirdPerson, true)
    CamInstantTransition()

    if prevOffset then SetFocalOffset(prevOffset) end
  end

  releaseLockCameraFOV()

  state.isThirdPersonLock = false
  state.prevCameraMode = nil
  state.prevFocalOffset = nil
  state.cameraPosition = nil
  state.cameraVelocity = nil
  state.lookTarget = nil
  state.lookTargetVelocity = nil
  return true
end

---@param target openmw.LObject
function LockOnManager:beginLockCamera(target)
  if self.state.isThirdPersonLock or not self.ThirdPersonLockCamera then return false end

  local mode = GetCamMode()
  if mode == CAM_FP or mode == camera.MODE.Static or not I.Camera.isModeControlEnabled() then
    return false
  end

  assert(IsActor(target), 'LockOnManager.beginLockCamera only accepts actor types!!')

  self.state.prevCameraMode = mode
  self.state.prevFocalOffset = GetFocalOffset()
  self.state.prevFieldOfView = nil
  self.state.appliedFieldOfView = nil
  if Clamp(self.CameraFOV or 0, 0, 120) > 0 then self.state.prevFieldOfView = GetFieldOfView() end
  I.Camera.disableModeControl(ModInfo.name)
  self.state.cameraPosition = GetCamPosition()
  self.state.cameraVelocity = ZeroVector3
  self.state.lookTarget = getCameraFramingPosition(target)
  self.state.lookTargetVelocity = ZeroVector3

  SetCamMode(camera.MODE.Static, true)
  self.state.isThirdPersonLock = true
  updateLockCameraFOV()
  return true
end

---@param target openmw.LObject
---@return boolean active whether the custom lock camera is active and updated
function LockOnManager:updateLockCamera(target)
  if not self.ThirdPersonLockCamera then
    self:endLockCamera()
    return false
  end

  local mode = GetCamMode()
  if self.state.isThirdPersonLock and mode ~= camera.MODE.Static then
    self:endLockCamera()
    return false
  end

  if not self.state.isThirdPersonLock and not self:beginLockCamera(target) then return false end

  updateLockCameraFOV()
  self.trackTargetThirdPerson(target)
  return true
end

---@param target openmw.LObject?
---@return boolean changed
function LockOnManager.setTarget(target)
  local state = LockOnManager.state
  local previousTarget = state.targetObject

  if target == nil then
    if previousTarget == nil then return false end

    LockOnManager:clearTarget()
    return true
  end

  if not LockOnManager.TargetLockToggle then return false end
  if not target:isValid() or not IsActor(target) then return false end
  if target == previousTarget then return false end

  local boundingBox = GetBoundingBox(target)

  if not previousTarget then state.cameraSide = getPreferredCameraSide() end

  state.targetObject = target
  state.targetHealth = Health(target)
  state.npcHeightOffset = boundingBox.halfSize.z * NPC_HEIGHT_OFFSET
  state.targetHalfHeight = boundingBox.halfSize.z
  state.lockInvalidTime = 0
  updateCrosshairPresentation()

  LockOnManager.ensureLockOnMarker()
  return true
end

--- Responds to the 'SW4_TargetLock' action, engaging or disengaging target locking as appropriate
--- Toggle type action, but, maybe we could make it a hold??
function LockOnManager.lockOnHandler()
  if LockOnManager.getTargetObject() then
    changeAndNotifyTarget()
    return
  end

  LockOnManager.selectNearestTarget()
end

--- Sets marker visibility when it changes.
---@param state boolean whether or not the marker should be visible
---@return boolean changed whether or not the visibility state changed
function LockOnManager.setMarkerVisibility(state)
  local markerState = LockOnManager.state
  if state then markerState.trackTarget = true end
  if markerState.markerVisible == state then return false end

  markerState.markerVisible = state
  markerState.isBouncing = false
  markerState.bouncedSize = 0
  markerState.bounceElapsed = 0

  local marker = LockOnManager.getLockOnMarker()
  if not marker then return true end

  marker.layout.props.visible = state
  UIUpdate(marker)
  return true
end

---@param distanceFromCamera number distance in todd units from targeted object to the camera
---@return number iconSize rounded icon size, remapped from the camera distance range to the size range
function LockOnManager:getIconSize(distanceFromCamera)
  return Round(
    Clamp(
      Remap(
        distanceFromCamera,
        self.TargetMinDistance,
        self.TargetMaxDistance,
        self.TargetMinSize,
        self.TargetMaxSize
      ),
      self.TargetMinSize,
      self.TargetMaxSize
    )
  )
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

  if normalizedHealth >= 0.8 then
    targetColorMin = self.TargetColorVH:asRgb()
    targetColorMax = self.TargetColorF:asRgb()
    bandLow, bandHigh = 0.8, 1.0
  elseif normalizedHealth >= 0.6 then
    targetColorMin = self.TargetColorH:asRgb()
    targetColorMax = self.TargetColorVH:asRgb()
    bandLow, bandHigh = 0.6, 0.8
  elseif normalizedHealth >= 0.4 then
    targetColorMin = self.TargetColorW:asRgb()
    targetColorMax = self.TargetColorH:asRgb()
    bandLow, bandHigh = 0.4, 0.6
  elseif normalizedHealth >= 0.2 then
    targetColorMin = self.TargetColorVW:asRgb()
    targetColorMax = self.TargetColorW:asRgb()
    bandLow, bandHigh = 0.2, 0.4
  else
    targetColorMin = self.TargetColorD:asRgb()
    targetColorMax = self.TargetColorVW:asRgb()
    bandLow, bandHigh = 0.0, 0.2
  end

  return RGBColor(
    Remap(normalizedHealth, bandLow, bandHigh, targetColorMin.x, targetColorMax.x),
    Remap(normalizedHealth, bandLow, bandHigh, targetColorMin.y, targetColorMax.y),
    Remap(normalizedHealth, bandLow, bandHigh, targetColorMin.z, targetColorMax.z)
  )
end

function LockOnManager:onFrameBegin()
  local state = self.state
  state.frameDt = GetFrameDuration()

  if not self.EnableFlickSwitch then
    state.cumulativeXMove = 0
    state.flickTriggered = false
    return
  end

  if GetUIMode() or not state.targetObject or not state.markerVisible then return end

  local mouseX, mouseY = GetMouseMoveX(), GetMouseMoveY()
  state.cumulativeXMove = state.cumulativeXMove + mouseX

  if Abs(state.cumulativeXMove) >= self.FlickSwitchDistance and not state.flickTriggered then
    self.selectNearestTarget(state.cumulativeXMove < 0)
    state.flickTriggered = true
  end

  if mouseX == 0 and mouseY == 0 then
    state.cumulativeXMove = 0
    state.flickTriggered = false
  end
end

function LockOnManager:onFrame()
  local state = self.state
  local targetObject = state.targetObject
  if targetObject and not targetObject:isValid() then
    changeAndNotifyTarget()
    return false
  end

  if targetObject and IsDead(targetObject) then
    changeAndNotifyTarget()
    if self.SwitchOnDeadTarget then self.selectNearestTarget() end
    targetObject = state.targetObject
  end

  local uiMode = GetUIMode()
  local validMode = not uiMode or uiMode == 'MainMenu'
  local normalizedPos
  if targetObject and validMode then
    normalizedPos = I.S3CamHelper.objectIsOnscreen(targetObject, state.npcHeightOffset)

    local trackingValid = normalizedPos and normalizedPos.z <= self.TargetMaxDistance
    if trackingValid and self.CheckLOS then
      local stablePos =
        I.S3CamHelper.targetPosition(targetObject, targetObject.position, state.npcHeightOffset)
      local LOStest = CastRay(GetCamPosition(), stablePos, RayOpts)
      trackingValid = not LOStest.hit or LOStest.hitObject == targetObject
    end

    if trackingValid then
      state.lockInvalidTime = 0
    else
      state.lockInvalidTime = state.lockInvalidTime + Max(state.frameDt, 0)

      local lockLossDelay =
        Clamp(self.LockLossDelay or DEFAULT_LOCK_LOSS_DELAY, 0, MAX_LOCK_LOSS_DELAY)
      if state.lockInvalidTime >= lockLossDelay then
        changeAndNotifyTarget()
        targetObject = state.targetObject
        normalizedPos = nil
      end
    end
  end

  local canLockOn = targetObject ~= nil and isWielding() and validMode
  state.canDoLockOn = canLockOn

  local markerExists = self.getLockOnMarker() ~= nil
  local markerIsVisible = state.markerVisible

  if canLockOn then
    assert(targetObject)
    if not self.ThirdPersonLockCamera then self:endLockCamera() end
    if not markerExists then self.ensureLockOnMarker() end

    if not state.markerVisible then self.setMarkerVisibility(true) end

    if normalizedPos and normalizedPos.z <= self.TargetMaxDistance then
      if s3lf.canMove() then
        if self.ThirdPersonLockCamera then
          if
            not self:updateLockCamera(targetObject)
            and GetCamMode() ~= camera.MODE.Static
            and I.Camera.isModeControlEnabled()
          then
            self.trackTarget(targetObject, self.shouldTrack())
          end
        else
          if GetCamMode() ~= camera.MODE.Static and I.Camera.isModeControlEnabled() then
            self.trackTarget(targetObject, self.shouldTrack())
          end
        end
      end

      self:updateMarker(normalizedPos, true)
    else
      self.setMarkerVisibility(false)
    end
  else
    if markerIsVisible then self.setMarkerVisibility(false) end

    self:endLockCamera()
  end

  return canLockOn
end

--- Checks whether the lock-on icon is currently "bouncing" from a hit
---@return boolean isBouncing whether or not a target has already been hit and started a "bounce"
function LockOnManager.isBouncing() return LockOnManager.state.isBouncing end

function LockOnManager:startBounce()
  local state = self.state
  if state.isBouncing or not state.markerVisible then return end

  state.isBouncing = true
  state.bounceElapsed = 0
end

function LockOnManager:bounce()
  local state = LockOnManager.state
  if not state.isBouncing or not state.markerVisible then return end

  state.bounceElapsed = state.bounceElapsed + Max(state.frameDt, 0)

  local progress = state.bounceElapsed / HIT_BOUNCE_DURATION
  if progress >= 1 then
    state.bouncedSize = 0
    state.isBouncing = false
    return
  end

  if progress < 0.5 then
    state.bouncedSize = LockOnManager.HitBounceSize * progress * 2
  else
    state.bouncedSize = LockOnManager.HitBounceSize * (2 - progress * 2)
  end
end

--- Handle late-stage actions such as un-targeting when the weapon is sheathed,
--- bouncing, and other stuff that depends on earlier frame interactions
function LockOnManager:onFrameEnd()
  self:bounce()

  if self.DisableLockWhenSheathing and not isWielding() and self.getTargetObject() then
    changeAndNotifyTarget()
  end
end

---@class TargetChangeData
---@field targets openmw.LObject[]
---@field actor openmw.LObject

---@param targetChangeData TargetChangeData
function LockOnManager.lockOnCombatStart(targetChangeData)
  local targetIsFighting = not not targetChangeData.targets[1]
  local actor = targetChangeData.actor
  local actorIsValid = actor:isValid()

  for i = #ActiveCombatTargets, 1, -1 do
    if not ActiveCombatTargets[i]:isValid() then TableRemove(ActiveCombatTargets, i) end
  end

  if not actorIsValid then return end

  local targetId = actor.id
  if targetIsFighting then
    local alreadyActive = false
    for i = 1, #ActiveCombatTargets do
      if ActiveCombatTargets[i].id == targetId then
        alreadyActive = true
        break
      end
    end

    if not alreadyActive then ActiveCombatTargets[#ActiveCombatTargets + 1] = actor end
  else
    for i = #ActiveCombatTargets, 1, -1 do
      if ActiveCombatTargets[i].id == targetId then TableRemove(ActiveCombatTargets, i) end
    end
  end

  if not LockOnManager.TargetLockToggle then return end

  if
    not LockOnManager.LockOnCombatStart
    or LockOnManager.getTargetObject()
    or not targetIsFighting
    or not I.S3CamHelper.objectIsOnscreen(
      targetChangeData.actor,
      LockOnManager.state.npcHeightOffset
    )
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

  changeAndNotifyTarget(targetChangeData.actor)

  if GetCamMode() == CAM_FP then
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
      if not LockOnManager:ensureTargetingEnabled() then return end

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
    version = 2,
    Manager = LockOnManager,
  },
}
