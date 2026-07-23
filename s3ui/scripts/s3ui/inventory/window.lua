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
local navigation = require 'scripts.s3ui.inventory.window_navigation'
local stateFactory = require 'scripts.s3ui.inventory.state'
local transition = require 'scripts.s3ui.inventory.transition'
local nullFunction = require 'scripts.s3.nullFunction'

local v2 = util.vector2

local WINDOW = I.UI.WINDOW.Inventory
local ROOT_LAYER = 'Windows'

---@class S3UI.InventoryWindowModule
local M = {}

local rootElement = nil
local equipmentLeftElement = nil
local equipmentDetailElement = nil
local rebuildInventoryPending = false
local rebuildEventQueued = false
local deferredRebuildPending = false
local deferredRebuildReady = false
local deferredRebuildTimerQueued = false
local deferredRebuildTimerSerial = 0
---@type S3UI.InventoryMetrics|nil
local activeLayoutMetrics = nil
local state = stateFactory.new()
local queueRebuild
local queueDeferredRebuild
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
	return rootElement
		and rootElement.layout
		and I.UI.isWindowVisible(WINDOW)
		and not (animation and animation.phase == transition.CLOSING)
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

function queueDeferredRebuild()
	details.hide()
	deferredRebuildPending = true
	if deferredRebuildTimerQueued then
		return
	end
	deferredRebuildTimerQueued = true
	deferredRebuildTimerSerial = deferredRebuildTimerSerial + 1
	local timerSerial = deferredRebuildTimerSerial
	async:newUnsavableSimulationTimer(0, function()
		if timerSerial ~= deferredRebuildTimerSerial then
			return
		end
		deferredRebuildTimerQueued = false
		if not deferredRebuildPending then
			return
		end
		deferredRebuildReady = true
		rebuildEventQueued = true
		self:sendEvent 'S3UI_RebuildInventory'
	end)
end

local function destroyRoot()
	stopAnimation()
	countModal.hide()
	state:bumpGeneration()
	rebuildInventoryPending = false
	rebuildEventQueued = false
	deferredRebuildPending = false
	deferredRebuildReady = false
	deferredRebuildTimerQueued = false
	deferredRebuildTimerSerial = deferredRebuildTimerSerial + 1
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

local function closeInventoryForRepair(onClosed)
	M.hide(onClosed)
end

local function actionCtx()
	return {
		closeInventoryForRepair = closeInventoryForRepair,
		queueRebuild = queueRebuild,
	}
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
		closeInventoryForRepair = closeInventoryForRepair,
		metrics = layoutMetrics,
		queueRebuild = queueRebuild,
		selectSlot = selectVisibleSlot,
		state = state,
	}
end

local function navigationCtx()
	return {
		actionCtx = actionCtx,
		activateEquipmentSlot = activateEquipmentSlot,
		clearSelection = clearSelection,
		layoutMetrics = layoutMetrics,
		openEquipmentCategory = openEquipmentCategory,
		queueRebuild = queueRebuild,
		selectEquipmentSlot = selectEquipmentSlot,
		selectVisibleSlot = selectVisibleSlot,
		state = state,
	}
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

function M.hide(onHidden)
	if animation and animation.phase == transition.CLOSING then
		return
	end
	if not (rootElement and rootElement.layout) then
		destroyRoot()
		inventoryCamera.restoreCamera()
		inventoryCamera.restoreHudVisibility()
		if onHidden then
			onHidden()
		end
		return
	end

	local metrics = activeLayoutMetrics or layout.compute()
	local startPosition = currentRootPosition() or metrics.windowRelativePosition
	state:bumpGeneration()
	rebuildInventoryPending = false
	rebuildEventQueued = false
	deferredRebuildPending = false
	deferredRebuildReady = false
	deferredRebuildTimerQueued = false
	deferredRebuildTimerSerial = deferredRebuildTimerSerial + 1
	countModal.hide()
	details.hide()
	beginAnimation(transition.CLOSING, startPosition, offscreenLeftPosition(metrics), function()
		destroyRoot()
		inventoryCamera.restoreHudVisibility()
		if onHidden then
			onHidden()
		end
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
	local immediatePending = rebuildInventoryPending
	local deferredReady = deferredRebuildReady
	if not (immediatePending or deferredReady) then
		return
	end
	if not active() then
		return
	end
	if immediatePending then
		rebuildInventoryPending = false
	end
	if deferredReady then
		deferredRebuildPending = false
		deferredRebuildReady = false
	end
	rebuildRoot(currentRootPosition())
end

M.queueRebuild = queueRebuild
M.queueDeferredRebuild = queueDeferredRebuild

---@param deltaRows integer
function M.scrollRows(deltaRows)
	if not active() then
		return
	end
	navigation.scrollRows(navigationCtx(), deltaRows)
end

function M.home()
	if not active() then
		return
	end
	navigation.home(navigationCtx())
end

function M.endScroll()
	if not active() then
		return
	end
	navigation.endScroll(navigationCtx())
end

---@param direction integer
function M.navigateSelection(direction)
	if not active() then
		return
	end
	navigation.navigateSelection(navigationCtx(), direction)
end

function M.activateSelection()
	if not active() then
		return
	end
	navigation.activateSelection(navigationCtx())
end

M.active = active

return M
