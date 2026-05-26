---@omw-context player

local self = require("openmw.self")
local types = require("openmw.types")
local data = require("scripts.s3ui.inventory.data")

local Actor = types.Actor
local SLOT = Actor.EQUIPMENT_SLOT

local M = {}

M.GROUPS = {
	{
		key = "equipped",
		title = "Equipped",
		layout = {
			helmet = { x = 0.5, y = 0.08 },
			amulet = { x = 0.62, y = 0.1, scale = 0.9 },
			leftPauldron = { x = 0.32, y = 0.24 },
			rightPauldron = { x = 0.68, y = 0.24 },
			shirt = { x = 0.44, y = 0.24 },
			cuirass = { x = 0.56, y = 0.24 },
			leftGauntlet = { x = 0.25, y = 0.38 },
			rightGauntlet = { x = 0.75, y = 0.38 },
			leftRing = { x = 0.37, y = 0.4, scale = 0.75 },
			rightRing = { x = 0.63, y = 0.4, scale = 0.75 },
			carriedLeft = { x = 0.25, y = 0.52 },
			carriedRight = { x = 0.75, y = 0.52 },
			ammunition = { x = 0.75, y = 0.68, scale = 0.75 },
			robe = { x = 0.5, y = 0.38 },
			belt = { x = 0.5, y = 0.52 },
			skirt = { x = 0.37, y = 0.66 },
			pants = { x = 0.5, y = 0.66 },
			greaves = { x = 0.63, y = 0.66 },
			boots = { x = 0.5, y = 0.82 },
		},
		navOrder = {
			"helmet",
			"amulet",
			"leftPauldron",
			"shirt",
			"cuirass",
			"rightPauldron",
			"leftGauntlet",
			"leftRing",
			"rightRing",
			"rightGauntlet",
			"carriedLeft",
			"belt",
			"robe",
			"carriedRight",
			"ammunition",
			"skirt",
			"pants",
			"greaves",
			"boots",
		},
		slots = {
			{ key = "helmet", label = "Head", slot = SLOT.Helmet, inventoryCategoryKey = "armor" },
			{ key = "amulet", label = "Amulet", slot = SLOT.Amulet, inventoryCategoryKey = "apparel" },
			{ key = "leftPauldron", label = "L. Pauldron", slot = SLOT.LeftPauldron, inventoryCategoryKey = "armor" },
			{ key = "shirt", label = "Shirt", slot = SLOT.Shirt, inventoryCategoryKey = "apparel" },
			{ key = "cuirass", label = "Cuirass", slot = SLOT.Cuirass, inventoryCategoryKey = "armor" },
			{ key = "rightPauldron", label = "R. Pauldron", slot = SLOT.RightPauldron, inventoryCategoryKey = "armor" },
			{ key = "leftGauntlet", label = "L. Gauntlet", slot = SLOT.LeftGauntlet, inventoryCategoryKey = "armor" },
			{ key = "pants", label = "Pants", slot = SLOT.Pants, inventoryCategoryKey = "apparel" },
			{ key = "greaves", label = "Greaves", slot = SLOT.Greaves, inventoryCategoryKey = "armor" },
			{ key = "rightGauntlet", label = "R. Gauntlet", slot = SLOT.RightGauntlet, inventoryCategoryKey = "armor" },
			{ key = "carriedLeft", label = "Off Hand", slot = SLOT.CarriedLeft, inventoryCategoryKey = "weapons" },
			{ key = "skirt", label = "Skirt", slot = SLOT.Skirt, inventoryCategoryKey = "apparel" },
			{ key = "robe", label = "Robe", slot = SLOT.Robe, inventoryCategoryKey = "apparel" },
			{ key = "carriedRight", label = "Main Hand", slot = SLOT.CarriedRight, inventoryCategoryKey = "weapons" },
			{ key = "leftRing", label = "L. Ring", slot = SLOT.LeftRing, inventoryCategoryKey = "apparel" },
			{ key = "belt", label = "Belt", slot = SLOT.Belt, inventoryCategoryKey = "apparel" },
			{ key = "boots", label = "Boots", slot = SLOT.Boots, inventoryCategoryKey = "armor" },
			{ key = "rightRing", label = "R. Ring", slot = SLOT.RightRing, inventoryCategoryKey = "apparel" },
			{ key = "ammunition", label = "Ammunition", slot = SLOT.Ammunition, inventoryCategoryKey = "weapons" },
		},
	},
}

local function currentActor()
	return self.object or self
end

local function safeRecord(item)
	if not item or not item.type or not item.recordId then
		return nil
	end
	local records = item.type.records
	return records and records[item.recordId] or nil
end

local function safeItemData(item)
	local ok, itemData = pcall(function()
		return types.Item.itemData(item)
	end)
	return ok and itemData or nil
end

