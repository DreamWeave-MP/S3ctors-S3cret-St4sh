---@omw-context player

local types = require 'openmw.types'
local ui = require 'openmw.ui'
local chrome = require 'scripts.s3ui.inventory.chrome'
local data = require 'scripts.s3ui.inventory.data'
local icons = require 'scripts.s3ui.inventory.icons'

local EMPTY_FIELD = data.EMPTY_FIELD
local TOOLTIP = icons.TOOLTIP
local WHITE_TEXTURE = chrome.WHITE_TEXTURE

local RANGED_WEAPON_TYPES = {
	[types.Weapon.TYPE.Arrow] = true,
	[types.Weapon.TYPE.Bolt] = true,
	[types.Weapon.TYPE.MarksmanBow] = true,
	[types.Weapon.TYPE.MarksmanCrossbow] = true,
	[types.Weapon.TYPE.MarksmanThrown] = true,
}

---@class S3UI.InventoryDetailsModelModule
local M = {}

local function typeIcon(itemData)
	local itemType = itemData and itemData.item and itemData.item.type
	if itemType == types.Weapon then
		local weaponType = itemData and itemData.record and itemData.record.type
		if RANGED_WEAPON_TYPES[weaponType] then
			return TOOLTIP.typeRangedWeapon
		end
		return TOOLTIP.typeWeapon
	end
	if itemType == types.Armor or itemType == types.Clothing then
		return TOOLTIP.typeArmor
	end
	if itemType == types.Book then
		return TOOLTIP.typeBook
	end
	return TOOLTIP.typeGeneric
end

local function addField(fields, key, icon, value, compactValue)
	if value == nil or value == '' or value == EMPTY_FIELD then
		return
	end
	fields[#fields + 1] = { key = key, icon = icon, value = value, compactValue = compactValue or value }
end

---@param itemData S3UI.InventoryItemData|nil
---@return S3UI.InventoryDetailModel|nil
function M.build(itemData)
	if not itemData then
		return nil
	end
	local record = itemData.record
	local fields = {}
	addField(fields, 'type', typeIcon(itemData), data.typeText(itemData))
	addField(
		fields,
		'value',
		TOOLTIP.value,
		record and type(record.value) == 'number' and tostring(record.value) or EMPTY_FIELD
	)
	addField(fields, 'weight', TOOLTIP.weight, data.formatNumber(record and record.weight, 2))
	addField(fields, 'goldPerWeight', TOOLTIP.goldPerWeight, data.goldPerWeight(record))
	addField(fields, 'condition', TOOLTIP.condition, data.formatCondition(itemData.condition))
	if itemData.item and itemData.item.type == types.Weapon then
		addField(fields, 'reach', TOOLTIP.reach, data.formatNumber(record and record.reach, 2))
		addField(fields, 'speed', TOOLTIP.speed, data.formatNumber(record and record.speed, 2))
		for _, damage in ipairs(data.weaponDamageFields(record)) do
			addField(fields, damage.key, TOOLTIP.damage, damage.text, damage.compactText)
		end
		addField(fields, 'effectiveness', TOOLTIP.damageSpeed, data.formatNumber(itemData.effectiveness, 2))
	elseif itemData.item and itemData.item.type == types.Armor then
		addField(fields, 'reach', TOOLTIP.armorRating, data.formatNumber(record and record.baseArmor, 0))
	end
	return {
		icon = itemData.icon and ui.texture { path = itemData.icon } or WHITE_TEXTURE,
		name = itemData.name or data.itemName(itemData.item, record),
		fields = fields,
	}
end

return M
