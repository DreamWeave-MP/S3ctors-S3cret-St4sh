---@omw-context local | player

local error, next, require, type, StrFormat = error, next, require, type, string.format

local BasePlacement = require 'scripts.s3.dr1p.basePlacement'
local Enum = require 'scripts.s3.dr1p.enum'
local GearPlacement = require 'scripts.s3.dr1p.gearPlacement'
local HeadPlacement = require 'scripts.s3.dr1p.headPlacement'
local RacePlacement = require 'scripts.s3.dr1p.racePlacement'
local SlotToBoneNames = require 'scripts.s3.dr1p.slots'

local Axis, AuxSlot, BodyType, ModelPolicy, Skeleton, Transform =
  Enum.Axis, Enum.AuxSlot, Enum.BodyType, Enum.ModelPolicy, Enum.Skeleton, Enum.Transform

local s3lf = require('openmw.interfaces').s3.lf
local VfsFileExists = require('openmw.vfs').fileExists

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
local ResolvedModels = {
  [ModelPolicy.OptionalSkinReplacement] = {},
  [ModelPolicy.SkinReplacement] = {},
}

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

---@param originalModel string
---@param modelPolicy ModelPolicy
---@return string?
local function resolveModel(originalModel, modelPolicy)
  if modelPolicy == ModelPolicy.Original then return originalModel end

  local resolvedModels = ResolvedModels[modelPolicy]
  local cachedModel = resolvedModels[originalModel]
  if cachedModel then return cachedModel end

  local modelStem, modelExtension = originalModel:match '^(.*)(%.[^./]+)$'
  local replacementModel = StrFormat('%s_skin%s', modelStem, modelExtension)

  if VfsFileExists(replacementModel) then
    resolvedModels[originalModel] = replacementModel
    return replacementModel
  end

  if modelPolicy == ModelPolicy.OptionalSkinReplacement then
    resolvedModels[originalModel] = originalModel
    return originalModel
  end
end

---@param getIsFirstPerson fun(): boolean
---@return DR1PRuntime
return function(getIsFirstPerson)
  ---@type DR1PAttachInfo
  local AttachInfo = {
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
  local function getHandBasePlacement(handSide, finger)
    local skeletonPlacement = BasePlacement[getSkeletonType()]
    if not skeletonPlacement then return end

    local handPlacement = skeletonPlacement[handSide]
    if not handPlacement then return end

    local fingerPlacement = handPlacement[finger]
    if not fingerPlacement then return end

    ---@cast fingerPlacement BaseDR1PPlacementMap
    return fingerPlacement[BodyType.Vanilla]
  end

  ---@param auxSlot AuxSlot
  ---@return DR1PTransform? basePlacement
  local function getAuxBasePlacement(auxSlot)
    local skeletonPlacement = BasePlacement[getSkeletonType()]
    if not skeletonPlacement then return end

    local auxPlacement = skeletonPlacement[auxSlot]
    if not auxPlacement then return end

    return auxPlacement[BodyType.Vanilla]
  end

  ---@param handSide HandSide
  ---@param finger FingerIndex
  ---@return DR1PTransform? racePlacement
  local function getHandRacePlacement(handSide, finger)
    local raceMap = RacePlacement[s3lf.record.race]
    if not raceMap then return end

    local handPlacement = raceMap[handSide]
    if not handPlacement then return end

    return handPlacement[finger]
  end

  ---@param auxSlot AuxSlot
  ---@return DR1PTransform? racePlacement
  local function getAuxRacePlacement(auxSlot)
    local raceMap = RacePlacement[s3lf.record.race]
    return raceMap and raceMap[auxSlot]
  end

  ---@param recordId string
  ---@param boneName string
  ---@param basePlacement DR1PTransform?
  ---@param racePlacement DR1PTransform?
  ---@param modelPolicy ModelPolicy
  ---@param useHeadTransform boolean
  ---@return string?
  local function addAttachment(
    recordId,
    boneName,
    basePlacement,
    racePlacement,
    modelPolicy,
    useHeadTransform
  )
    if not basePlacement then return end
    local mesh = resolveModel(ClothingRecords[recordId].model, modelPolicy)
    if not mesh then return end

    AttachInfo.vfxId = StrFormat('DR1P-%s-%s', s3lf.id, boneName)
    AttachInfo.boneName = boneName

    local headPlacement
    if useHeadTransform then
      local headModel = BodyPartRecords[s3lf.record.head].model
      headPlacement = HeadPlacement[headModel]
    end

    local result = IdentityTransform
    result = result * compilePlacement(basePlacement)
    if racePlacement then result = result * compilePlacement(racePlacement) end
    if useHeadTransform and headPlacement then result = result * compilePlacement(headPlacement) end

    local gearPlacement = GearPlacement[mesh]
    if gearPlacement then result = result * compilePlacement(gearPlacement) end

    AttachInfo.transform = result
    s3lf.addVfx(mesh, AttachInfo)
    return AttachInfo.vfxId
  end

  ---@param item openmw.Object
  ---@param handSide HandSide
  ---@param finger FingerIndex
  ---@param useHeadTransform boolean
  ---@return string?
  local function addRing(item, handSide, finger, useHeadTransform)
    local slotBoneBinding = SlotToBoneNames[handSide]
    if type(slotBoneBinding) ~= 'table' then
      error('Invalid handSide provided to DR1P.addRing: ' .. handSide .. ' !', 2)
    end

    local boneName = slotBoneBinding[finger]
    if not boneName then error('Invalid finger provided to DR1P.addRing: ' .. finger .. ' !', 2) end

    return addAttachment(
      item.recordId,
      boneName,
      getHandBasePlacement(handSide, finger),
      getHandRacePlacement(handSide, finger),
      ModelPolicy.Original,
      useHeadTransform
    )
  end

  ---@param recordId string
  ---@return string?
  local function addAmulet(recordId)
    if getIsFirstPerson() then return end

    local amuletBone = SlotToBoneNames[AuxSlot.Amulet]
    ---@cast amuletBone string

    return addAttachment(
      recordId,
      amuletBone,
      getAuxBasePlacement(AuxSlot.Amulet),
      getAuxRacePlacement(AuxSlot.Amulet),
      ModelPolicy.OptionalSkinReplacement,
      true
    )
  end

  ---@param recordId string
  ---@return string?
  local function addBelt(recordId)
    if getIsFirstPerson() then return end

    local beltBone = SlotToBoneNames[AuxSlot.Belt]
    ---@cast beltBone string

    return addAttachment(
      recordId,
      beltBone,
      getAuxBasePlacement(AuxSlot.Belt),
      getAuxRacePlacement(AuxSlot.Belt),
      ModelPolicy.SkinReplacement,
      false
    )
  end

  return {
    addAmulet = addAmulet,
    addBelt = addBelt,
    addRing = addRing,
    getIsFirstPerson = getIsFirstPerson,
    getSkeletonType = getSkeletonType,
    getSkeletonTypeName = getSkeletonTypeName,
  }
end
