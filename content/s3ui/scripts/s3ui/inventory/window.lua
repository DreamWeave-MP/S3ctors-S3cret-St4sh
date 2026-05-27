---@omw-context player

local async = require 'openmw.async'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local countModal = require 'scripts.s3ui.components.count_modal'
local actions = require 'scripts.s3ui.inventory.actions'
local builder = require 'scripts.s3ui.inventory.builder'
local data = require 'scripts.s3ui.inventory.data'
local detailsFactory = require 'scripts.s3ui.inventory.details'
local equipmentData = require 'scripts.s3ui.inventory.equipment_data'
local equipmentView = require 'scripts.s3ui.inventory.equipment_view'
local inventoryCamera = require 'scripts.s3ui.player_camera'
local layout = require 'scripts.s3ui.inventory.layout'
local stateFactory = require 'scripts.s3ui.inventory.state'
local transition = require 'scripts.s3ui.inventory.transition'
local nullFunction = require 'scripts.s3.nullFunction'

local v2 = util.vector2

local WINDOW = I.UI.WINDOW.Inventory
local ROOT_LAYER = 'Windows'

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
local updateAnimation

---@type fun(dt: number)
local currentUpdate = nullFunction

---@type table|nil
local animation = nil

local function layoutMetrics()
	return activeLayoutMetrics or layout.compute()
end

local details = detailsFactory.new {
	metrics = layoutMetrics,
	root = function()
		return rootElement
	end,
	rootLayer = ROOT_LAYER,
}

local function active()
	return rootElement and rootElement.layout and I.UI.isWindowVisible(WINDOW)
end

local function stopAnimation()
	animation = nil
	currentUpdate = nullFunction
end

---@param metrics S3UI.InventoryMetrics
local function offscreenLeftPosition(metrics)
	return v2(-metrics.windowSize.x / metrics.screen.x, metrics.windowRelativePosition.y)
end

local function currentRootPosition()
	if rootElement and rootElement.layout and rootElement.layout.props then
		return rootElement.layout.props.relativePosition
	end
	return nil
end

local function applyRootPosition(position)
	if not (rootElement and rootElement.layout) then
		return
	end
	rootElement.layout.props.relativePosition = position
	rootElement:update()
end

local function beginAnimation(phase, startPosition, targetPosition, onDone)
	animation = {
		phase = phase,
		elapsed = 0,
		duration = transition.duration(phase),
		startPosition = startPosition,
		targetPosition = targetPosition,
		onDone = onDone,
	}
	applyRootPosition(startPosition)
	currentUpdate = updateAnimation
end

local function finishAnimation()
	local done = animation and animation.onDone or nil
	if animation then
		applyRootPosition(animation.targetPosition)
	end
	stopAnimation()
	if done then
		done()
	end
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
	if state.primaryTab ~= 'equipment' then
		return
	end
	groups = groups or equipmentData.collectGroups()
	local selectedSlot = equipmentData.findSlot(groups, state.selectedEquipmentSlotKey)
	if selectedSlot then
		state:selectEquipmentSlot(selectedSlot)
	end
	local ctx = equipmentCtx(groups)
	equipmentView.updateLeftPanel(equipmentLeftElement, ctx)
	equipmentView.updateDetailPanel(equipmentDetailElement, ctx)
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
	self:sendEvent 'S3UI_RebuildInventory'
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
	state:setPrimaryTab 'inventory'
	for _, category in ipairs(data.CATEGORY_ORDER) do
		if category.key ~= 'all' then
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
		detailElement = equipmentDetailElement,
		leftElement = equipmentLeftElement,
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

local function orderedEquipmentSlots(groups)
	return equipmentData.orderedSlots(groups)
end

local function equipmentSelectionIndex(slots)
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

local function selectEquipmentByOffset(delta)
	local slots = orderedEquipmentSlots(equipmentData.collectGroups())
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
	local step = delta >= 0 and 1 or -1
	local attempts = 0
	while attempts < #slots do
		local slot = slots[targetIndex]
		if slot then
			selectEquipmentSlot(slot)
			return
		end
		targetIndex = targetIndex + step
		while targetIndex > #slots do
			targetIndex = targetIndex - #slots
		end
		while targetIndex < 1 do
			targetIndex = targetIndex + #slots
		end
		attempts = attempts + 1
	end
end

