---@omw-context player

local async = require("openmw.async")
local I = require("openmw.interfaces")
local self = require("openmw.self")
local ui = require("openmw.ui")
local countModal = require("scripts.s3ui.components.count_modal")
local actions = require("scripts.s3ui.inventory.actions")
local builder = require("scripts.s3ui.inventory.builder")
local data = require("scripts.s3ui.inventory.data")
local detailsFactory = require("scripts.s3ui.inventory.details")
local equipmentData = require("scripts.s3ui.inventory.equipment_data")
local equipmentView = require("scripts.s3ui.inventory.equipment_view")
local inventoryCamera = require("scripts.s3ui.player_camera")
local layout = require("scripts.s3ui.inventory.layout")
local stateFactory = require("scripts.s3ui.inventory.state")

local WINDOW = I.UI.WINDOW.Inventory
local ROOT_LAYER = "Windows"

local M = {}

local rootElement = nil
local equipmentLeftElement = nil
local equipmentDetailElement = nil
local rebuildInventoryPending = false
local rebuildEventQueued = false
---@type S3UI.InventoryMetrics|nil
local activeLayoutMetrics = nil
local state = stateFactory.new()
local queueRebuild
local equipmentCtx

local function layoutMetrics()
	return activeLayoutMetrics or layout.compute()
end

local details = detailsFactory.new({
	metrics = layoutMetrics,
	root = function()
		return rootElement
	end,
	rootLayer = ROOT_LAYER,
})

local function active()
	return rootElement and rootElement.layout and I.UI.isWindowVisible(WINDOW)
end

local function clearSelection()
	state:clearSelection()
	details.hide()
end

local function selectVisibleSlot(slotIndex, itemData)
	state:selectVisibleSlot(slotIndex, itemData)
	if itemData then
		details.update(itemData)
	else
		details.hide()
	end
end

local function updateEquipmentPanels(groups)
	if state.primaryTab ~= "equipment" then
		return
	end
	groups = groups or equipmentData.collectGroups()
	local selectedSlot = equipmentData.findSlot(groups, state.selectedEquipmentSlotKey)
	if selectedSlot then
		state:selectEquipmentSlot(selectedSlot)
	end
	equipmentView.updateLeftPanel(equipmentLeftElement, equipmentCtx(groups))
	equipmentView.updateDetailPanel(equipmentDetailElement, state)
end

local function selectEquipmentSlot(slot)
	local selectedKey = slot and slot.key or nil
	if state.selectedEquipmentSlotKey == selectedKey then
		return
	end
	state:selectEquipmentSlot(slot)
	details.hide()
	updateEquipmentPanels()
end

function queueRebuild()
	details.hide()
	rebuildInventoryPending = true
	if rebuildEventQueued then
		return
	end
	rebuildEventQueued = true
	self:sendEvent("S3UI_RebuildInventory")
end

local function actionCtx()
	return { queueRebuild = queueRebuild }
end

local function activateEquipmentSlot(slot)
	actions.activateEquipmentSlot(slot, actionCtx())
end

local function openEquipmentCategory(slot)
	local categoryKey = slot and slot.inventoryCategoryKey
	if not categoryKey then
		return
	end
	state:setPrimaryTab("inventory")
	for _, category in ipairs(data.CATEGORY_ORDER) do
		if category.key ~= "all" then
			state.collapsedCategories[category.key] = category.key ~= categoryKey
		end
	end
	queueRebuild()
end

local function controlsCtx()
	return {
		async = async,
		clearSelection = clearSelection,
		metrics = layoutMetrics,
		queueRebuild = queueRebuild,
		state = state,
	}
end

equipmentCtx = function(groups)
	return {
		async = async,
		leftElement = equipmentLeftElement,
		detailElement = equipmentDetailElement,
		groups = groups,
		metrics = layoutMetrics,
		queueRebuild = queueRebuild,
		activateEquipmentSlot = activateEquipmentSlot,
		openEquipmentCategory = openEquipmentCategory,
		selectEquipmentSlot = selectEquipmentSlot,
		state = state,
	}
end

local function viewCtx()
	return {
		async = async,
		clearSelection = clearSelection,
		metrics = layoutMetrics,
		queueRebuild = queueRebuild,
		selectSlot = selectVisibleSlot,
		state = state,
	}
end

