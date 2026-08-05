---@omw-context none

local Dr1pEnum = require 'scripts.s3.dr1p.enum'
local AuxSlot, Axis, BodyType, Finger, Hand, Skeleton, Transform =
  Dr1pEnum.AuxSlot,
  Dr1pEnum.Axis,
  Dr1pEnum.BodyType,
  Dr1pEnum.Finger,
  Dr1pEnum.Hand,
  Dr1pEnum.Skeleton,
  Dr1pEnum.Transform

local Radians = math.rad

---@type SkeletonDR1PPlacementMap
local Placements = {
  [Skeleton.FemaleFirst] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 0.6,
            [Axis.Y] = -0.55,
            [Axis.Z] = 0.10,
          },
          [Transform.Rotation] = {
            [Axis.X] = Radians(-150),
            [Axis.Y] = Radians(75),
            [Axis.Z] = Radians(-60),
          },
          [Transform.Scale] = {
            [Axis.X] = 0.5,
            [Axis.Y] = 0.55,
            [Axis.Z] = 0.5,
          },
        },
      },
      [Finger.Index] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 1,
            [Axis.Y] = 0.75,
            [Axis.Z] = -0.2,
          },
          [Transform.Rotation] = {
            [Axis.X] = Radians(-50),
            [Axis.Y] = Radians(-90),
            [Axis.Z] = Radians(0),
          },
          [Transform.Scale] = {
            [Axis.X] = 0.5,
            [Axis.Y] = 0.5,
            [Axis.Z] = 0.5,
          },
        },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 0.2,
            [Axis.Y] = -0.25,
            [Axis.Z] = -0.35,
          },
          [Transform.Rotation] = {
            [Axis.X] = Radians(-165),
            [Axis.Y] = Radians(120),
            [Axis.Z] = Radians(-75),
          },
          [Transform.Scale] = {
            [Axis.X] = 0.5,
            [Axis.Y] = 0.55,
            [Axis.Z] = 0.5,
          },
        },
      },
      [Finger.Index] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 1,
            [Axis.Y] = 0.75,
            [Axis.Z] = -0.2,
          },
          [Transform.Rotation] = {
            [Axis.X] = Radians(-50),
            [Axis.Y] = Radians(-90),
            [Axis.Z] = Radians(0),
          },
          [Transform.Scale] = {
            [Axis.X] = 0.5,
            [Axis.Y] = 0.5,
            [Axis.Z] = 0.5,
          },
        },
      },
    },
    -- Doing belts before right hands means it's no longer an array
    -- Also we don't have belt meshes yet anyway
    -- [AuxSlot.Belt] = {
    --   [BodyType.Vanilla] = {
    --     [Transform.Position] = {
    --       [Axis.X] = 0,
    --       [Axis.Y] = 0,
    --       [Axis.Z] = 0,
    --     },
    --     [Transform.Rotation] = {
    --       [Axis.X] = Radians(0),
    --       [Axis.Y] = Radians(0),
    --       [Axis.Z] = Radians(0),
    --     },
    --     [Transform.Scale] = {
    --       [Axis.X] = 1,
    --       [Axis.Y] = 1,
    --       [Axis.Z] = 1,
    --     },
    --   },
    -- },
  },
  [Skeleton.FemaleThird] = {
    [AuxSlot.Amulet] = {
      [BodyType.Vanilla] = {
        [Transform.Position] = {
          [Axis.X] = -2.3,
          [Axis.Y] = 6,
          [Axis.Z] = 0,
        },

        [Transform.Rotation] = {
          [Axis.X] = Radians(90),
          [Axis.Y] = Radians(95),
          [Axis.Z] = Radians(50),
        },

        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
  },
  [Skeleton.HumanoidThird] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 0.95,
            [Axis.Y] = -0.250,
            [Axis.Z] = 0.05,
          },

          [Transform.Rotation] = {
            [Axis.X] = Radians(180),
            [Axis.Y] = Radians(90),
            [Axis.Z] = Radians(00),
          },

          [Transform.Scale] = {
            [Axis.X] = 0.5,
            [Axis.Y] = 0.5,
            [Axis.Z] = 0.5,
          },
        },
      },
      [Finger.Index] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 1.25,
            [Axis.Y] = -0.00,
            [Axis.Z] = 1.00,
          },

          [Transform.Rotation] = {
            [Axis.X] = Radians(00),
            [Axis.Y] = Radians(-90),
            [Axis.Z] = Radians(0),
          },
          [Transform.Scale] = {
            [Axis.X] = 0.40,
            [Axis.Y] = 0.40,
            [Axis.Z] = 0.40,
          },
        },
      },
    },
    [Hand.Right] = {
      [Finger.Index] = {
        [BodyType.Vanilla] = {
          [Transform.Position] = {
            [Axis.X] = 1.25,
            [Axis.Y] = -0.00,
            [Axis.Z] = 1.00,
          },

          [Transform.Rotation] = {
            [Axis.X] = Radians(00),
            [Axis.Y] = Radians(-90),
            [Axis.Z] = Radians(0),
          },
          [Transform.Scale] = {
            [Axis.X] = 0.40,
            [Axis.Y] = 0.40,
            [Axis.Z] = 0.40,
          },
        },
      },
    },
    [Hand.Right] = {},
    [AuxSlot.Amulet] = {
      [BodyType.Vanilla] = {
        [Transform.Position] = {
          [Axis.X] = -2.3,
          [Axis.Y] = 6,
          [Axis.Z] = 0,
        },

        [Transform.Rotation] = {
          [Axis.X] = Radians(90),
          [Axis.Y] = Radians(95),
          [Axis.Z] = Radians(50),
        },

        [Transform.Scale] = {
          [Axis.X] = 1,
          [Axis.Y] = 1,
          [Axis.Z] = 1,
        },
      },
    },
  },
}

return Placements