local function makeInventoryLayout(items, rootPosition)
	activeLayoutMetrics = layout.compute()
	local metrics = activeLayoutMetrics
	local windowRelativePosition = type(rootPosition) == 'function' and rootPosition(metrics) or rootPosition
	local entries = state.primaryTab == 'inventory' and state:buildEntries(items, data.CATEGORY_ORDER) or {}
	local equipmentGroups = equipmentData.collectGroups()
	local selectedEquipmentSlot = equipmentData.findSlot(equipmentGroups, state.selectedEquipmentSlotKey)
	if selectedEquipmentSlot then
		state:selectEquipmentSlot(selectedEquipmentSlot)
	elseif state.primaryTab == 'equipment' then
		state.selectedEquipmentData = nil
	end
	state.lastEntryCount = #entries
	state:clampScroll(#entries, metrics)
	local firstIndex = state.scrollOffset + 1
	state.selectedDisplayData = state:selectedEntryData(entries, firstIndex)
	if state.primaryTab == 'equipment' then
		equipmentLeftElement = equipmentView.createLeftPanel(equipmentCtx(equipmentGroups))
		equipmentDetailElement = equipmentView.createDetailPanel(equipmentCtx(equipmentGroups))
	else
		equipmentLeftElement = nil
		equipmentDetailElement = nil
	end
	return builder.make {
		controlsCtx = controlsCtx(),
		details = details,
		equipmentCtx = equipmentCtx(equipmentGroups),
		entries = entries,
		firstIndex = firstIndex,
		metrics = metrics,
		rootLayer = ROOT_LAYER,
		state = state,
		viewCtx = viewCtx(),
		windowRelativePosition = windowRelativePosition,
	}
end

local function destroyRoot()
	stopAnimation()
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
	activeLayoutMetrics = nil
	state:resetTransientSelection()
end

local function rebuildRoot(rootPosition)
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
	rootElement = ui.create(makeInventoryLayout(data.collectItems(), rootPosition))
	if activeLayoutMetrics.detailMode == 'side' then
		details.createSideTooltip()
	end
	if state.selectedSlotIndex ~= nil and state.selectedDisplayData then
		details.update(state.selectedDisplayData)
	end
	state.selectedDisplayData = nil
end

function updateAnimation(dt)
	if not animation then
		currentUpdate = nullFunction
		return
	end

	animation.elapsed = animation.elapsed + (tonumber(dt) or 0)
	local rawT = animation.elapsed / animation.duration
	local t = transition.progress(animation.phase, rawT)
	applyRootPosition(animation.startPosition + (animation.targetPosition - animation.startPosition) * t)

	if rawT >= 1 then
		finishAnimation()
	end
end

function M.show()
	destroyRoot()
	inventoryCamera.saveHudVisibility()
	inventoryCamera.showStaticInventoryCamera()
	rebuildRoot(offscreenLeftPosition)
	local metrics = activeLayoutMetrics
	beginAnimation(transition.OPENING, offscreenLeftPosition(metrics), metrics.windowRelativePosition)
end

function M.hide()
	if not (rootElement and rootElement.layout) then
		destroyRoot()
		inventoryCamera.restoreCamera()
		inventoryCamera.restoreHudVisibility()
		return
	end

	local metrics = activeLayoutMetrics or layout.compute()
	local startPosition = currentRootPosition() or metrics.windowRelativePosition
	state:bumpGeneration()
	rebuildInventoryPending = false
	rebuildEventQueued = false
	countModal.hide()
	details.hide()
	beginAnimation(transition.CLOSING, startPosition, offscreenLeftPosition(metrics), function()
		destroyRoot()
		inventoryCamera.restoreHudVisibility()
	end)
	inventoryCamera.restoreCamera()
end

function M.destroyInstant()
	destroyRoot()
	inventoryCamera.restoreHudVisibility()
end

function M.update(dt)
	currentUpdate(dt)
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
	rebuildRoot(currentRootPosition())
end

function M.scrollRows(deltaRows)
	if not active() then
		return
	end
	if state.primaryTab == 'equipment' then
		selectEquipmentSlot(
			equipmentData.spatialNeighbor(equipmentData.collectGroups(), state.selectedEquipmentSlotKey, deltaRows)
		)
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
	if state.primaryTab == 'equipment' then
		local slots = orderedEquipmentSlots(equipmentData.collectGroups())
		selectEquipmentSlot(firstEquipmentSlot(slots))
	elseif state:home() then
		queueRebuild()
	end
end

function M.endScroll()
	if not active() then
		return
	end
	if state.primaryTab == 'equipment' then
		local slots = orderedEquipmentSlots(equipmentData.collectGroups())
		selectEquipmentSlot(lastEquipmentSlot(slots))
	elseif state:endScroll(layoutMetrics()) then
		queueRebuild()
	end
end

function M.navigateSelection(direction)
	if not active() then
		return
	end
	if state.primaryTab == 'equipment' then
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
	selectVisibleSlot(slotIndex, entry and entry.kind == 'item' and entry.data or nil)
	if state.scrollOffset ~= oldOffset then
		queueRebuild()
	end
end

function M.activateSelection()
	if not active() then
		return
	end
	if state.primaryTab == 'equipment' then
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
