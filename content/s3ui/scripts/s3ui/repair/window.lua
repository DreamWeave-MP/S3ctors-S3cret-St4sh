---@omw-context player

local async = require 'openmw.async'
local I = require 'openmw.interfaces'
local input = require 'openmw.input'
local ui = require 'openmw.ui'
local builder = require 'scripts.s3ui.repair.builder'
local data = require 'scripts.s3ui.repair.data'
local strike = require 'scripts.s3ui.repair.strike'
local s3math = require 'scripts.s3.math'

local WINDOW = I.UI.WINDOW.Repair
local MODE = I.UI.MODE.Repair

---@class S3UI.RepairWindowModule
local M = {}

local rootElement = nil
local meterElement = nil
local tool = nil
local items = {}
local selectedIndex = 1
local scrollOffset = 0
local hovered = nil
local generation = 0
local armorer = 35
local strikeState = nil
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
	if meterElement and meterElement.layout then
		builder.updateMeter(meterElement, strikeState, true)
	end
end

local function isAlive(callbackGeneration)
	return callbackGeneration == generation and rootElement and rootElement.layout
end

local function closeMode()
	I.UI.removeMode(MODE)
end

local function refreshItems()
	items = data.collectRepairableItems()
	ensureSelectedVisible()
	if #items == 0 then
		selectedIndex = 1
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
		scrollOffset = scrollOffset,
		select = function(index)
			if isAlive(callbackGeneration) then
				M.select(index)
			end
		end,
		selectedIndex = selectedIndex,
		selectedItem = selectedItem(),
		meterElement = meterElement,
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
				M.strikeSelected()
			end
		end,
		tool = tool,
	}
end

function M.rebuildElement()
	if not (rootElement and rootElement.layout) then
		return
	end
	rootElement.layout = builder.make(layoutCtx())
	rootElement:update()
end

local function destroyRoot()
	generation = generation + 1
	hovered = nil
	if meterElement and meterElement.layout then
		meterElement:destroy()
	end
	meterElement = nil
	if rootElement and rootElement.layout then
		rootElement:destroy()
	end
	rootElement = nil
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
	meterElement = ui.create(builder.meterLayout { strike = strikeState })
	rootElement = ui.create(builder.make(layoutCtx()))
end

function M.hide()
	destroyRoot()
	tool = nil
	items = {}
	selectedIndex = 1
	scrollOffset = 0
	lastMessage = nil
	strikeState = nil
	meterElement = nil
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
	if not (item and strikeState) then
		return
	end
	if not tool or tool.uses <= 0 then
		lastMessage = 'The repair tool is spent.'
		M.rebuildElement()
		return
	end
	local rating, performance, wearMultiplier = strike.rating(strikeState)
	local gain = strike.conditionGain(item, armorer, tool.quality, performance)
	local wear = strike.toolWear(tool.quality, wearMultiplier)
	local applied = data.applyConditionGain(item, gain)
	local consumed = data.consumeToolUses(tool, wear)
	strikeState.lastRating = rating
	strikeState.lastGain = applied
	strikeState.lastWear = consumed
	lastMessage = rating .. ' strike. +' .. tostring(applied) .. ' condition, -' .. tostring(consumed) .. ' tool uses.'
	refreshAfterRepair()
	M.rebuildElement()
end

---@param dt number
function M.update(dt)
	if not active() or not strikeState or #items == 0 then
		return
	end
	strike.update(strikeState, dt)
	builder.updateMeter(meterElement, strikeState, false)
end

---@param key table
---@return boolean handled
function M.handleKeyPress(key)
	if not active() then
		return false
	end
	if key.code == input.KEY.Escape then
		closeMode()
	elseif key.code == input.KEY.Enter or key.code == input.KEY.NP_Enter or key.code == input.KEY.Space then
		M.strikeSelected()
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
