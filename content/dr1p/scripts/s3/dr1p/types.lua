---@omw-context none

---@meta

---@alias BodyType
---| 1 # Vanilla

---@alias FingerIndex
---| 1 # Thumb
---| 2 # Index
---| 3 # Middle
---| 4 # Ring
---| 5 # Pinky

---@alias AuxSlot
---| 3 # Belt
---| 4 # Amulet

---@alias AuxPlacementMap table<AuxSlot, BaseDR1PPlacementMap>
---@alias BaseDR1PPlacementMap table<BodyType, DR1PTransform>
---@alias DR1PPlacementMap HandPlacementMap | AuxPlacementMap
---@alias FingerPlacementMap table<FingerIndex, BaseDR1PPlacementMap>
---@alias HandPlacementMap table<HandSide, FingerPlacementMap>
---@alias RaceFingerPlacementMap table<FingerIndex, DR1PTransform>
---@alias RacePlacementMap table<number, DR1PTransform | RaceFingerPlacementMap>

---@alias HandSide
---| 1 # Left
---| 2 # Right

---@alias SkeletonDR1PPlacementMap table<SkeletonVariant, DR1PPlacementMap>

---@alias SkeletonVariant
---| 1 # FemaleFirst - base_anim_female.1st
---| 2 # HumanoidThird - xbase_anim
---| 3 # HumanoidFirst - xbase_anim.1st
---| 4 # FemaleThird - xbase_anim_female
---| 5 # BeastThird - xbase_animkna
---| 6 # BeastFirst - xbase_animkna.1st

---@alias SlotBoneBinding table<FingerIndex, string> | string
---@alias SlotBoneMap table<SlotIndex, SlotBoneBinding>
---@alias SlotIndex HandSide | AuxSlot
---@alias TransformPosition 1
---@alias TransformRotation 2
---@alias TransformScale 3
---@alias Vec3X 1
---@alias Vec3Y 2
---@alias Vec3Z 3

---@alias Visibility
---| 1 # All
---| 2 # ThirdPerson

---@class DR1PInterface
---@field AuxSlot AuxSlots
---@field BodyType BodyTypes
---@field Finger FingerIndices
---@field Hand HandSides
---@field Skeleton SkeletonVariants
---@field addRing fun(item: openmw.Object, handSide: HandSide, finger: FingerIndex, useHeadTransform: boolean): string?
---@field addAmulet fun(recordId: string): string?
---@field getSkeletonType fun(): SkeletonVariant
---@field getSkeletonTypeName fun(): string

---@class DR1PAttachInfo
---@field autoTransform boolean
---@field boneName string
---@field loop boolean
---@field transform openmw.util.Transform
---@field useAmbientLight boolean
---@field vfxId string

---@class DR1PRuntime
---@field addRing fun(item: openmw.Object, handSide: HandSide, finger: FingerIndex, useHeadTransform: boolean): string?
---@field addAmulet fun(recordId: string): string?
---@field getSkeletonType fun(): SkeletonVariant
---@field getSkeletonTypeName fun(): string
---@field getIsFirstPerson fun(): boolean

---@class DR1PTrackedSlot
---@field attachmentSlot SlotIndex?
---@field equipmentSlot number
---@field finger FingerIndex?
---@field useHeadTransform boolean
---@field visibility Visibility

---@class DR1PEquipmentTracker
---@field checkNextSlot fun()
---@field flushPendingVfxRemovals fun()
---@field onLoad fun(data?: table)
---@field onSave fun(): table
---@field reapplyTrackedVfx fun()

---@class DR1PInterfaceDefinition
---@field interfaceName string
---@field interface DR1PInterface

---@class openmw.interfaces
---@field DR1P DR1PInterface

---@class DR1PTransform
---@field [TransformPosition] DR1PVec3 Position
---@field [TransformRotation] DR1PVec3 Rotation In radians
---@field [TransformScale] DR1PVec3 Scale

---@class DR1PVec3
---@field [Vec3X] number X Axis
---@field [Vec3Y] number Y Axis
---@field [Vec3Z] number Z Axis
