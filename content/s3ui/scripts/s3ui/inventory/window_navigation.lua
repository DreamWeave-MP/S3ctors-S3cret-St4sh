---@omw-context player

local data = require 'scripts.s3ui.inventory.data'
local equipmentData = require 'scripts.s3ui.inventory.equipment_data'
local actions = require 'scripts.s3ui.inventory.actions'

---@class S3UI.InventoryWindowNavigationModule
local M = {}

local function orderedEquipmentSlots()
	return equipmentData.orderedSlots(equipmentData.collectGroups())
end

local function equipmentSelectionIndex(state, slots)
	for index, slot in ipairs(slots) do
		if slot and slot.key == state.selectedEquipmentSlotKey then
			return index
		end
	end
	return nil
end

local function firstEquipmentSlot(slots)
	for index = 1, #slots do
		if slots[index] then
			return slots[index]
		end
	end
	return nil
end

local function lastEquipmentSlot(slots)
	for index = #slots, 1, -1 do
		if slots[index] then
			return slots[index]
		end
	end
	return nil
end

local function wrapIndex(index, count)
	while index > count do
		index = index - count
	end
	while index < 1 do
		index = index + count
	end
	return index
end

local function selectEquipmentByOffset(ctx, delta)
	local slots = orderedEquipmentSlots()
	if #slots == 0 then
		return
	end
	local currentIndex = equipmentSelectionIndex(ctx.state, slots)
	local targetIndex = currentIndex and (currentIndex + delta) or (delta >= 0 and 1 or #slots)
	local step = delta >= 0 and 1 or -1
	local attempts = 0
	targetIndex = wrapIndex(targetIndex, #slots)
	while attempts < #slots do
		local slot = slots[targetIndex]
		if slot then
			ctx.selectEquipmentSlot(slot)
			return
		end
		targetIndex = wrapIndex(targetIndex + step, #slots)
		attempts = attempts + 1
	end
end

local function navigateInventorySelection(ctx, direction)
	local state = ctx.state
	local entries = state:buildEntries(data.collectItems(), data.CATEGORY_ORDER)
	if #entries == 0 then
		ctx.clearSelection()
		return
	end
	local metrics = ctx.layoutMetrics()
	local capacity = state:visibleSlotCount(metrics)
	local currentIndex = nil
	if state.selectedSlotIndex ~= nil and state.selectedSlotViewMode == state.viewMode then
		currentIndex = state.scrollOffset + state.selectedSlotIndex
	end
	local targetIndex
	if currentIndex then
		targetIndex = currentIndex + direction
		if targetIndex > #entries then
			targetIndex = 1
		elseif targetIndex < 1 then
			targetIndex = #entries
		end
	elseif direction > 0 then
		targetIndex = math.min(state.scrollOffset + 1, #entries)
	else
		targetIndex = math.min(state.scrollOffset + capacity, #entries)
	end
	local oldOffset = state.scrollOffset
	state.scrollOffset = state:scrollOffsetForSelection(targetIndex, direction, metrics)
	state:clampScroll(#entries, metrics)
	local slotIndex = targetIndex - state.scrollOffset
	if slotIndex < 1 or slotIndex > capacity then
		return
	end
	local entry = entries[targetIndex]
	ctx.selectVisibleSlot(slotIndex, entry and entry.kind == 'item' and entry.data or nil)
	if state.scrollOffset ~= oldOffset then
		ctx.queueRebuild()
	end
end

---@param ctx S3UI.InventoryNavigationContext
---@param deltaRows integer
function M.scrollRows(ctx, deltaRows)
	if ctx.state.primaryTab == 'equipment' then
		ctx.selectEquipmentSlot(
			equipmentData.spatialNeighbor(equipmentData.collectGroups(), ctx.state.selectedEquipmentSlotKey, deltaRows)
		)
		return
	end
	if ctx.state:scrollRows(deltaRows, ctx.layoutMetrics(), ctx.state.lastEntryCount) then
		ctx.queueRebuild()
	end
end

---@param ctx S3UI.InventoryNavigationContext
function M.home(ctx)
	if ctx.state.primaryTab == 'equipment' then
		ctx.selectEquipmentSlot(firstEquipmentSlot(orderedEquipmentSlots()))
	elseif ctx.state:home() then
		ctx.queueRebuild()
	end
end

---@param ctx S3UI.InventoryNavigationContext
function M.endScroll(ctx)
	if ctx.state.primaryTab == 'equipment' then
		ctx.selectEquipmentSlot(lastEquipmentSlot(orderedEquipmentSlots()))
	elseif ctx.state:endScroll(ctx.layoutMetrics()) then
		ctx.queueRebuild()
	end
end

---@param ctx S3UI.InventoryNavigationContext
---@param direction integer
function M.navigateSelection(ctx, direction)
	if ctx.state.primaryTab == 'equipment' then
		selectEquipmentByOffset(ctx, direction)
	else
		navigateInventorySelection(ctx, direction)
	end
end

---@param ctx S3UI.InventoryNavigationContext
function M.activateSelection(ctx)
	if ctx.state.primaryTab == 'equipment' then
		local slot = equipmentData.findSlot(equipmentData.collectGroups(), ctx.state.selectedEquipmentSlotKey)
		if slot and slot.itemData then
			ctx.activateEquipmentSlot(slot)
		elseif slot then
			ctx.openEquipmentCategory(slot)
		end
	elseif ctx.state.selectedDisplayData then
		actions.activateItem(ctx.state.selectedDisplayData, ctx.actionCtx())
	end
end

return M
