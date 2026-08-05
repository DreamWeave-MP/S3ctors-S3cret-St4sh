---@omw-context none

---@class DR1PEnum
local Dr1pEnum = {
  ---@class Axes
  ---@field X Vec3X
  ---@field Y Vec3Y
  ---@field Z Vec3Z
  Axis = {
    X = 1,
    Y = 2,
    Z = 3,
  },

  ---@class AuxSlots
  ---@field Belt AuxSlot
  ---@field Amulet AuxSlot
  AuxSlot = {
    Belt = 3,
    Amulet = 4,
  },

  ---@class BodyTypes
  ---@field Vanilla 1
  BodyType = {
    Vanilla = 1,
  },

  ---@class FingerIndices
  ---@field Thumb 1
  ---@field Index 2
  ---@field Middle 3
  ---@field Ring 4
  ---@field Pinky 5
  Finger = {
    Thumb = 1,
    Index = 2,
    Middle = 3,
    Ring = 4,
    Pinky = 5,
  },

  ---@class HandSides
  ---@field Left 1
  ---@field Right 2
  Hand = {
    Left = 1,
    Right = 2,
  },

  ---@class SkeletonVariants
  ---@field FemaleFirst 1
  ---@field HumanoidThird 2
  ---@field HumanoidFirst 3
  ---@field FemaleThird 4
  ---@field BeastThird 5
  ---@field BeastFirst 6
  Skeleton = {
    FemaleFirst = 1,
    HumanoidThird = 2,
    HumanoidFirst = 3,
    FemaleThird = 4,
    BeastThird = 5,
    BeastFirst = 6,
  },

  ---@class TransformComponents
  ---@field Position TransformPosition
  ---@field Rotation TransformRotation
  ---@field Scale TransformScale
  Transform = {
    Position = 1,
    Rotation = 2,
    Scale = 3,
  },

  ---@class VisibilityPolicies
  ---@field All 1
  ---@field ThirdPerson 2
  Visibility = {
    All = 1,
    ThirdPerson = 2,
  },
}

return Dr1pEnum
