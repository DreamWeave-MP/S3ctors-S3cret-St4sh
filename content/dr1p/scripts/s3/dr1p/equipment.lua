---@omw-context local | player

local require = require

local Enum = require 'scripts.s3.dr1p.enum'
local s3lf = require('openmw.interfaces').s3.lf

local EquipmentSlots = s3lf.EQUIPMENT_SLOT
local GetEquipment = s3lf.getEquipment
local RemoveVfx = s3lf.removeVfx
local Finger, Hand = Enum.Finger, Enum.Hand

---@type DR1PTrackedSlot[]
local Slots = {
  {
    equipmentSlot = EquipmentSlots.LeftRing,
    handSide = Hand.Left,
    finger = Finger.Thumb,
  },
  {
    equipmentSlot = EquipmentSlots.RightRing,
    handSide = Hand.Right,
    finger = Finger.Thumb,
  },
  { equipmentSlot = EquipmentSlots.Amulet },
  { equipmentSlot = EquipmentSlots.Belt },
  { equipmentSlot = EquipmentSlots.LeftGauntlet },
  { equipmentSlot = EquipmentSlots.RightGauntlet },
}

local SlotCount = #Slots
local PollableSlots = { 1, 2 }
local PollableSlotCount = #PollableSlots

---@param runtime DR1PRuntime
---@return DR1PEquipmentTracker
return function(runtime)
  ---@type table<number, openmw.Object|false>
  local trackedItems = { false, false, false, false, false, false }

  ---@type table<number, string|false>
  local trackedItemIds = { false, false, false, false, false, false }

  ---@type table<number, string|false>
  local trackedVfxIds = { false, false, false, false, false, false }

  local nextPollIndex = 1
  local forceCheck = true

  ---@param slotIndex number
  local function removeVfx(slotIndex)
    local vfxId = trackedVfxIds[slotIndex]
    if not vfxId then return end

    RemoveVfx(vfxId)
    trackedVfxIds[slotIndex] = false
  end

  ---@param slotIndex number
  local function checkSlot(slotIndex)
    local slot = Slots[slotIndex]
    local item = GetEquipment(slot.equipmentSlot)
    local itemId = item and item.id or false

    if not forceCheck and itemId == trackedItemIds[slotIndex] then return end

    removeVfx(slotIndex)
    trackedItems[slotIndex] = item or false
    trackedItemIds[slotIndex] = itemId

    if item then
      trackedVfxIds[slotIndex] = runtime.addRing(item, slot.handSide, slot.finger, false) or false
    end
  end

  local function checkNextSlot()
    checkSlot(PollableSlots[nextPollIndex])

    if nextPollIndex == PollableSlotCount then
      nextPollIndex = 1
      forceCheck = false
    else
      nextPollIndex = nextPollIndex + 1
    end
  end

  local function reapplyTrackedVfx()
    for pollIndex = 1, PollableSlotCount do
      local slotIndex = PollableSlots[pollIndex]
      local slot = Slots[slotIndex]
      local item = trackedItems[slotIndex]

      if item then
        removeVfx(slotIndex)
        trackedVfxIds[slotIndex] = runtime.addRing(item, slot.handSide, slot.finger, false) or false
      end
    end
  end

  local function reset()
    for slotIndex = 1, SlotCount do
      trackedItems[slotIndex] = false
      trackedItemIds[slotIndex] = false
      trackedVfxIds[slotIndex] = false
    end

    nextPollIndex = 1
    forceCheck = true
  end

  return {
    checkNextSlot = checkNextSlot,
    reapplyTrackedVfx = reapplyTrackedVfx,
    reset = reset,
  }
end
