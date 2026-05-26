---@omw-context player

local self = require("openmw.self")
local types = require("openmw.types")
local data = require("scripts.s3ui.inventory.data")

local Actor = types.Actor
local SLOT = Actor.EQUIPMENT_SLOT

local M = {}

M.GROUPS = {
	{
		key = "weapons",
		title = "Weapons",
		inventoryCategoryKey = "weapons",
		slots = {
			{ key = "carriedRight", label = "Main Hand", slot = SLOT.CarriedRight },
			{ key = "carriedLeft", label = "Off Hand", slot = SLOT.CarriedLeft },
			{ key = "ammunition", label = "Ammunition", slot = SLOT.Ammunition },
		},
	},
	{
		key = "armor",
		title = "Armor",
		inventoryCategoryKey = "armor",
		slots = {
			{ key = "helmet", label = "Head", slot = SLOT.Helmet },
			{ key = "cuirass", label = "Cuirass", slot = SLOT.Cuirass },
			{ key = "greaves", label = "Greaves", slot = SLOT.Greaves },
			{ key = "leftPauldron", label = "L. Pauldron", slot = SLOT.LeftPauldron },
			{ key = "rightPauldron", label = "R. Pauldron", slot = SLOT.RightPauldron },
			{ key = "boots", label = "Boots", slot = SLOT.Boots },
			{ key = "leftGauntlet", label = "L. Gauntlet", slot = SLOT.LeftGauntlet },
			{ key = "rightGauntlet", label = "R. Gauntlet", slot = SLOT.RightGauntlet },
		},
	},
	{
		key = "clothing",
		title = "Clothing & Jewelry",
		inventoryCategoryKey = "apparel",
		slots = {
			{ key = "shirt", label = "Shirt", slot = SLOT.Shirt },
			{ key = "pants", label = "Pants", slot = SLOT.Pants },
			{ key = "robe", label = "Robe", slot = SLOT.Robe },
			{ key = "skirt", label = "Skirt", slot = SLOT.Skirt },
			{ key = "belt", label = "Belt", slot = SLOT.Belt },
			{ key = "amulet", label = "Amulet", slot = SLOT.Amulet },
			{ key = "leftRing", label = "L. Ring", slot = SLOT.LeftRing },
			{ key = "rightRing", label = "R. Ring", slot = SLOT.RightRing },
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
	elseif item and item.type == types.Clothing then
		summary = data.typeText(itemData)
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
		local group = { key = groupDef.key, title = groupDef.title, slots = {} }
		for _, slotDef in ipairs(groupDef.slots) do
			local itemData = makeItemData(inventory, equipment[slotDef.slot])
			group.slots[#group.slots + 1] = {
				key = slotDef.key,
				label = slotDef.label,
				slot = slotDef.slot,
				inventoryCategoryKey = groupDef.inventoryCategoryKey,
				itemData = itemData,
				summary = summaryText(itemData),
			}
		end
		groups[#groups + 1] = group
	end
	return groups
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
