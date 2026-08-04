---@omw-context player

local s3lf

local error, next, print, require, StrFormat = error, next, print, require, string.format

local BoneNames = require 'scripts.s3.dr1p.boneNames'
local Enum = require 'scripts.s3.dr1p.enum'
local Finger, Hand, Skeleton = Enum.Finger, Enum.Hand, Enum.Skeleton

local Placement = require 'scripts.s3.dr1p.basePlacement'
local StateMachine = require 'scripts.s3.statemachine'

---@type string[]
local SkeletonTypesToNames = {}

for name, index in next, Skeleton do
  SkeletonTypesToNames[index] = name
end

local DeepToString, FirstPersonMode, GetCameraMode, IsPlayer, ReloadLua, SetCameraMode, ThirdPersonMode, Transform, Vector3

local ringMesh
do
  local aux_util = require 'openmw_aux.util'
  DeepToString = aux_util.deepToString

  local types = require 'openmw.types'
  ringMesh = types.Clothing.records.exquisite_ring_01.model

  local util = require 'openmw.util'
  Transform, Vector3 = util.transform, util.vector3

  s3lf = require('openmw.interfaces').s3.lf

  IsPlayer = s3lf.actorType == 0

  if IsPlayer then
    local camera = require 'openmw.camera'
    FirstPersonMode, GetCameraMode, SetCameraMode, ThirdPersonMode =
      camera.MODE.FirstPerson, camera.getMode, camera.setMode, camera.MODE.ThirdPerson

    ReloadLua = require('openmw.debug').reloadLua
  end
end

---@type table<HandSide, table<FingerIndex, string>>
local FingersToBoneNames = {
  [Hand.Left] = {
    [Finger.Thumb] = BoneNames[1],
    [Finger.Index] = BoneNames[2],
    [Finger.Middle] = BoneNames[3],
    [Finger.Ring] = BoneNames[4],
    [Finger.Pinky] = BoneNames[5],
  },
  [Hand.Right] = {
    [Finger.Thumb] = BoneNames[6],
    [Finger.Index] = BoneNames[7],
    [Finger.Middle] = BoneNames[8],
    [Finger.Ring] = BoneNames[9],
    [Finger.Pinky] = BoneNames[10],
  },
}

local RingAttachInfo = {
  autoTransform = false,
  boneName = '',
  loop = true,
  transform = Transform.identity,
  useAmbientLight = false,
  vfxId = '',
}

---@return SkeletonVariant
local function getSkeletonType()
  local isFirstPerson = GetCameraMode() == FirstPersonMode
  local isFemale = not s3lf.isMale
  local isBeast = s3lf.races.records[s3lf.race].isBeast

  print(isFemale, isBeast, isFirstPerson)

  if isFirstPerson then
    if isBeast then
      return Skeleton.BeastFirst
    elseif isFemale then
      return Skeleton.FemaleFirst
    else
      return Skeleton.HumanoidFirst
    end
  else
    if isBeast then
      return Skeleton.BeastThird
    elseif isFemale then
      return Skeleton.FemaleThird
    else
      return Skeleton.HumanoidThird
    end
  end
end

---@return string
local function getSkeletonTypeName() return SkeletonTypesToNames[getSkeletonType()] end

--- Gets the final relative transform for ring placment,
--- Per-finger, per-race, and optionally, per-item
---@param handSide HandSide
---@param finger FingerIndex
---@return DR1PTransform? ringOffset
local function getRingPlacement(handSide, finger)
  local skeletonType = getSkeletonType()

  local skeletonPlacement = Placement[skeletonType]
  if not skeletonPlacement then return end

  local handPlacement = skeletonPlacement[handSide]
  if not handPlacement then return end

  local fingerPlacement = handPlacement[finger]
  if not fingerPlacement then return end

  -- Only handle bodies for now, not equipment
  local ringPlacement = fingerPlacement[Enum.BodyType.Vanilla]

  return ringPlacement
end

---@param handSide HandSide
---@param finger FingerIndex
local function addRing(handSide, finger)
  local fingerBoneMap = FingersToBoneNames[handSide]
  if not fingerBoneMap then
    error('Invalid handSide provided to DR1P.addRing: ' .. handSide .. ' !', 2)
  end

  local boneName = fingerBoneMap[finger]
  if not boneName then error('Invalid finger provided to DR1P.addRing: ' .. finger .. ' !', 2) end

  RingAttachInfo.vfxId = StrFormat('DR1P-%s-%s', s3lf.id, boneName)
  RingAttachInfo.boneName = boneName

  local ringPlacement = getRingPlacement(handSide, finger)
  if not ringPlacement then return end

  local transform = Transform.identity

  if ringPlacement.pos then
    local pos = ringPlacement.pos

    transform = transform * Transform.move(Vector3(pos.x, pos.y, pos.z))
  end

  if ringPlacement.rot then
    local rot = ringPlacement.rot

    transform = transform
      * Transform.rotateZ(rot.z)
      * Transform.rotateY(rot.y)
      * Transform.rotateX(rot.x)
  end

  if ringPlacement.scale then
    local scale = ringPlacement.scale

    transform = transform * Transform.scale(scale.x, scale.y, scale.z)
  end

  RingAttachInfo.transform = transform

  print(DeepToString(ringPlacement, 3), transform)

  s3lf.addVfx(ringMesh, RingAttachInfo)
end

local wasFirstPerson = false
local detourMode, restoreMode
local cameraRebuild = StateMachine.new()

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
  addRing(Hand.Left, Finger.Thumb)
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
  addRing(Hand.Left, Finger.Index)
  cameraRebuild:jump 'idle'
end)

cameraRebuild:start 'idle'

local section = require('openmw.storage').playerSection 'DR1PTESTSTORAGE'

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
  interfaceName = 'DR1P',
  interface = {
    addRing = addRing,
    getSkeletonType = getSkeletonType,
    getSkeletonTypeName = getSkeletonTypeName,
    BodyType = Enum.BodyType,
    Finger = Enum.Finger,
    Hand = Enum.Hand,
    Skeleton = Enum.Skeleton,
  },
}