local function itemCount(inventory, item)
	if not item or not item.recordId then
		return 1
	end
	local ok, count = pcall(function()
		return inventory:countOf(item.recordId)
	end)
	return ok and count and count > 0 and count or 1
end

local function itemCondition(itemData)
	return itemData and type(itemData.condition) == "number" and itemData.condition or nil
end

local function summaryText(itemData)
	if not itemData then
		return ""
	end
	local record, item = itemData.record, itemData.item
	local summary = ""
	if item and item.type == types.Weapon then
		summary = "DMG " .. data.bestWeaponDamage(record)
	elseif item and item.type == types.Armor then
		summary = "AR " .. data.formatNumber(record and record.baseArmor, 0)
	end
	local condition = data.formatCondition(itemData.condition)
	if condition ~= data.EMPTY_FIELD then
		return summary ~= "" and (summary .. "   Cnd " .. condition) or ("Cnd " .. condition)
	end
	return summary
end

local function makeItemData(inventory, item)
	if not item then
		return nil
	end
	local record = safeRecord(item)
	local itemData = safeItemData(item)
	local condition = itemCondition(itemData)
	return {
		item = item,
		record = record,
		name = data.itemName(item, record),
		icon = record and record.icon,
		count = itemCount(inventory, item),
		categoryKey = "equipment",
		categoryLabel = "Equipment",
		value = record and type(record.value) == "number" and record.value or 0,
		weight = record and type(record.weight) == "number" and record.weight or 0,
		effectiveness = data.itemEffectiveness(item.type, record),
		condition = condition,
		equipped = true,
		enchanted = record and record.enchant ~= nil and record.enchant ~= "" or false,
		broken = type(condition) == "number" and condition <= 0,
	}
end

function M.collectGroups()
	local actor = currentActor()
	local inventory = Actor.inventory(actor)
	local ok, equipment = pcall(function()
		return Actor.getEquipment(actor)
	end)
	if not ok or type(equipment) ~= "table" then
		equipment = {}
	end

	local groups = {}
	for _, groupDef in ipairs(M.GROUPS) do
		local group = {
			key = groupDef.key,
			title = groupDef.title,
			layout = groupDef.layout,
			navOrder = groupDef.navOrder,
			slots = {},
		}
		for _, slotDef in ipairs(groupDef.slots) do
			local itemData = makeItemData(inventory, equipment[slotDef.slot])
			group.slots[#group.slots + 1] = {
				key = slotDef.key,
				label = slotDef.label,
				slot = slotDef.slot,
				inventoryCategoryKey = slotDef.inventoryCategoryKey or groupDef.inventoryCategoryKey,
				itemData = itemData,
				summary = summaryText(itemData),
			}
		end
		groups[#groups + 1] = group
	end
	return groups
end

local function slotsByKey(group)
	local byKey = {}
	for _, slot in ipairs(group.slots or {}) do
		byKey[slot.key] = slot
	end
	return byKey
end

function M.orderedSlots(groups)
	local ordered = {}
	for _, group in ipairs(groups or {}) do
		local byKey = slotsByKey(group)
		for _, key in ipairs(group.navOrder or {}) do
			local slot = byKey[key]
			if slot then
				ordered[#ordered + 1] = slot
			end
		end
		if not group.navOrder then
			for _, slot in ipairs(group.slots or {}) do
				ordered[#ordered + 1] = slot
			end
		end
	end
	return ordered
end

function M.findPlacement(groups, key)
	if not key then
		return nil
	end
	for _, group in ipairs(groups or {}) do
		local placement = group.layout and group.layout[key]
		if placement then
			return placement
		end
	end
	return nil
end

function M.spatialNeighbor(groups, currentKey, direction)
	local current = M.findPlacement(groups, currentKey)
	if not current then
		local ordered = M.orderedSlots(groups)
		return ordered[1]
	end

	local bestSlot, bestScore
	for _, group in ipairs(groups or {}) do
		for _, slot in ipairs(group.slots or {}) do
			local placement = group.layout and group.layout[slot.key]
			if placement and slot.key ~= currentKey then
				local dy = placement.y - current.y
				local valid = direction > 0 and dy > 0 or direction < 0 and dy < 0
				if valid then
					local dx = math.abs(placement.x - current.x)
					local score = math.abs(dy) * 100 + dx * 100
					if not bestScore or score < bestScore then
						bestScore = score
						bestSlot = slot
					end
				end
			end
		end
	end

	if bestSlot then
		return bestSlot
	end

	local ordered = M.orderedSlots(groups)
	return direction > 0 and ordered[1] or ordered[#ordered]
end

function M.findSlot(groups, key)
	if not key then
		return nil
	end
	for _, group in ipairs(groups or {}) do
		for _, slot in ipairs(group.slots or {}) do
			if slot.key == key then
				return slot
			end
		end
	end
	return nil
end

return M
