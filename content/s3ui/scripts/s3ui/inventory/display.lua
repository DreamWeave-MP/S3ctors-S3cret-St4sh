---@omw-context player

---@alias S3UI.InventoryViewMode 'grid'|'list'
---@alias S3UI.InventorySortMode 'value'|'weight'|'effectiveness'|'condition'

local M = {}

---@param data S3UI.InventoryItemData
---@param sortMode S3UI.InventorySortMode
---@return number
local function itemSortValue(data, sortMode)
    if sortMode == 'value' then return data.value or 0 end
    if sortMode == 'weight' then return data.weight or 0 end
    if sortMode == 'effectiveness' then return data.effectiveness or 0 end
    if sortMode == 'condition' then return data.condition or 0 end
    return 0
end

---@param items S3UI.InventoryItemData[] Mutated in place.
---@param sortMode S3UI.InventorySortMode
---@param sortAscending table<string, boolean>
local function sortItems(items, sortMode, sortAscending)
    table.sort(items, function(left, right)
        local leftValue = itemSortValue(left, sortMode)
        local rightValue = itemSortValue(right, sortMode)
        if leftValue ~= rightValue then
            if sortAscending[sortMode] then return leftValue < rightValue end
            return leftValue > rightValue
        end
        local leftName = left.name:lower()
        local rightName = right.name:lower()
        if leftName ~= rightName then return leftName < rightName end
        return (left.item and left.item.recordId or '') < (right.item and right.item.recordId or '')
    end)
end

---@param items S3UI.InventoryItemData[]
---@param categoryOrder S3UI.InventoryCategory[]
---@param sortMode S3UI.InventorySortMode
---@param sortAscending table<string, boolean>
---@return table<string, S3UI.InventoryItemData[]>
local function itemsByCategory(items, categoryOrder, sortMode, sortAscending)
    local grouped = {}
    for _, category in ipairs(categoryOrder) do
        grouped[category.key] = {}
    end

    for _, item in ipairs(items) do
        grouped[item.categoryKey][#grouped[item.categoryKey] + 1] = item
    end

    for key in pairs(grouped) do
        sortItems(grouped[key], sortMode, sortAscending)
    end

    return grouped
end

---@param category S3UI.InventoryCategory
---@param count integer
---@param collapsed boolean
---@return S3UI.InventoryCategoryEntry
local function categoryEntry(category, count, collapsed)
    return {
        kind = 'categoryHeader',
        categoryKey = category.key,
        label = category.label,
        count = count,
        collapsed = collapsed,
    }
end

---@param item S3UI.InventoryItemData
---@return S3UI.InventoryItemEntry
local function itemEntry(item)
    return {
        kind = 'item',
        data = item,
    }
end

---@param items S3UI.InventoryItemData[]
---@param categoryOrder S3UI.InventoryCategory[]
---@param collapsedCategories table<string, boolean>
---@param sortMode S3UI.InventorySortMode
---@param sortAscending table<string, boolean>
---@return S3UI.InventoryDisplayEntry[]
function M.buildDisplayEntries(items, categoryOrder, collapsedCategories, sortMode, sortAscending)
    local grouped = itemsByCategory(items, categoryOrder, sortMode, sortAscending)
    local entries = {}

    for _, category in ipairs(categoryOrder) do
        if category.key ~= 'all' then
            local categoryItems = grouped[category.key]
            if #categoryItems > 0 then
                entries[#entries + 1] = categoryEntry(category, #categoryItems, collapsedCategories[category.key] == true)
                if not collapsedCategories[category.key] then
                    for _, item in ipairs(categoryItems) do
                        entries[#entries + 1] = itemEntry(item)
                    end
                end
            end
        end
    end

    return entries
end

---@param viewMode S3UI.InventoryViewMode
---@param metrics S3UI.InventoryMetrics
---@return integer
function M.visibleSlotCount(viewMode, metrics)
    if viewMode == 'list' then return metrics.listRows end
    return metrics.gridRows * metrics.gridColumns
end

---@param entryCount integer
---@param viewMode S3UI.InventoryViewMode
---@param metrics S3UI.InventoryMetrics
---@return integer
function M.maxScrollOffset(entryCount, viewMode, metrics)
    if viewMode == 'list' then
        local extraRows = entryCount - metrics.listRows
        if extraRows <= 0 then return 0 end
        return extraRows
    end

    local extraRows = math.ceil(entryCount / metrics.gridColumns) - metrics.gridRows
    if extraRows <= 0 then return 0 end
    return extraRows * metrics.gridColumns
end

---@param viewMode S3UI.InventoryViewMode
---@param metrics S3UI.InventoryMetrics
---@return integer
function M.scrollStepSize(viewMode, metrics)
    if viewMode == 'list' then return 1 end
    return metrics.gridColumns
end

---@param targetIndex integer
---@param direction integer
---@param scrollOffset integer
---@param viewMode S3UI.InventoryViewMode
---@param metrics S3UI.InventoryMetrics
---@return integer
function M.scrollOffsetForSelection(targetIndex, direction, scrollOffset, viewMode, metrics)
    local capacity = M.visibleSlotCount(viewMode, metrics)
    if targetIndex > scrollOffset and targetIndex <= scrollOffset + capacity then return scrollOffset end

    if viewMode == 'list' then
        if direction > 0 then return targetIndex - capacity end
        return targetIndex - 1
    end

    local rowStart = math.floor((targetIndex - 1) / metrics.gridColumns) * metrics.gridColumns
    if direction > 0 then return rowStart - (metrics.gridRows - 1) * metrics.gridColumns end
    return rowStart
end

return M
