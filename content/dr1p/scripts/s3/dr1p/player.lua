---@omw-context player

local s3lf

local error, next, print, require, StrFormat = error, next, print, require, string.format

local BoneNames = require 'scripts.s3.dr1p.boneNames'
local Enum = require 'scripts.s3.dr1p.enum'
local BodyType, Finger, Hand, Skeleton = Enum.BodyType, Enum.Finger, Enum.Hand, Enum.Skeleton

local BasePlacement = require 'scripts.s3.dr1p.basePlacement'
local GearPlacement = require 'scripts.s3.dr1p.gearPlacement'
local HeadPlacement = require 'scripts.s3.dr1p.headPlacement'
local RacePlacement = require 'scripts.s3.dr1p.racePlacement'
local StateMachine = require 'scripts.s3.statemachine'

---@type string[]
local SkeletonTypesToNames = {}

for name, index in next, Skeleton do
  SkeletonTypesToNames[index] = name
end

local BodyPartRecords, DeepToString, FirstPersonMode, GetCameraMode, IdentityTransform, IsPlayer, ReloadLua, SetCameraMode, ThirdPersonMode, TransformMove, TransformRotateX, TransformRotateY, TransformRotateZ, TransformScale

local ringMesh
do
  local aux_util = require 'openmw_aux.util'
  DeepToString = aux_util.deepToString

  local types = require 'openmw.types'
  ringMesh = types.Clothing.records.exquisite_ring_01.model
  BodyPartRecords = types.BodyPart.records

  local util = require 'openmw.util'
  local transform = util.transform
  IdentityTransform, TransformMove, TransformRotateX, TransformRotateY, TransformRotateZ, TransformScale =
    transform.identity,
    transform.move,
    transform.rotateX,
    transform.rotateY,
    transform.rotateZ,
    transform.scale

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
  transform = IdentityTransform,
  useAmbientLight = false,
  vfxId = '',
}

---@return SkeletonVariant
local function getSkeletonType()
  local isFirstPerson = GetCameraMode() == FirstPersonMode
  local isFemale = not s3lf.isMale
  local isBeast = s3lf.races.records[s3lf.race].isBeast

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
---@return DR1PTransform? basePlacement
local function getBasePlacement(handSide, finger)
  local skeletonType = getSkeletonType()

  local skeletonPlacement = BasePlacement[skeletonType]
  if not skeletonPlacement then return end

  local handPlacement = skeletonPlacement[handSide]
  if not handPlacement then return end

  local fingerPlacement = handPlacement[finger]
  if not fingerPlacement then return end

  return fingerPlacement[BodyType.Vanilla]
end

local CompiledPlacements = {}
---@param placement DR1PTransform
---@return openmw.util.Transform
local function compilePlacement(placement)
  local compiled = CompiledPlacements[placement]
  if compiled then return compiled end

  local transform = IdentityTransform

  local pos = placement.pos
  --- Cod3x bug
  ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
  if pos then transform = transform * TransformMove(pos.x, pos.y, pos.z) end

  local rot = placement.rot
  if rot then
    transform = transform
      * TransformRotateZ(rot.z)
      * TransformRotateY(rot.y)
      * TransformRotateX(rot.x)
  end

  local scale = placement.scale
  if scale then transform = transform * TransformScale(scale.x, scale.y, scale.z) end

  CompiledPlacements[placement] = transform
  return transform
end

---@param basePlacement DR1PTransform?
---@param racePlacement DR1PTransform?
---@param headPlacement DR1PTransform?
---@param gearPlacement DR1PTransform?
---@param useHeadTransform boolean
---@return openmw.util.Transform
local function composeTransforms(
  basePlacement,
  racePlacement,
  headPlacement,
  gearPlacement,
  useHeadTransform
)
  local transform = IdentityTransform

  if basePlacement then transform = transform * compilePlacement(basePlacement) end
  if racePlacement then transform = transform * compilePlacement(racePlacement) end
  if useHeadTransform and headPlacement then
    transform = transform * compilePlacement(headPlacement)
  end
  if gearPlacement then transform = transform * compilePlacement(gearPlacement) end

  return transform
end

---@param handSide HandSide
---@param finger FingerIndex
---@param useHeadTransform boolean
local function addRing(handSide, finger, useHeadTransform)
  local fingerBoneMap = FingersToBoneNames[handSide]
  if not fingerBoneMap then
    error('Invalid handSide provided to DR1P.addRing: ' .. handSide .. ' !', 2)
  end

  local boneName = fingerBoneMap[finger]
  if not boneName then error('Invalid finger provided to DR1P.addRing: ' .. finger .. ' !', 2) end

  RingAttachInfo.vfxId = StrFormat('DR1P-%s-%s', s3lf.id, boneName)
  RingAttachInfo.boneName = boneName

  local basePlacement = getBasePlacement(handSide, finger)
  if not basePlacement then return end

  local raceMap = RacePlacement[s3lf.race]
  ---@type DR1PTransform?
  local racePlacement
  if raceMap then
    local handPlacement = raceMap[handSide]

    if handPlacement then
      ---@cast handPlacement RaceFingerPlacementMap
      racePlacement = handPlacement[finger]
    end
  end

  local headPlacement
  if useHeadTransform then
    local headModel = BodyPartRecords[s3lf.head].model
    headPlacement = HeadPlacement[headModel]
  end

  local transform = composeTransforms(
    basePlacement,
    racePlacement,
    headPlacement,
    GearPlacement[ringMesh],
    useHeadTransform
  )

  RingAttachInfo.transform = transform

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
  addRing(Hand.Left, Finger.Thumb, false)
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
  addRing(Hand.Left, Finger.Index, false)
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
