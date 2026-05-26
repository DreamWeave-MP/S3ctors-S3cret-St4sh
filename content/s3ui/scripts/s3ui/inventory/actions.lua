---@omw-context player

local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local types = require("openmw.types")
local countModal = require("scripts.s3ui.components.count_modal")

local M = {}

local Actor = types.Actor
local SLOT = Actor.EQUIPMENT_SLOT

local ARMOR_SLOT_BY_TYPE = {
	[types.Armor.TYPE.Boots] = SLOT.Boots,
	[types.Armor.TYPE.Cuirass] = SLOT.Cuirass,
	[types.Armor.TYPE.Greaves] = SLOT.Greaves,
	[types.Armor.TYPE.Helmet] = SLOT.Helmet,
	[types.Armor.TYPE.LBracer] = SLOT.LeftGauntlet,
	[types.Armor.TYPE.LGauntlet] = SLOT.LeftGauntlet,
	[types.Armor.TYPE.LPauldron] = SLOT.LeftPauldron,
	[types.Armor.TYPE.RBracer] = SLOT.RightGauntlet,
	[types.Armor.TYPE.RGauntlet] = SLOT.RightGauntlet,
	[types.Armor.TYPE.RPauldron] = SLOT.RightPauldron,
	[types.Armor.TYPE.Shield] = SLOT.CarriedLeft,
}

local CLOTHING_SLOT_BY_TYPE = {
	[types.Clothing.TYPE.Amulet] = SLOT.Amulet,
	[types.Clothing.TYPE.Belt] = SLOT.Belt,
	[types.Clothing.TYPE.LGlove] = SLOT.LeftGauntlet,
	[types.Clothing.TYPE.Pants] = SLOT.Pants,
	[types.Clothing.TYPE.RGlove] = SLOT.RightGauntlet,
	[types.Clothing.TYPE.Robe] = SLOT.Robe,
	[types.Clothing.TYPE.Shirt] = SLOT.Shirt,
	[types.Clothing.TYPE.Shoes] = SLOT.Boots,
	[types.Clothing.TYPE.Skirt] = SLOT.Skirt,
}

local function playerObject()
	return self.object or self
end

local function playerSelf()
	return self
end

local function itemRecordId(itemData)
	return itemData and itemData.item and itemData.item.recordId
end

local function sameRecord(item, recordId)
	return item and item.recordId and item.recordId == recordId
end

local function ringSlot(equipment)
	if not equipment[SLOT.LeftRing] then
		return SLOT.LeftRing
	end
	return SLOT.RightRing
end

local function equipmentSlot(itemData, equipment)
	local item = itemData and itemData.item
	local record = itemData and itemData.record
	if not item or not record then
		return nil
	end
	if item.type == types.Weapon then
		if record.type == types.Weapon.TYPE.Arrow or record.type == types.Weapon.TYPE.Bolt then
			return SLOT.Ammunition
		end
		return SLOT.CarriedRight
	elseif item.type == types.Armor then
		return ARMOR_SLOT_BY_TYPE[record.type]
	elseif item.type == types.Clothing then
		if record.type == types.Clothing.TYPE.Ring then
			return ringSlot(equipment)
		end
		return CLOTHING_SLOT_BY_TYPE[record.type]
	elseif item.type == types.Light and record.isCarriable then
		return SLOT.CarriedLeft
	end
	return nil
end

local function queueRebuild(ctx)
	if ctx and ctx.queueRebuild then
		ctx.queueRebuild()
	end
end

local function unequip(itemData, ctx)
	local recordId = itemRecordId(itemData)
	if not recordId then
		return false
	end
	local actor = playerSelf()
	local equipment = Actor.getEquipment(actor)
	local changed = false
	for slot, equipped in pairs(equipment) do
		if sameRecord(equipped, recordId) then
			equipment[slot] = nil
			changed = true
		end
	end
	if not changed then
		return false
	end
	Actor.setEquipment(actor, equipment)
	queueRebuild(ctx)
	return true
end

local function equip(itemData, ctx)
	local actor = playerSelf()
	local equipment = Actor.getEquipment(actor)
	local slot = equipmentSlot(itemData, equipment)
	if not slot then
		return false
	end
	equipment[slot] = itemData.item
	Actor.setEquipment(actor, equipment)
	queueRebuild(ctx)
	return true
end

local function dropEventData(itemData, count)
	local actor = playerObject()
	return {
		player = actor,
		item = itemData.item,
		count = count,
		cellName = actor.cell and actor.cell.name or "",
		position = actor.position,
		onGround = true,
	}
end

local function dropCount(itemData, count, ctx)
	if not itemData or not itemData.item then
		return
	end
	count = math.floor(tonumber(count) or 0)
	if count < 1 then
		return
	end
	if count > itemData.count then
		count = itemData.count
	end
	core.sendGlobalEvent("S3UI_DropItem", dropEventData(itemData, count))
	queueRebuild(ctx)
end

local function openDropCountModal(itemData, ctx)
	countModal.show({
		title = "Drop " .. itemData.name,
		min = 1,
		max = itemData.count,
		initial = itemData.count,
		onOk = function(count)
			dropCount(itemData, count, ctx)
		end,
	})
end

function M.activateItem(itemData, ctx)
	if not itemData then
		return
	end
	if input.isShiftPressed() then
		openDropCountModal(itemData, ctx)
	elseif input.isCtrlPressed() then
		dropCount(itemData, 1, ctx)
	elseif itemData.equipped then
		unequip(itemData, ctx)
	else
		equip(itemData, ctx)
	end
end

return M
