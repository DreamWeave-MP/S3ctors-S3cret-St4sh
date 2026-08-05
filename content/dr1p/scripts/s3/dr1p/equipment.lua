---@omw-context local | player

local require = require

local Enum = require 'scripts.s3.dr1p.enum'
local s3lf = require('openmw.interfaces').s3.lf

local EquipmentSlots = s3lf.EQUIPMENT_SLOT
local GetEquipment = s3lf.getEquipment
local RemoveVfx = s3lf.removeVfx
local AuxSlot, Finger, Hand, Visibility = Enum.AuxSlot, Enum.Finger, Enum.Hand, Enum.Visibility

---@type DR1PTrackedSlot[]
local Slots = {
  {
    equipmentSlot = EquipmentSlots.LeftRing,
    attachmentSlot = Hand.Left,
    finger = Finger.Index,
    useHeadTransform = false,
    visibility = Visibility.All,
  },
  {
    equipmentSlot = EquipmentSlots.RightRing,
    attachmentSlot = Hand.Right,
    finger = Finger.Index,
    useHeadTransform = false,
    visibility = Visibility.All,
  },
  {
    equipmentSlot = EquipmentSlots.Amulet,
    attachmentSlot = AuxSlot.Amulet,
    useHeadTransform = true,
    visibility = Visibility.ThirdPerson,
  },
  {
    equipmentSlot = EquipmentSlots.Belt,
    attachmentSlot = AuxSlot.Belt,
    useHeadTransform = false,
    visibility = Visibility.ThirdPerson,
  },
  {
    equipmentSlot = EquipmentSlots.LeftGauntlet,
    useHeadTransform = false,
    visibility = Visibility.ThirdPerson,
  },
  {
    equipmentSlot = EquipmentSlots.RightGauntlet,
    useHeadTransform = false,
    visibility = Visibility.ThirdPerson,
  },
}

local PollableSlots = { 1, 2, 3, 4 }
local PollableSlotCount, SlotCount = #PollableSlots, #Slots

---@param runtime DR1PRuntime
---@return DR1PEquipmentTracker
return function(runtime)
  local AddAmulet, AddBelt, AddRing = runtime.addAmulet, runtime.addBelt, runtime.addRing
  local GetIsFirstPerson = runtime.getIsFirstPerson

  ---@type table<number, string|false>
  local trackedItemIds = { false, false, false, false, false, false }

  ---@type table<number, string|false>
  local trackedVfxIds = { false, false, false, false, false, false }

  local pendingVfxRemovals = {}
  local nextPollIndex = 1
  local forceCheck = true

  ---@param slotIndex number
  local function removeVfx(slotIndex)
    local vfxId = trackedVfxIds[slotIndex]
    if not vfxId then return end

    RemoveVfx(vfxId)
    trackedVfxIds[slotIndex] = false
  end

  ---@param slot DR1PTrackedSlot
  local function isVisible(slot) return slot.visibility == Visibility.All or not GetIsFirstPerson() end

  ---@param slot DR1PTrackedSlot
  ---@param item openmw.Object
  ---@return string?
  local function addVfx(slot, item)
    local attachmentSlot = slot.attachmentSlot
    if attachmentSlot == AuxSlot.Amulet then return AddAmulet(item.recordId) end
    if attachmentSlot == AuxSlot.Belt then return AddBelt(item.recordId) end
    if attachmentSlot ~= Hand.Left and attachmentSlot ~= Hand.Right then return end

    ---@cast attachmentSlot HandSide
    return AddRing(item, attachmentSlot, slot.finger, slot.useHeadTransform)
  end

  ---@param slotIndex number
  ---@param force boolean?
  local function checkSlot(slotIndex, force)
    local slot = Slots[slotIndex]
    local item = GetEquipment(slot.equipmentSlot)
    local itemId = item and item.id or false

    if not force and not forceCheck and itemId == trackedItemIds[slotIndex] then return end

    removeVfx(slotIndex)
    trackedItemIds[slotIndex] = itemId

    if item then trackedVfxIds[slotIndex] = addVfx(slot, item) or false end
  end

  local function checkNextSlot()
    local slotIndex = PollableSlots[nextPollIndex]
    if isVisible(Slots[slotIndex]) then checkSlot(slotIndex) end

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

      if isVisible(slot) then
        checkSlot(slotIndex, true)
      else
        removeVfx(slotIndex)
        trackedItemIds[slotIndex] = false
      end
    end

    nextPollIndex = 1
    forceCheck = true
  end

  local function resetRuntimeState()
    for slotIndex = 1, SlotCount do
      trackedItemIds[slotIndex] = false
      trackedVfxIds[slotIndex] = false
    end

    nextPollIndex = 1
    forceCheck = true
  end

  local function onSave()
    local vfxIds = {}
    for slotIndex = 1, SlotCount do
      vfxIds[slotIndex] = trackedVfxIds[slotIndex] or pendingVfxRemovals[slotIndex] or false
    end

    return {
      version = 1,
      vfxIds = vfxIds,
    }
  end

  ---@param data? table
  local function onLoad(data)
    pendingVfxRemovals = {}

    local savedVfxIds = data and data.version == 1 and data.vfxIds
    if savedVfxIds then
      for slotIndex = 1, SlotCount do
        local vfxId = savedVfxIds[slotIndex]
        if vfxId then pendingVfxRemovals[slotIndex] = vfxId end
      end
    end

    resetRuntimeState()
  end

  local function flushPendingVfxRemovals()
    for slotIndex = 1, SlotCount do
      local vfxId = pendingVfxRemovals[slotIndex]
      if vfxId then
        RemoveVfx(vfxId)
        pendingVfxRemovals[slotIndex] = false
      end
    end
  end

  return {
    checkNextSlot = checkNextSlot,
    flushPendingVfxRemovals = flushPendingVfxRemovals,
    onLoad = onLoad,
    onSave = onSave,
    reapplyTrackedVfx = reapplyTrackedVfx,
  }
end
