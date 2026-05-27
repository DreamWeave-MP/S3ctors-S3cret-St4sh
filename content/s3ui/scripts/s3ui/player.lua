---@omw-context player

local async = require 'openmw.async'
local omwDebug = require 'openmw.debug'
local input = require 'openmw.input'
local I = require 'openmw.interfaces'
local storage = require 'openmw.storage'

local countModal = require 'scripts.s3ui.components.count_modal'
local inventoryWindow = require 'scripts.s3ui.inventory.window'
local inventoryCamera = require 'scripts.s3ui.player_camera'
local travelWindow = require 'scripts.s3ui.travel.window'

local UI_WINDOWS = I.UI.WINDOW
local WINDOW = UI_WINDOWS.Inventory
local TRAVEL_WINDOW = UI_WINDOWS.Travel
local MODE = I.UI.MODE.Interface
local DEV_RELOAD_SECTION = 'S3UI_DevReload'
local DEV_RELOAD_REOPEN_KEY = 'reopenInventory'
local EMPTY_WINDOW_OVERRIDES = {
	UI_WINDOWS.Map,
	UI_WINDOWS.Stats,
	UI_WINDOWS.Magic,
	UI_WINDOWS.Journal,
}

local devReloadStorage = storage.playerSection(DEV_RELOAD_SECTION)
devReloadStorage:setLifeTime(storage.LIFE_TIME.GameSession)

local registeredWindow = false

local function reloadLuaAndReopenInventory()
	devReloadStorage:set(DEV_RELOAD_REOPEN_KEY, true)
	if I.UI.isWindowVisible(WINDOW) then
		I.UI.removeMode(MODE)
	end
	inventoryCamera.restoreCamera(true)
	omwDebug.reloadLua()
end

local function processDevReloadReopen()
	if devReloadStorage:get(DEV_RELOAD_REOPEN_KEY) ~= true then
		return
	end
	devReloadStorage:set(DEV_RELOAD_REOPEN_KEY, false)
	if not I.UI.isWindowVisible(WINDOW) then
		I.UI.setMode(MODE, { windows = { WINDOW } })
	end
end

local function emptyWindowOverride() end

local function closeJournalMode()
	if I.UI.getMode() == I.UI.MODE.Journal then
		I.UI.removeMode(I.UI.MODE.Journal)
	end
end

local function registerInventoryWindow()
	if registeredWindow then
		return
	end
	I.UI.registerWindow(WINDOW, inventoryWindow.show, inventoryWindow.hide)
	I.UI.registerWindow(TRAVEL_WINDOW, travelWindow.show, travelWindow.hide)
	for _, windowName in ipairs(EMPTY_WINDOW_OVERRIDES) do
		I.UI.registerWindow(windowName, emptyWindowOverride, emptyWindowOverride)
	end
	registeredWindow = true
end

registerInventoryWindow()
-- Vanilla's Journal trigger pushes MODE.Journal. Until S3UI has a journal tab,
-- collapse that mode after vanilla trigger handlers run so the action is a no-op.
input.registerTriggerHandler(
	'Journal',
	async:callback(function()
		async:newUnsavableSimulationTimer(0, closeJournalMode)
	end)
)
async:newUnsavableSimulationTimer(0, processDevReloadReopen)

return {
	engineHandlers = {
		onUpdate = inventoryCamera.update,
		onKeyPress = function(key)
			if key.code == input.KEY.F8 then
				reloadLuaAndReopenInventory()
			elseif countModal.handleKeyPress(key) then
				return
			elseif travelWindow.handleKeyPress(key) then
				return
			elseif key.code == input.KEY.Enter or key.code == input.KEY.NP_Enter or key.code == input.KEY.Space then
				inventoryWindow.activateSelection()
			elseif key.code == input.KEY.LeftArrow then
				inventoryWindow.navigateSelection(-1)
			elseif key.code == input.KEY.RightArrow then
				inventoryWindow.navigateSelection(1)
			elseif key.code == input.KEY.PageUp or key.code == input.KEY.UpArrow then
				inventoryWindow.scrollRows(-1)
			elseif key.code == input.KEY.PageDown or key.code == input.KEY.DownArrow then
				inventoryWindow.scrollRows(1)
			elseif key.code == input.KEY.Home then
				inventoryWindow.home()
			elseif key.code == input.KEY.End then
				inventoryWindow.endScroll()
			end
		end,
		onMouseWheel = function(vertical, _horizontal)
			if countModal.isOpen() then
				return
			end
			if type(vertical) ~= 'number' then
				return
			end
			if travelWindow.active() then
				if vertical > 0 then
					travelWindow.scroll(-1)
				elseif vertical < 0 then
					travelWindow.scroll(1)
				end
				return
			end
			if vertical > 0 then
				inventoryWindow.scrollRows(-1)
			elseif vertical < 0 then
				inventoryWindow.scrollRows(1)
			end
		end,
	},
	eventHandlers = {
		S3UI_RebuildInventory = inventoryWindow.processPendingRebuild,
		S3UI_TravelFollowerFound = travelWindow.addFollower,
		S3UI_TravelCellNamesResolved = travelWindow.setCellDisplayNames,
	},
	interfaceName = 'S3UI',
	interface = {
		version = 1,
		Travel = travelWindow.interface(),
		travel = travelWindow.interface(),
	},
}