local function flatEquipmentSlots(groups)
	local slots = {}
	for _, group in ipairs(groups or {}) do
		for _, slot in ipairs(group.slots or {}) do
			slots[#slots + 1] = slot
		end
	end
	return slots
end

local function equipmentSelectionIndex(slots)
	for index, slot in ipairs(slots) do
		if slot.key == state.selectedEquipmentSlotKey then
			return index
		end
	end
	return nil
end

local function selectEquipmentByOffset(delta)
	local slots = flatEquipmentSlots(equipmentData.collectGroups())
	if #slots == 0 then
		return
	end
	local currentIndex = equipmentSelectionIndex(slots)
	local targetIndex = currentIndex and (currentIndex + delta) or (delta >= 0 and 1 or #slots)
	while targetIndex > #slots do
		targetIndex = targetIndex - #slots
	end
	while targetIndex < 1 do
		targetIndex = targetIndex + #slots
	end
	selectEquipmentSlot(slots[targetIndex])
end

local function makeInventoryLayout(items)
	activeLayoutMetrics = layout.compute()
	local metrics = activeLayoutMetrics
	local entries = state.primaryTab == "inventory" and state:buildEntries(items, data.CATEGORY_ORDER) or {}
	local equipmentGroups = equipmentData.collectGroups()
	local selectedEquipmentSlot = equipmentData.findSlot(equipmentGroups, state.selectedEquipmentSlotKey)
	if selectedEquipmentSlot then
		state:selectEquipmentSlot(selectedEquipmentSlot)
	elseif state.primaryTab == "equipment" then
		state.selectedEquipmentData = nil
	end
	state.lastEntryCount = #entries
	state:clampScroll(#entries, metrics)
	local firstIndex = state.scrollOffset + 1
	state.selectedDisplayData = state:selectedEntryData(entries, firstIndex)
	if state.primaryTab == "equipment" then
		equipmentLeftElement = equipmentView.createLeftPanel(equipmentCtx(equipmentGroups))
		equipmentDetailElement = equipmentView.createDetailPanel(state)
	else
		equipmentLeftElement = nil
		equipmentDetailElement = nil
	end
	return builder.make({
		controlsCtx = controlsCtx(),
		details = details,
		equipmentCtx = equipmentCtx(equipmentGroups),
		entries = entries,
		firstIndex = firstIndex,
		metrics = metrics,
		rootLayer = ROOT_LAYER,
		state = state,
		viewCtx = viewCtx(),
	})
end

local function destroyRoot()
	countModal.hide()
	state:bumpGeneration()
	rebuildInventoryPending = false
	rebuildEventQueued = false
	details.destroy()
	if equipmentLeftElement and equipmentLeftElement.layout then
		equipmentLeftElement:destroy()
	end
	equipmentLeftElement = nil
	if equipmentDetailElement and equipmentDetailElement.layout then
		equipmentDetailElement:destroy()
	end
	equipmentDetailElement = nil
	if rootElement and rootElement.layout then
		rootElement:destroy()
	end
	rootElement = nil
	state:resetTransientSelection()
end

local function rebuildRoot()
	state:bumpGeneration()
	details.hide()
	if equipmentLeftElement and equipmentLeftElement.layout then
		equipmentLeftElement:destroy()
	end
	equipmentLeftElement = nil
	if equipmentDetailElement and equipmentDetailElement.layout then
		equipmentDetailElement:destroy()
	end
	equipmentDetailElement = nil
	if rootElement and rootElement.layout then
		rootElement:destroy()
	end
	details.destroy()
	rootElement = ui.create(makeInventoryLayout(data.collectItems()))
	if activeLayoutMetrics.detailMode == "side" then
		details.createSideTooltip()
	end
	if state.selectedSlotIndex ~= nil and state.selectedDisplayData then
		details.update(state.selectedDisplayData)
	end
	state.selectedDisplayData = nil
end

function M.show()
	destroyRoot()
	inventoryCamera.saveHudVisibility()
	inventoryCamera.showStaticInventoryCamera()
	rebuildRoot()
end

function M.hide()
	destroyRoot()
	inventoryCamera.restoreCamera()
	inventoryCamera.restoreHudVisibility()
end

function M.processPendingRebuild()
	rebuildEventQueued = false
	if not rebuildInventoryPending then
		return
	end
	rebuildInventoryPending = false
	if not active() then
		return
	end
	rebuildRoot()
end

function M.scrollRows(deltaRows)
	if not active() then
		return
	end
	if state.primaryTab == "equipment" then
		selectEquipmentByOffset(deltaRows * 3)
		return
	end
	if state:scrollRows(deltaRows, layoutMetrics(), state.lastEntryCount) then
		queueRebuild()
	end
end

function M.home()
	if not active() then
		return
	end
	if state.primaryTab == "equipment" then
		local slots = flatEquipmentSlots(equipmentData.collectGroups())
		selectEquipmentSlot(slots[1])
	elseif state:home() then
		queueRebuild()
	end
end

function M.endScroll()
	if not active() then
		return
	end
	if state.primaryTab == "equipment" then
		local slots = flatEquipmentSlots(equipmentData.collectGroups())
		selectEquipmentSlot(slots[#slots])
	elseif state:endScroll(layoutMetrics()) then
		queueRebuild()
	end
end

function M.navigateSelection(direction)
	if not active() then
		return
	end
	if state.primaryTab == "equipment" then
		selectEquipmentByOffset(direction)
		return
	end
	local entries = state:buildEntries(data.collectItems(), data.CATEGORY_ORDER)
	if #entries == 0 then
		clearSelection()
		return
	end
	local metrics = layoutMetrics()
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
	selectVisibleSlot(slotIndex, entry and entry.kind == "item" and entry.data or nil)
	if state.scrollOffset ~= oldOffset then
		queueRebuild()
	end
end

function M.activateSelection()
	if not active() then
		return
	end
	if state.primaryTab == "equipment" then
		local slot = equipmentData.findSlot(equipmentData.collectGroups(), state.selectedEquipmentSlotKey)
		if slot and slot.itemData then
			activateEquipmentSlot(slot)
		elseif slot then
			openEquipmentCategory(slot)
		end
	elseif state.selectedDisplayData then
		actions.activateItem(state.selectedDisplayData, actionCtx())
	end
end

M.active = active

return M
