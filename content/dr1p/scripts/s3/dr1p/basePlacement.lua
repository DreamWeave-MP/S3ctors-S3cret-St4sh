---@omw-context none

local Dr1pEnum = require 'scripts.s3.dr1p.enum'
local AuxSlot, BodyType, Finger, Hand, Skeleton =
  Dr1pEnum.AuxSlot, Dr1pEnum.BodyType, Dr1pEnum.Finger, Dr1pEnum.Hand, Dr1pEnum.Skeleton

local Radians = math.rad

---@type SkeletonDR1PPlacementMap
local Placements = {
  [Skeleton.FemaleFirst] = {
    [Hand.Left] = {
      [Finger.Index] = {
        [BodyType.Vanilla] = {
          pos = {
            x = 0,
            y = 0,
            z = 0,
          },
          rot = {
            x = Radians(0),
            y = Radians(0),
            z = Radians(0),
          },
          scale = {
            x = 0.5,
            y = 0.5,
            z = 0.5,
          },
        },
      },
      [Finger.Thumb] = {
        [BodyType.Vanilla] = {
          pos = {
            x = 0.6,
            y = -0.25,
            z = -0.20,
          },
          rot = {
            x = Radians(195),
            y = Radians(60),
            z = Radians(-60),
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
