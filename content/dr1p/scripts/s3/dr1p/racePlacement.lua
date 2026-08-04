---@omw-context none

local Dr1pEnum = require 'scripts.s3.dr1p.enum'
local AuxSlot, Finger, Hand = Dr1pEnum.AuxSlot, Dr1pEnum.Finger, Dr1pEnum.Hand

---@type table<string, RacePlacementMap>
local RacePlacement = {
  ['redguard'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['dark elf'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['imperial'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['breton'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['nord'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['wood elf'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['high elf'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['khajiit'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['argonian'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
  ['orc'] = {
    [Hand.Left] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [Hand.Right] = {
      [Finger.Thumb] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Index] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Middle] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Ring] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
      [Finger.Pinky] = {
        pos = { x = 0, y = 0, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
        scale = { x = 1, y = 1, z = 1 },
      },
    },
    [AuxSlot.Belt] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
    [AuxSlot.Amulet] = {
      pos = { x = 0, y = 0, z = 0 },
      rot = { x = 0, y = 0, z = 0 },
      scale = { x = 1, y = 1, z = 1 },
    },
  },
}

return RacePlacement
