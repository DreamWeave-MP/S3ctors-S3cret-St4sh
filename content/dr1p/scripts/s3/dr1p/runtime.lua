---@omw-context local | player

local error, next, require, type, StrFormat = error, next, require, type, string.format

local BasePlacement = require 'scripts.s3.dr1p.basePlacement'
local Enum = require 'scripts.s3.dr1p.enum'
local GearPlacement = require 'scripts.s3.dr1p.gearPlacement'
local HeadPlacement = require 'scripts.s3.dr1p.headPlacement'
local RacePlacement = require 'scripts.s3.dr1p.racePlacement'
local SlotToBoneNames = require 'scripts.s3.dr1p.slots'

local Axis, BodyType, Skeleton, Transform = Enum.Axis, Enum.BodyType, Enum.Skeleton, Enum.Transform

local s3lf = require('openmw.interfaces').s3.lf

local types = require 'openmw.types'
local BodyPartRecords = types.BodyPart.records
local ClothingRecords = types.Clothing.records
local RaceRecords = s3lf.races.records

local util = require 'openmw.util'
local transform = util.transform
local IdentityTransform, TransformMove, TransformRotateX, TransformRotateY, TransformRotateZ, TransformScale =
  transform.identity,
  transform.move,
  transform.rotateX,
  transform.rotateY,
  transform.rotateZ,
  transform.scale

---@type table<DR1PTransform, openmw.util.Transform>
local CompiledPlacements = {}
---@param placement DR1PTransform
---@return openmw.util.Transform
local function compilePlacement(placement)
  local compiled = CompiledPlacements[placement]
  if compiled then return compiled end

  local result = IdentityTransform

  local pos = placement[Transform.Position]
  ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
  if pos then result = result * TransformMove(pos[Axis.X], pos[Axis.Y], pos[Axis.Z]) end

  local rot = placement[Transform.Rotation]
  if rot then
    result = result
      * TransformRotateZ(rot[Axis.Z])
      * TransformRotateY(rot[Axis.Y])
      * TransformRotateX(rot[Axis.X])
  end

  local scale = placement[Transform.Scale]
  if scale then result = result * TransformScale(scale[Axis.X], scale[Axis.Y], scale[Axis.Z]) end

  CompiledPlacements[placement] = result
  return result
end

---@param getIsFirstPerson fun(): boolean
---@return DR1PRuntime
return function(getIsFirstPerson)
  ---@type DR1PAttachInfo
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
    local actorRecord = s3lf.record
    local isBeast = RaceRecords[actorRecord.race].isBeast

    if getIsFirstPerson() then
      if isBeast then
        return Skeleton.BeastFirst
      elseif not actorRecord.isMale then
        return Skeleton.FemaleFirst
      else
        return Skeleton.HumanoidFirst
      end
    elseif isBeast then
      return Skeleton.BeastThird
    elseif not actorRecord.isMale then
      return Skeleton.FemaleThird
    else
      return Skeleton.HumanoidThird
    end
  end

  ---@type table<SkeletonVariant, string>
  local SkeletonTypesToNames = {}
  for name, index in next, Skeleton do
    SkeletonTypesToNames[index] = name
  end

  ---@return string
  local function getSkeletonTypeName() return SkeletonTypesToNames[getSkeletonType()] end

  ---@param handSide HandSide
  ---@param finger FingerIndex
  ---@return DR1PTransform? basePlacement
  local function getBasePlacement(handSide, finger)
    local skeletonPlacement = BasePlacement[getSkeletonType()]
    if not skeletonPlacement then return end

    local handPlacement = skeletonPlacement[handSide]
    if not handPlacement then return end

    local fingerPlacement = handPlacement[finger]
    if not fingerPlacement then return end

    return fingerPlacement[BodyType.Vanilla]
  end

  ---@param item openmw.Object
  ---@param handSide HandSide
  ---@param finger FingerIndex
  ---@param useHeadTransform boolean
  ---@return string?
  local function addRing(item, handSide, finger, useHeadTransform)
    local slotBoneBinding = SlotToBoneNames[handSide]
    if not slotBoneBinding then
      error('Invalid handSide provided to DR1P.addRing: ' .. handSide .. ' !', 2)
    end

    local boneName
    if type(slotBoneBinding) == 'table' then
      boneName = slotBoneBinding[finger]
    else
      boneName = slotBoneBinding
    end

    if not boneName then error('Invalid finger provided to DR1P.addRing: ' .. finger .. ' !', 2) end

    local ringMesh = ClothingRecords[item.recordId].model

    RingAttachInfo.vfxId = StrFormat('DR1P-%s-%s', s3lf.id, boneName)
    RingAttachInfo.boneName = boneName

    local basePlacement = getBasePlacement(handSide, finger)
    if not basePlacement then return end

    local raceMap = RacePlacement[s3lf.record.race]
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
      local headModel = BodyPartRecords[s3lf.record.head].model
      headPlacement = HeadPlacement[headModel]
    end

    local result = IdentityTransform
    result = result * compilePlacement(basePlacement)
    if racePlacement then result = result * compilePlacement(racePlacement) end
    if useHeadTransform and headPlacement then result = result * compilePlacement(headPlacement) end

    local gearPlacement = GearPlacement[ringMesh]
    if gearPlacement then result = result * compilePlacement(gearPlacement) end

    RingAttachInfo.transform = result
    s3lf.addVfx(ringMesh, RingAttachInfo)
    return RingAttachInfo.vfxId
  end

  return {
    addRing = addRing,
    getSkeletonType = getSkeletonType,
    getSkeletonTypeName = getSkeletonTypeName,
  }
end
