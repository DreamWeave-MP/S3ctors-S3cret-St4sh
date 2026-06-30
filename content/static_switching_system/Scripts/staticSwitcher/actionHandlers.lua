---@omw-context global

local core = require 'openmw.core'
local world = require 'openmw.world'
local types = require 'openmw.types'

local randomGen = require 'scripts.s3.randomGen'

local ipairs, pairs, pcall, type = ipairs, pairs, pcall, type

local ActorObjectIsInstance = types.Actor.objectIsInstance
local ContainerObjectIsInstance = types.Container.objectIsInstance

---@param object openmw.GObject
---@return openmw.core.Inventory? inventory
local function getObjectInventory(object)
	if not ContainerObjectIsInstance(object) and not ActorObjectIsInstance(object) then
		return
	end

	return object.type.inventory(object)
end

---@param object openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasAdded
local function addItemToInventory(object, recordId, count)
	if count < 1 then
		return false
	end

	local inventory = getObjectInventory(object)
	if not inventory then
		return false
	end

	world.createObject(recordId, count):moveInto(inventory)
	return true
end

---@param object openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasRemoved
local function removeItemFromInventory(object, recordId, count)
	if count < 1 then
		return false
	end

	local inventory = getObjectInventory(object)
	if not inventory or inventory:countOf(recordId) < count then
		return false
	end

	local remainingCount = count

	for _, itemStack in ipairs(inventory:findAll(recordId)) do
		local removeCount = remainingCount
		if itemStack.count < removeCount then
			removeCount = itemStack.count
		end

		itemStack:remove(removeCount)
		remainingCount = remainingCount - removeCount

		if remainingCount <= 0 then
			return true
		end
	end

	return false
end

---@param actor openmw.GObject
---@param recordId RecordId
---@param count integer
---@return openmw.GObject? item
local function getOrCreateInventoryItem(actor, recordId, count)
	if count < 1 or not ActorObjectIsInstance(actor) then
		return
	end

	local inventory = getObjectInventory(actor)
	if not inventory then
		return
	end

	local item = inventory:find(recordId)
	if item then
		return item
	end

	item = world.createObject(recordId, count)
	item:moveInto(inventory)

	return item
end

---@param actor openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasEquipped
local function equipInventoryItem(actor, recordId, count)
	local item = getOrCreateInventoryItem(actor, recordId, count)
	if not item then
		return false
	end

	core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = true })
	return true
end

---@param chance SSSChanceRange?
---@return number chanceValue
local function getChanceValue(chance)
	local chanceType = type(chance)

	if chanceType == 'number' then
		return chance
	elseif chanceType == 'table' then
		return randomGen.range(chance.min or 0, chance.max)
	end

	return 0
end

---@param itemData integer|SSSItemActionDetails
---@return integer count
---@return SSSChanceRange? chance
local function getItemActionDetails(itemData)
	if type(itemData) == 'table' then
		if not itemData.count and not itemData.chance then
			return 0
		end

		return itemData.count or 1, itemData.chance
	end

	return itemData
end

---@param chance SSSChanceRange?
---@return boolean shouldApply
local function shouldApplyChance(chance)
	if not chance then
		return true
	end

	if type(chance) == 'number' then
		if chance <= 0 then
			return false
		elseif chance >= 1 then
			return true
		end
	elseif type(chance) == 'table' then
		if chance.max <= 0 then
			return false
		elseif chance.min and chance.min >= 1 then
			return true
		end
	end

	return randomGen.float() <= getChanceValue(chance)
end

---@param object openmw.GObject
---@param itemAction SSSItemAction
---@param itemHandler fun(object: openmw.GObject, recordId: RecordId, count: integer): boolean
---@return boolean wasApplied
local function applyItemAction(object, itemAction, itemHandler)
	local actionType = type(itemAction)

	if actionType == 'string' then
		return itemHandler(object, itemAction, 1)
	elseif actionType == 'table' then
		local wasApplied = false

		for recordId, itemData in pairs(itemAction) do
			local count, chance = getItemActionDetails(itemData)

			if count >= 1 and shouldApplyChance(chance) then
				wasApplied = itemHandler(object, recordId, count) or wasApplied
			end
		end

		return wasApplied
	end

	return false
end

---@type table<string, function>
local actionHandlers = {
	['replace'] = function(_, replaceActionData)
		for replaceId, replaceChance in pairs(replaceActionData) do
			if randomGen.float() <= replaceChance then
				local result, replacement = pcall(world.createObject, replaceId)

				if result then
					return replacement
				end
			end
		end
	end,
	['add'] = function(object, addActionData)
		return applyItemAction(object, addActionData, addItemToInventory)
	end,
	['remove'] = function(object, removeActionData)
		return applyItemAction(object, removeActionData, removeItemFromInventory)
	end,
	['equip'] = function(object, equipActionData)
		return applyItemAction(object, equipActionData, equipInventoryItem)
	end,
}

return actionHandlers
