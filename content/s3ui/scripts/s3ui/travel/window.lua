---@omw-context player

local async = require 'openmw.async'
local core = require 'openmw.core'
local I = require 'openmw.interfaces'
local input = require 'openmw.input'
local self = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local builder = require 'scripts.s3ui.travel.builder'
local data = require 'scripts.s3ui.travel.data'

local WINDOW = I.UI.WINDOW.Travel
local MODE = I.UI.MODE.Travel

---@class S3UI.TravelWindowModule
local M = {}

local rootElement = nil
local targetActor = nil
local rows = {}
local selectedIndex = 1
local scrollOffset = 0
local hovered = nil
local generation = 0
local followerRequestId = 0
local followers = {}
local followerKeys = {}
local hooks = {}
local renderer = nil

local function validObject(object)
	return object and object.isValid and object:isValid()
end

local function objectKey(object)
	if not validObject(object) then
		return nil
	end
	return object.id or tostring(object)
end

local function closeEnoughForTravel(follower)
	return validObject(follower)
		and types.Actor.objectIsInstance(follower)
		and types.Actor.getStance(follower) == types.Actor.STANCE.Nothing
		and (follower.position - self.position):length2() <= 800 * 800
end

local function isAlive(callbackGeneration)
	return callbackGeneration == generation and rootElement and rootElement.layout
end

local function active()
	return rootElement and rootElement.layout and (not WINDOW or I.UI.isWindowVisible(WINDOW))
end

local function callHook(name, ...)
	local hook = hooks[name]
	if type(hook) ~= 'function' then
		return nil
	end
	local ok, result = pcall(hook, ...)
	if ok then
		return result
	end
	return nil
end

