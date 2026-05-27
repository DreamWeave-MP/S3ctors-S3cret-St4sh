---@omw-context player

local self = require 'openmw.self'
local types = require 'openmw.types'
local s3math = require 'scripts.s3.math'

---@class S3UI.RepairItem
---@field item openmw.Object
---@field record table
---@field name string
---@field condition number
---@field maxCondition number
---@field conditionPercent number
---@field damage number
---@field kind 'weapon'|'armor'

---@class S3UI.RepairTool
---@field item openmw.Object
---@field record table|nil
---@field name string
---@field uses number
---@field maxUses number
---@field quality number

---@class S3UI.RepairDataModule
local M = {}

local function currentActor()
	return self.object or self
end

local function safeRecord(item)
	if not item or not item.type or not item.recordId then
		return nil
	end
	local records = item.type.records
	if not records then
		return nil
	end
	return records[item.recordId]
end

local function safeItemData(item)
	local ok, itemData = pcall(function()
		return types.Item.itemData(item)
	end)
	if ok then
		return itemData
	end
	return nil
end

local function itemName(item, record)
	return (record and record.name) or (item and item.recordId) or 'Unknown item'
end

local function itemKind(item)
	if item.type == types.Weapon then
		return 'weapon'
	elseif item.type == types.Armor then
		return 'armor'
	end
	return nil
end

local function maxCondition(record)
	if record and type(record.health) == 'number' and record.health > 0 then
		return record.health
	end
	return nil
end

---@return number
function M.armorerSkill()
	local ok, stat = pcall(function()
		local actor = currentActor()
		return actor.type.stats.skills.armorer(actor)
	end)
	if ok and stat and type(stat.modified) == 'number' then
		return stat.modified
	end
	return 35
end

---@param tool openmw.Object|nil
---@return S3UI.RepairTool|nil
function M.toolInfo(tool)
	if not tool then
		return nil
	end
	local record = safeRecord(tool)
	local itemData = safeItemData(tool)
	local maxUses = (record and type(record.maxCondition) == 'number' and record.maxCondition > 0)
			and record.maxCondition
		or 1
	local uses = itemData and type(itemData.condition) == 'number' and itemData.condition or maxUses
	return {
		item = tool,
		record = record,
		name = itemName(tool, record),
		uses = uses,
		maxUses = maxUses,
		quality = record and type(record.quality) == 'number' and record.quality or 1,
	}
end

---@return S3UI.RepairItem[]
function M.collectRepairableItems()
	local inventory = types.Actor.inventory(currentActor())
	local rows = {}

	for _, item in ipairs(inventory:getAll()) do
		local kind = itemKind(item)
		if kind and item.recordId then
			local record = safeRecord(item)
			local max = maxCondition(record)
			local itemData = safeItemData(item)
			local condition = itemData and type(itemData.condition) == 'number' and itemData.condition or max
			if max and condition and condition < max then
				rows[#rows + 1] = {
					item = item,
					record = record,
					name = itemName(item, record),
					condition = condition,
					maxCondition = max,
					conditionPercent = s3math.clamp(condition / max, 0, 1),
					damage = max - condition,
					kind = kind,
				}
			end
		end
	end

	table.sort(rows, function(left, right)
		if left.kind ~= right.kind then
			return left.kind < right.kind
		end
		return left.name:lower() < right.name:lower()
	end)

	return rows
end

---@param repairItem S3UI.RepairItem
---@param amount number
---@return number applied
function M.applyConditionGain(repairItem, amount)
	local itemData = safeItemData(repairItem.item)
	if not itemData then
		return 0
	end
	local before = type(itemData.condition) == 'number' and itemData.condition or repairItem.condition
	local after = s3math.min(repairItem.maxCondition, before + s3math.max(0, amount))
	repairItem.condition = after
	repairItem.conditionPercent = s3math.clamp(after / repairItem.maxCondition, 0, 1)
	repairItem.damage = repairItem.maxCondition - after
	return after - before
end

---@param toolInfo S3UI.RepairTool|nil
---@param amount number
---@return number consumed
function M.consumeToolUses(toolInfo, amount)
	if not toolInfo then
		return 0
	end
	local itemData = safeItemData(toolInfo.item)
	if not itemData then
		return 0
	end
	local before = type(itemData.condition) == 'number' and itemData.condition or toolInfo.uses
	local after = s3math.max(0, before - s3math.max(0, amount))
	toolInfo.uses = after
	return before - after
end

return M
