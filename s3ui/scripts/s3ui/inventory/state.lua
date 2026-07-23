---@omw-context player

local display = require 'scripts.s3ui.inventory.display'

---@class S3UI.InventoryStateModule
local M = {}

---@class S3UI.InventoryState

---@return S3UI.InventoryState
function M.new()
	local state = {
		collapsedCategories = {},
		sortMode = 'value',
		sortAscending = {
			value = false,
			weight = false,
			effectiveness = false,
			condition = false,
		},
		viewMode = 'grid',
		primaryTab = 'inventory',
		generation = 0,
		scrollOffset = 0,
		lastEntryCount = 0,
		selectedSlotIndex = nil,
		selectedSlotViewMode = nil,
		selectedDisplayData = nil,
		selectedEquipmentSlotKey = nil,
		selectedEquipmentSlotLabel = nil,
		selectedEquipmentData = nil,
	}

	function state:bumpGeneration()
		self.generation = self.generation + 1
		return self.generation
	end

	function state:resetScroll()
		self.scrollOffset = 0
	end

	---@param entryCount integer
	---@param metrics S3UI.InventoryMetrics
	function state:clampScroll(entryCount, metrics)
		local maxOffset = display.maxScrollOffset(entryCount, self.viewMode, metrics)
		local step = display.scrollStepSize(self.viewMode, metrics)
		if self.scrollOffset < 0 then
			self.scrollOffset = 0
		end
		if self.scrollOffset > maxOffset then
			self.scrollOffset = maxOffset
		end
		self.scrollOffset = math.floor(self.scrollOffset / step) * step
		return maxOffset
	end

	---@param deltaRows integer
	---@param metrics S3UI.InventoryMetrics
	---@param entryCount integer
	function state:scrollRows(deltaRows, metrics, entryCount)
		local oldOffset = self.scrollOffset
		self.scrollOffset = self.scrollOffset + deltaRows * display.scrollStepSize(self.viewMode, metrics)
		self:clampScroll(entryCount, metrics)
		return self.scrollOffset ~= oldOffset
	end

	function state:endScroll(metrics)
		local oldOffset = self.scrollOffset
		self.scrollOffset = display.maxScrollOffset(self.lastEntryCount, self.viewMode, metrics)
		return self.scrollOffset ~= oldOffset
	end

	function state:home()
		if self.scrollOffset == 0 then
			return false
		end
		self.scrollOffset = 0
		return true
	end

	function state:activateSort(mode)
		if self.sortMode == mode then
			self.sortAscending[mode] = not self.sortAscending[mode]
		end
		self.sortMode = mode
	end

	function state:toggleViewMode()
		if self.primaryTab ~= 'inventory' then
			return
		end
		self.viewMode = self.viewMode == 'grid' and 'list' or 'grid'
		self:resetScroll()
	end

	function state:setPrimaryTab(tab)
		if self.primaryTab == tab then
			return false
		end
		self.primaryTab = tab
		self:resetScroll()
		self:resetTransientSelection()
		return true
	end

	function state:toggleCategory(categoryKey)
		self.collapsedCategories[categoryKey] = not self.collapsedCategories[categoryKey]
	end

	function state:selectVisibleSlot(slotIndex, data)
		self.selectedSlotIndex = slotIndex
		self.selectedSlotViewMode = self.viewMode
		self.selectedDisplayData = data
	end

	function state:clearSelection()
		self.selectedSlotIndex = nil
		self.selectedSlotViewMode = nil
		self.selectedDisplayData = nil
		self.selectedEquipmentSlotKey = nil
		self.selectedEquipmentSlotLabel = nil
		self.selectedEquipmentData = nil
	end

	function state:selectEquipmentSlot(slot)
		self.selectedSlotIndex = nil
		self.selectedSlotViewMode = nil
		self.selectedDisplayData = nil
		self.selectedEquipmentSlotKey = slot and slot.key or nil
		self.selectedEquipmentSlotLabel = slot and slot.label or nil
		self.selectedEquipmentData = slot and slot.itemData or nil
	end

	function state:selectedEntryData(entries, firstIndex)
		if self.selectedSlotIndex == nil or self.selectedSlotViewMode ~= self.viewMode then
			return nil
		end
		local entry = entries[firstIndex + self.selectedSlotIndex - 1]
		if entry and entry.kind == 'item' then
			return entry.data
		end
		return nil
	end

	function state:resetTransientSelection()
		self.selectedSlotIndex = nil
		self.selectedSlotViewMode = nil
		self.selectedDisplayData = nil
		self.selectedEquipmentSlotKey = nil
		self.selectedEquipmentSlotLabel = nil
		self.selectedEquipmentData = nil
	end

	function state:buildEntries(items, categoryOrder)
		return display.buildDisplayEntries(
			items,
			categoryOrder,
			self.collapsedCategories,
			self.sortMode,
			self.sortAscending
		)
	end

	function state:visibleSlotCount(metrics)
		return display.visibleSlotCount(self.viewMode, metrics)
	end

	function state:scrollOffsetForSelection(targetIndex, direction, metrics)
		return display.scrollOffsetForSelection(targetIndex, direction, self.scrollOffset, self.viewMode, metrics)
	end

	return state
end

return M
