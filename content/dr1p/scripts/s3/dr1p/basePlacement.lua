---@omw-context none

local Dr1pEnum = require 'scripts.s3.dr1p.enum'
local AuxSlot, BodyType, Finger, Hand, Skeleton =
  Dr1pEnum.AuxSlot, Dr1pEnum.BodyType, Dr1pEnum.Finger, Dr1pEnum.Hand, Dr1pEnum.Skeleton

local Radians = math.rad

---@type SkeletonDR1PPlacementMap
local Placements = {
  [Skeleton.FemaleFirst] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [BodyType.Vanilla] = {
          pos = {
            x = 0.6,
            y = -0.55,
            z = 0.10,
          },
          rot = {
            x = Radians(-150),
            y = Radians(75),
            z = Radians(-60),
          },
          scale = {
            x = 0.5,
            y = 0.55,
            z = 0.5,
          },
        },
      },
      [Finger.Index] = {
        [BodyType.Vanilla] = {
          pos = {
            x = 1,
            y = 0.75,
            z = -0.2,
          },
          rot = {
            x = Radians(-50),
            y = Radians(-90),
            z = Radians(0),
          },
          scale = {
            x = 0.5,
            y = 0.5,
            z = 0.5,
          },
        },
      },
    },
    -- Doing belts before right hands means it's no longer an array
    -- Also we don't have belt meshes yet anyway
    -- [AuxSlot.Belt] = {
    --   [BodyType.Vanilla] = {
    --     pos = {
    --       x = 0,
    --       y = 0,
    --       z = 0,
    --     },
    --     rot = {
    --       x = Radians(0),
    --       y = Radians(0),
    --       z = Radians(0),
    --     },
    --     scale = {
    --       x = 1,
    --       y = 1,
    --       z = 1,
    --     },
    --   },
    -- },
  },
}

return Placements
