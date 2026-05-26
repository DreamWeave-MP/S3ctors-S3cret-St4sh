---@omw-context player

local async = require 'openmw.async'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local ui = require 'openmw.ui'
local builder = require 'scripts.s3ui.inventory.builder'
local data = require 'scripts.s3ui.inventory.data'
local detailsFactory = require 'scripts.s3ui.inventory.details'
local inventoryCamera = require 'scripts.s3ui.player_camera'
local layout = require 'scripts.s3ui.inventory.layout'
local stateFactory = require 'scripts.s3ui.inventory.state'

local WINDOW = I.UI.WINDOW.Inventory
local ROOT_LAYER = 'Windows'

local M = {}

local rootElement = nil
local rebuildInventoryPending = false
local rebuildEventQueued = false
---@type S3UI.InventoryMetrics|nil
local activeLayoutMetrics = nil
local state = stateFactory.new()

local function layoutMetrics()
    return activeLayoutMetrics or layout.compute()
end

local details = detailsFactory.new {
    metrics = layoutMetrics,
    root = function() return rootElement end,
    rootLayer = ROOT_LAYER,
}

local function active()
    return rootElement and rootElement.layout and I.UI.isWindowVisible(WINDOW)
end

local function clearSelection()
    state:clearSelection()
    details.hide()
end

local function selectVisibleSlot(slotIndex, itemData)
    state:selectVisibleSlot(slotIndex, itemData)
    if itemData then details.update(itemData) else details.hide() end
end

local function queueRebuild()
    details.hide()
    rebuildInventoryPending = true
    if rebuildEventQueued then return end
    rebuildEventQueued = true
    self:sendEvent('S3UI_RebuildInventory')
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

local function makeInventoryLayout(items)
    activeLayoutMetrics = layout.compute()
    local metrics = activeLayoutMetrics
    local entries = state:buildEntries(items, data.CATEGORY_ORDER)
    state.lastEntryCount = #entries
    state:clampScroll(#entries, metrics)
    local firstIndex = state.scrollOffset + 1
    state.selectedDisplayData = state:selectedEntryData(entries, firstIndex)
    return builder.make {
        controlsCtx = controlsCtx(),
        details = details,
        entries = entries,
        firstIndex = firstIndex,
        metrics = metrics,
        rootLayer = ROOT_LAYER,
        state = state,
        viewCtx = viewCtx(),
    }
end

local function destroyRoot()
    state:bumpGeneration()
    rebuildInventoryPending = false
    rebuildEventQueued = false
    details.destroy()
    if rootElement and rootElement.layout then rootElement:destroy() end
    rootElement = nil
    state:resetTransientSelection()
end

local function rebuildRoot()
    state:bumpGeneration()
    details.hide()
    if rootElement and rootElement.layout then rootElement:destroy() end
    details.destroy()
    rootElement = ui.create(makeInventoryLayout(data.collectItems()))
    if activeLayoutMetrics.detailMode == 'side' then details.createSideTooltip() end
    if state.selectedSlotIndex ~= nil and state.selectedDisplayData then details.update(state.selectedDisplayData) end
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
    if not rebuildInventoryPending then return end
    rebuildInventoryPending = false
    if not active() then return end
    rebuildRoot()
end

function M.scrollRows(deltaRows)
    if not active() then return end
    if state:scrollRows(deltaRows, layoutMetrics(), state.lastEntryCount) then queueRebuild() end
end

function M.home()
    if active() and state:home() then queueRebuild() end
end

function M.endScroll()
    if active() and state:endScroll(layoutMetrics()) then queueRebuild() end
end

function M.navigateSelection(direction)
    if not active() then return end
    local entries = state:buildEntries(data.collectItems(), data.CATEGORY_ORDER)
    if #entries == 0 then clearSelection(); return end
    local metrics = layoutMetrics()
    local capacity = state:visibleSlotCount(metrics)
    local currentIndex = nil
    if state.selectedSlotIndex ~= nil and state.selectedSlotViewMode == state.viewMode then
        currentIndex = state.scrollOffset + state.selectedSlotIndex
    end
    local targetIndex
    if currentIndex then
        targetIndex = currentIndex + direction
        if targetIndex > #entries then targetIndex = 1 elseif targetIndex < 1 then targetIndex = #entries end
    elseif direction > 0 then
        targetIndex = math.min(state.scrollOffset + 1, #entries)
    else
        targetIndex = math.min(state.scrollOffset + capacity, #entries)
    end
    local oldOffset = state.scrollOffset
    state.scrollOffset = state:scrollOffsetForSelection(targetIndex, direction, metrics)
    state:clampScroll(#entries, metrics)
    local slotIndex = targetIndex - state.scrollOffset
    if slotIndex < 1 or slotIndex > capacity then return end
    local entry = entries[targetIndex]
    selectVisibleSlot(slotIndex, entry and entry.kind == 'item' and entry.data or nil)
    if state.scrollOffset ~= oldOffset then queueRebuild() end
end

M.active = active

return M