local function clampBounds()
	local maxScroll = math.max(0, #rows - builder.ROWS_VISIBLE)
	if scrollOffset > maxScroll then
		scrollOffset = maxScroll
	elseif scrollOffset < 0 then
		scrollOffset = 0
	end
	if selectedIndex < 1 then
		selectedIndex = 1
	elseif selectedIndex > #rows then
		selectedIndex = #rows
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

local function applyHooks(defaultRows)
	local ctx = { target = targetActor, rows = defaultRows }
	local replacement = callHook('collectDestinations', ctx)
	local nextRows = type(replacement) == 'table' and replacement or defaultRows
	local filtered = {}
	local playerGold = data.serviceInfo(targetActor).playerGold
	for index, row in ipairs(nextRows) do
		local include = callHook('filterDestination', ctx, row)
		if include ~= false then
			row.sourceIndex = row.sourceIndex or row.index or index
			local price = callHook('priceDestination', ctx, row, row.price)
			if type(price) == 'number' then
				row.price = math.max(1, math.floor(price))
			end
			row.price = math.max(1, math.floor(tonumber(row.price) or 1))
			local label = callHook('formatDestination', ctx, row)
			if type(label) == 'string' then
				row.label = label
			end
			row.label = type(row.label) == 'string' and row.label or tostring(row.cellId or 'Destination')
			row.index = #filtered + 1
			local enabled = row.enabled ~= false and row.price <= playerGold
			local hookEnabled = callHook('enableDestination', ctx, row, enabled)
			row.enabled = type(hookEnabled) == 'boolean' and hookEnabled or enabled
			filtered[#filtered + 1] = row
		end
	end
	return filtered
end

local function followerList()
	local list = {}
	for _, follower in ipairs(followers) do
		if closeEnoughForTravel(follower) then
			list[#list + 1] = follower
		end
	end
	return list
end

local function followerCount()
	return #followerList()
end

local function rebuildRows()
	rows = applyHooks(data.collectRows(targetActor, followerCount()))
	ensureSelectedVisible()
end

local function requestFollowers()
	followerRequestId = followerRequestId + 1
	followers = {}
	followerKeys = {}
	local player = self.object or self
	core.sendGlobalEvent('S3UI_RequestTravelFollowers', { player = player, requestId = followerRequestId })
end

local function requestCellNames()
	local cellIds = {}
	for _, row in ipairs(rows) do
		local cellId = row.cellId or (row.destination and row.destination.cellId)
		if type(cellId) == 'string' and cellId ~= '' then
			cellIds[#cellIds + 1] = cellId
		end
	end
	if #cellIds > 0 then
		core.sendGlobalEvent('S3UI_ResolveTravelCellNames', { player = self.object or self, cellIds = cellIds })
	end
end

local function closeMode()
	if MODE then
		I.UI.removeMode(MODE)
	end
end

local function selectedRow()
	return rows[selectedIndex]
end

local function sendTravel(row)
	if not (row and row.enabled and validObject(targetActor)) then
		return
	end
	local veto = callHook('beforeTravel', { target = targetActor, rows = rows }, row)
	if veto == false then
		return
	end
	local payload = {
		player = self.object or self,
		target = targetActor,
		cellId = row.cellId or (row.destination and row.destination.cellId),
		position = row.position or (row.destination and row.destination.position),
		rotation = row.rotation or (row.destination and row.destination.rotation),
		price = row.price,
		followers = followerList(),
		sourceExterior = targetActor.cell and targetActor.cell.isExterior or false,
		hours = type(row.hours) == 'number' and row.hours or data.travelHours(row.destination),
	}
	local handled = callHook('executeTravel', { target = targetActor, rows = rows }, row, payload)
	if handled == false then
		return
	elseif handled ~= true then
		core.sendGlobalEvent('S3UI_TravelExecute', payload)
	end
	callHook('afterTravel', { target = targetActor, rows = rows }, row, payload)
	async:newUnsavableSimulationTimer(0, closeMode)
end

local function selectIndex(index)
	if index < 1 or index > #rows then
		return
	end
	if index == selectedIndex then
		return
	end
	selectedIndex = index
	ensureSelectedVisible()
	M.rebuildElement()
end

local function updateHovered(name)
	if hovered == name then
		return
	end
	hovered = name
	M.rebuildElement()
end

local function layoutCtx()
	local info = data.serviceInfo(targetActor)
	local callbackGeneration = generation
	return {
		async = async,
		cancel = function()
			if isAlive(callbackGeneration) then
				closeMode()
			end
		end,
		confirm = function()
			if isAlive(callbackGeneration) then
				sendTravel(selectedRow())
			end
		end,
		activate = function(index)
			if isAlive(callbackGeneration) then
				selectIndex(index)
				sendTravel(selectedRow())
			end
		end,
		select = function(index)
			if isAlive(callbackGeneration) then
				selectIndex(index)
			end
		end,
		setHovered = function(name)
			if isAlive(callbackGeneration) then
				updateHovered(name)
			end
		end,
		clearHovered = function(name)
			if isAlive(callbackGeneration) and hovered == name then
				updateHovered(nil)
			end
		end,
		hovered = hovered,
		playerGold = info.playerGold,
		rows = rows,
		scrollOffset = scrollOffset,
		selectedIndex = selectedIndex,
		serviceName = info.name,
		target = targetActor,
	}
end

function M.rebuildElement()
	if not (rootElement and rootElement.layout) then
		return
	end
	local ctx = layoutCtx()
	rootElement.layout = (renderer or builder.make)(ctx)
	rootElement:update()
end

function M.refresh()
	if not (rootElement and rootElement.layout) then
		return
	end
	rebuildRows()
	M.rebuildElement()
end

local function destroyRoot()
	generation = generation + 1
	hovered = nil
	if rootElement and rootElement.layout then
		rootElement:destroy()
	end
	rootElement = nil
end

---@param target openmw.Object
function M.show(target)
	destroyRoot()
	targetActor = target
	selectedIndex = 1
	scrollOffset = 0
	requestFollowers()
	rebuildRows()
	requestCellNames()
	rootElement = ui.create((renderer or builder.make)(layoutCtx()))
end

---@param data table
function M.addFollower(data)
	if type(data) ~= 'table' or data.requestId ~= followerRequestId then
		return
	end
	local follower = data.actor
	local key = objectKey(follower)
	if key and not followerKeys[key] then
		followerKeys[key] = true
		followers[#followers + 1] = follower
		if active() then
			rebuildRows()
			M.rebuildElement()
		end
	end
end

---@param names table<string, string>
function M.setCellDisplayNames(names)
	if data.setCellDisplayNames(names) and active() then
		rebuildRows()
		M.rebuildElement()
	end
end

function M.hide()
	destroyRoot()
	targetActor = nil
	rows = {}
	followers = {}
	followerKeys = {}
	selectedIndex = 1
	scrollOffset = 0
end

---@param delta integer
function M.navigate(delta)
	if not active() or #rows == 0 then
		return
	end
	selectIndex(math.max(1, math.min(#rows, selectedIndex + delta)))
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

function M.activateSelection()
	if active() then
		sendTravel(selectedRow())
	end
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
		M.activateSelection()
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

---@return table|nil
function M.getElement()
	return rootElement
end

---@return openmw.Object|nil
function M.getTarget()
	return targetActor
end

---@return S3UI.TravelRow[]
function M.getDestinations()
	return rows
end

---@return openmw.Object[]
function M.getFollowers()
	return followerList()
end

---@param name string
---@param fn function|nil
function M.setHook(name, fn)
	hooks[name] = fn
end

---@param fn function|nil
function M.setRenderer(fn)
	renderer = fn
end

function M.resetOverrides()
	hooks = {}
	renderer = nil
end

---@return S3UI.TravelInterface
function M.interface()
	return {
		getElement = M.getElement,
		getTarget = M.getTarget,
		getDestinations = M.getDestinations,
		getFollowers = M.getFollowers,
		show = M.show,
		hide = M.hide,
		rebuild = M.refresh,
		updateElement = M.rebuildElement,
		activateSelection = M.activateSelection,
		setCellDisplayNames = M.setCellDisplayNames,
		setHook = M.setHook,
		setRenderer = M.setRenderer,
		resetOverrides = M.resetOverrides,
		defaultRenderer = builder.make,
		getBarterOffer = data.getBarterOffer,
	}
end

M.active = active

return M
