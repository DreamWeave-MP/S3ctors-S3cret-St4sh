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

---@class DR1PTransform
---@field pos DR1PVec3
---@field rot DR1PVec3 In radians
---@field scale DR1PVec3

---@class DR1PVec3
---@field x number
---@field y number
---@field z number
