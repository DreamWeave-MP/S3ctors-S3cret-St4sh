---@omw-context player

local async = require 'openmw.async'
local core = require 'openmw.core'
local I = require 'openmw.interfaces'
local input = require 'openmw.input'
local self = require 'openmw.self'
local ui = require 'openmw.ui'
local builder = require 'scripts.s3ui.repair.builder'
local data = require 'scripts.s3ui.repair.data'
local meter = require 'scripts.s3ui.repair.meter'
local strike = require 'scripts.s3ui.repair.strike'
local s3math = require 'scripts.s3.math'

local WINDOW = I.UI.WINDOW.Repair
local MODE = I.UI.MODE.Repair

---@class S3UI.RepairWindowModule
local M = {}

local rootElement = nil
local tool = nil
local items = {}
local selectedIndex = 1
local scrollOffset = 0
local hovered = nil
local generation = 0
local armorer = 35
local strikeState = nil
local meterRunning = false
local lastMessage = nil

local function active()
	return rootElement and rootElement.layout and I.UI.isWindowVisible(WINDOW)
end

local function selectedItem()
	return items[selectedIndex]
end

local function clampBounds()
	local maxScroll = s3math.max(0, #items - builder.ROWS_VISIBLE)
	if scrollOffset > maxScroll then
		scrollOffset = maxScroll
	elseif scrollOffset < 0 then
		scrollOffset = 0
	end
	if selectedIndex < 1 then
		selectedIndex = 1
	elseif selectedIndex > #items then
		selectedIndex = #items
	end
end

local function ensureSelectedVisible()
	clampBounds()
	if selectedIndex > 0 and selectedIndex <= scrollOffset then
		scrollOffset = selectedIndex - 1
	elseif selectedIndex > scrollOffset + builder.ROWS_VISIBLE then
		scrollOffset = selectedIndex - builder.ROWS_VISIBLE
	end
end

local function resetStrike()
	strikeState = strike.new(armorer, tool and tool.quality or 1)
	meterRunning = false
	if rootElement then
		meter.update(rootElement, strikeState)
	end
end

local function isAlive(callbackGeneration)
	return callbackGeneration == generation and rootElement and rootElement.layout
end

local refreshItems
local bindMeterFromRoot

local function closeMode()
	I.UI.removeMode(MODE)
end

local function playerObject()
	return self.object or self
end

local function queueRepairRefresh()
	async:newUnsavableSimulationTimer(0, function()
		if active() then
			refreshItems()
			if #items == 0 then
				closeMode()
				return
			end
			M.rebuildElement()
		end
	end)
end

function refreshItems()
	items = data.collectRepairableItems()
	ensureSelectedVisible()
	if #items == 0 then
		selectedIndex = 1
		if active() then
			closeMode()
		end
	end
end

local function expectedGain()
	local item = selectedItem()
	if not item then
		return 0
	end
	return strike.conditionGain(item, armorer, tool and tool.quality or 1, 1)
end

local function layoutCtx()
	local callbackGeneration = generation
	return {
		async = async,
		armorer = armorer,
		cancel = function()
			if isAlive(callbackGeneration) then
				closeMode()
			end
		end,
		expectedGain = expectedGain(),
		hovered = hovered,
		items = items,
		lastMessage = lastMessage,
		meterRunning = meterRunning,
		scrollOffset = scrollOffset,
		select = function(index)
			if isAlive(callbackGeneration) then
				M.select(index)
			end
		end,
		selectedIndex = selectedIndex,
		selectedItem = selectedItem(),
		meterLayout = meter.make(strikeState),
		setHovered = function(name)
			if isAlive(callbackGeneration) then
				hovered = name
				M.rebuildElement()
			end
		end,
		clearHovered = function(name)
			if isAlive(callbackGeneration) and hovered == name then
				hovered = nil
				M.rebuildElement()
			end
		end,
		strike = strikeState,
		strikeNow = function()
			if isAlive(callbackGeneration) then
				M.activateStrike()
			end
		end,
		tool = tool,
	}
end

local rebuildLayout

function M.rebuildElement()
	if not (rootElement and rootElement.layout) then
		return
	end
	rootElement.layout = rebuildLayout()
	rootElement:update()
	bindMeterFromRoot()
end

local function destroyRoot()
	generation = generation + 1
	hovered = nil
	if rootElement and rootElement.layout then
		rootElement:destroy()
	end
	meter.reset()
	rootElement = nil
end

function rebuildLayout()
	return builder.make(layoutCtx())
end

---@param rootLayout openmw.ui.Layout|nil
---@return openmw.ui.Layout|nil
local function meterLayoutFromRoot(rootLayout)
	local selectedContent = nil
	local rootContent = rootLayout and rootLayout.content
	local panel = rootContent and rootContent.s3ui_repair_panel
	local panelContent = panel and panel.content
	local body = panelContent and panelContent.s3ui_repair_panel_body
	local bodyContent = body and body.content
	local columns = bodyContent and bodyContent.s3ui_repair_panel_columns
	local columnsContent = columns and columns.content
	local detailWrapper = columnsContent and columnsContent.s3ui_repair_detail_wrapper
	local detailContent = detailWrapper and detailWrapper.content
	local selectedPanel = detailContent and detailContent.s3ui_repair_selected_panel
	selectedContent = selectedPanel and selectedPanel.content
	return selectedContent and selectedContent.s3ui_repair_meter
end

function bindMeterFromRoot()
	if not (rootElement and rootElement.layout) then
		meter.reset()
		return false
	end
	return meter.bind(meterLayoutFromRoot(rootElement.layout))
end

---@param repairTool openmw.Object|nil
function M.show(repairTool)
	destroyRoot()
	tool = data.toolInfo(repairTool)
	armorer = data.armorerSkill()
	selectedIndex = 1
	scrollOffset = 0
	lastMessage = nil
	refreshItems()
	resetStrike()
	rootElement = ui.create(rebuildLayout())
	bindMeterFromRoot()
end

function M.hide()
	destroyRoot()
	tool = nil
	items = {}
	selectedIndex = 1
	scrollOffset = 0
	lastMessage = nil
	strikeState = nil
	meterRunning = false
end

function M.startStrike()
	if not (active() and selectedItem() and strikeState) then
		return false
	end
	if not tool or tool.uses <= 0 then
		lastMessage = 'The repair tool is spent.'
		closeMode()
		return false
	end
	meterRunning = true
	lastMessage = nil
	M.rebuildElement()
	return true
end

function M.activateStrike()
	if not meterRunning then
		return M.startStrike()
	end
	M.strikeSelected()
	return true
end

---@param index integer
function M.select(index)
	if index < 1 or index > #items then
		return
	end
	selectedIndex = index
	ensureSelectedVisible()
	lastMessage = nil
	resetStrike()
	M.rebuildElement()
end

---@param delta integer
function M.navigate(delta)
	if not active() or #items == 0 then
		return
	end
	M.select(s3math.max(1, s3math.min(#items, selectedIndex + delta)))
end

---@param deltaRows integer
function M.scroll(deltaRows)
	if not active() then
		return
	end
	scrollOffset = scrollOffset + deltaRows
	clampBounds()
	M.rebuildElement()
end

local function refreshAfterRepair()
	local oldItem = selectedItem()
	refreshItems()
	if oldItem and oldItem.item and oldItem.damage > 0 then
		for index, item in ipairs(items) do
			if item.item == oldItem.item then
				selectedIndex = index
				break
			end
		end
	end
	ensureSelectedVisible()
	resetStrike()
end

function M.strikeSelected()
	local item = selectedItem()
	if not (item and strikeState and meterRunning) then
		return
	end
	if not tool or tool.uses <= 0 then
		lastMessage = 'The repair tool is spent.'
		meterRunning = false
		closeMode()
		return
	end
	local rating, performance, wearMultiplier = strike.rating(strikeState)
	local gain = strike.conditionGain(item, armorer, tool.quality, performance)
	local wear = strike.toolWear(tool.quality, wearMultiplier)
	local beforeUses = tool.uses
	local afterUses = s3math.max(0, beforeUses - s3math.max(0, wear))
	local willDestroyTool = afterUses <= 0
	local wasStackedTool = math.floor(tonumber(tool.item and tool.item.count) or 1) > 1
	local applied = data.applyConditionGain(item, gain)
	local consumed = beforeUses - afterUses
	tool.uses = afterUses
	if applied > 0 then
		core.sendGlobalEvent('ModifyItemCondition', { actor = playerObject(), item = item.item, amount = applied })
	end
	if willDestroyTool then
		core.sendGlobalEvent('S3UI_ConsumeRepairTool', {
			player = playerObject(),
			item = tool.item,
			recordId = tool.item.recordId,
			wear = wear,
			expectedBefore = beforeUses,
		})
	else
		core.sendGlobalEvent('S3UI_SetRepairToolCondition', {
			player = playerObject(),
			item = tool.item,
			recordId = tool.item.recordId,
			condition = afterUses,
			wear = wear,
			expectedBefore = beforeUses,
		})
	end
	strikeState.lastRating = rating
	strikeState.lastGain = applied
	strikeState.lastWear = consumed
	lastMessage = rating .. ' strike. +' .. tostring(applied) .. ' condition, -' .. tostring(consumed) .. ' tool uses.'
	if willDestroyTool then
		closeMode()
		return
	end
	if wasStackedTool then
		closeMode()
		return
	end
	refreshAfterRepair()
	if not active() then
		return
	end
	M.rebuildElement()
	queueRepairRefresh()
end

---@param dt number
function M.update(dt)
	if not active() or not meterRunning or not strikeState or #items == 0 then
		return
	end
	local frameDt = core.getRealFrameDuration()
	strike.update(strikeState, frameDt)
	meter.update(rootElement, strikeState)
end

---@param key table
---@return boolean handled
function M.handleKeyPress(key)
	if not active() then
		return false
	end
	if key.code == input.KEY.Escape then
		closeMode()
	elseif key.code == input.KEY.Enter or key.code == input.KEY.NP_Enter then
		M.activateStrike()
	elseif key.code == input.KEY.UpArrow then
		M.navigate(-1)
	elseif key.code == input.KEY.DownArrow then
		M.navigate(1)
	elseif key.code == input.KEY.PageUp then
		M.navigate(-builder.ROWS_VISIBLE)
	elseif key.code == input.KEY.PageDown then
		M.navigate(builder.ROWS_VISIBLE)
	else
		return false
	end
	return true
end

function M.active()
	return active()
end

return M
