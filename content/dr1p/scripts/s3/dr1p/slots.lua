---@omw-context none

local BoneNames = require 'scripts.s3.dr1p.boneNames'
local Enum = require 'scripts.s3.dr1p.enum'
local AuxSlot, Finger, Hand = Enum.AuxSlot, Enum.Finger, Enum.Hand

---@type SlotBoneMap
local SlotToBoneNames = {
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
  [AuxSlot.Amulet] = BoneNames[11],
  [AuxSlot.Belt] = BoneNames[12],
}

return SlotToBoneNames
