---@omw-context global

local core = require 'openmw.core'
local world = require 'openmw.world'
local types = require 'openmw.types'
local util = require 'openmw.util'

local ambient = require 'openmw.ambient'

local randomGen = require 'scripts.s3.randomGen'

local next, pairs, pcall, type = next, pairs, pcall, type

local rotateX = util.transform.rotateX
local rotateY = util.transform.rotateY
local rotateZ = util.transform.rotateZ
local rad = math.rad

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
	if not inventory then
		return false
	end

	local availableCount = inventory:countOf(recordId)
	if availableCount < 1 then
		return false
	end

	local remainingCount = math.min(count, availableCount)
	local items = inventory:findAll(recordId)

	for i = 1, #items do
		local itemStack = items[i]
		local removeCount = math.min(remainingCount, itemStack.count)

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

---@param actor openmw.GObject
---@param recordId RecordId
---@return integer count
local function countEquippedItems(actor, recordId)
	if not ActorObjectIsInstance(actor) then
		return 0
	end

	local count = 0

	for _, item in pairs(actor.type.getEquipment(actor)) do
		if item.recordId == recordId then
			count = count + 1
		end
	end

	return count
end

---@param actor openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasUnequipped
local function unequipInventoryItem(actor, recordId, count)
	if count < 1 or countEquippedItems(actor, recordId) < count then
		return false
	end

	local remainingCount = count

	for _, item in pairs(actor.type.getEquipment(actor)) do
		if item.recordId == recordId then
			core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = true })
			remainingCount = remainingCount - 1

			if remainingCount <= 0 then
				return true
			end
		end
	end

	return false
end

---@param itemData integer|SSSItemActionDetails
---@return integer count
---@return SSSChanceRange? chance
local function getItemActionDetails(itemData)
	if type(itemData) == 'table' then
		if not itemData.count and not itemData.chance then
			return 0
		end

		local count = itemData.count or 1
		if type(count) == 'table' then
			assert(count.max, 'RangeTable requires a "max"')
			count.min = count.min or 1
			assert(count.min <= count.max, 'RangeTable requires min <= max')
			-- Must use randomGen.range(_, true) for integer output;
			-- getRangeValue returns floats (correct for positions, not counts).
			count = randomGen.range(count, true)
		end

		return count, itemData.chance
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

		return randomGen.float() <= chance
	end

	assert(chance.max, 'Chance range table is missing required "max" field')

	if chance.max <= 0 then
		return false
	elseif chance.min and chance.min >= 1 then
		return true
	end

	local roll = randomGen.float()

	return roll >= (chance.min or 0) and roll <= chance.max
end

---@param object openmw.GObject
---@param itemAction SSSItemAction
---@param itemHandler fun(object: openmw.GObject, recordId: RecordId, count: integer): boolean
---@param arrayItemCount integer? Default count to use for each element in the array form.
---@return boolean wasApplied
local function applyItemAction(object, itemAction, itemHandler, arrayItemCount)
	local actionType = type(itemAction)

	if actionType == 'string' then
		return itemHandler(object, itemAction, 1)
	elseif actionType == 'table' then
		local firstKey = next(itemAction)

		-- Array of record IDs: apply the same count to each.
		if firstKey and type(firstKey) == 'number' then
			local wasApplied = false
			local count = arrayItemCount or 1
			local numItems = #itemAction

			for i = 1, numItems do
				wasApplied = itemHandler(object, itemAction[i], count) or wasApplied
			end

			return wasApplied
		end

		-- Map of record IDs to counts: existing behavior.
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

---
--- Helper: extract a numeric value from a number or {min, max} range table.
---@param numberOrTable number|SSSNumericRange
---@return number
local function getRangeValue(numberOrTable)
	local actionDataType = type(numberOrTable)

	if actionDataType == 'number' then
		return numberOrTable
	elseif actionDataType == 'table' then
		assert(numberOrTable.max, 'An upper bound is required when selecting a numeric range!')
		return randomGen.range(numberOrTable.min or 0, numberOrTable.max)
	elseif actionDataType == 'nil' then
		return 0
	else
		error('Incorrect type provided to getRangeValue: ' .. actionDataType)
	end
end

---
--- Apply rotation to a transform, optionally relative to current.
---@param isRelative boolean
---@param rotateActionDetails SSSVector3Range
---@param currentTransform openmw.util.Transform
---@return openmw.util.Transform
local function getRotationValue(isRelative, rotateActionDetails, currentTransform)
	local rootTransform = isRelative and currentTransform or util.transform.identity

	local z = rotateActionDetails.z
	if z then
		rootTransform = rotateZ(rad(getRangeValue(z))) * rootTransform
	end

	local y = rotateActionDetails.y
	if y then
		rootTransform = rotateY(rad(getRangeValue(y))) * rootTransform
	end

	local x = rotateActionDetails.x
	if x then
		rootTransform = rotateX(rad(getRangeValue(x))) * rootTransform
	end

	return rootTransform
end

---
--- Calculate target scale from a scale action, relative to a reference.
---@param scaleAction SSSNumericRange
---@param referenceScale number
---@return number
local function getScaleValue(scaleAction, referenceScale)
	local scaleType = type(scaleAction)

	if scaleType == 'number' then
		return referenceScale * scaleAction
	elseif scaleType == 'table' then
		return referenceScale * randomGen.range(scaleAction.min or 1.0, scaleAction.max)
	end

	error('Invalid type for scale parameter: ' .. scaleType)
end

---@type table<string, function>
local actionHandlers = {
	['transform'] = function(_, transformAction, newTransform, newPos, targetScale)
		local wasModified = false
		local useRelativeTransform = transformAction.transform_type == nil
			or transformAction.transform_type == 'relative'

		local scaleAction = transformAction.scale
		if scaleAction then
			local referenceScale = useRelativeTransform and targetScale or 1.0
			targetScale = getScaleValue(scaleAction, referenceScale)
			wasModified = true
		end

		local rotateAction = transformAction.rotate
		if rotateAction then
			newTransform = getRotationValue(useRelativeTransform, rotateAction, newTransform)
			wasModified = true
		end

		local positionAction = transformAction.position
		if positionAction then
			local actionTargetPos = util.vector3(
				getRangeValue(positionAction.x),
				getRangeValue(positionAction.y),
				getRangeValue(positionAction.z)
			)

			if useRelativeTransform then
				newPos = newPos + actionTargetPos
			else
				newPos = actionTargetPos
			end

			wasModified = true
		end

		return wasModified, newTransform, newPos, targetScale
	end,
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
		return applyItemAction(object, addActionData, addItemToInventory, 1)
	end,
	['remove'] = function(object, removeActionData)
		return applyItemAction(object, removeActionData, removeItemFromInventory, math.huge)
	end,
	['equip'] = function(object, equipActionData)
		return applyItemAction(object, equipActionData, equipInventoryItem, 1)
	end,
	['unequip'] = function(object, unequipActionData)
		return applyItemAction(object, unequipActionData, unequipInventoryItem, 1)
	end,
	['disable'] = function(_, disableAction)
		if disableAction == true then
			return true
		end
		if type(disableAction) == 'table' then
			if not disableAction.chance then
				return true
			end
			return randomGen.float() <= disableAction.chance
		end
		return false
	end,
	['delete'] = function(_, deleteAction, replaceAction, replaceActionSucceeded)
		return deleteAction and (not replaceAction or replaceActionSucceeded)
	end,
	['create'] = function(triggerObject, createActionData)
		local totalCreated = 0

		for recordId, details in pairs(createActionData) do
			local count, chance, positionOverride, rotateOverride, scaleOverride, transformType
			local detailsType = type(details)

			if detailsType == 'string' then
				count = 1
			elseif detailsType == 'number' then
				count = math.floor(details)
			elseif detailsType == 'table' then
				count = details.count or 1
				if type(count) == 'table' then
					assert(count.max, 'RangeTable requires a "max"')
					count.min = count.min or 1
					assert(count.min <= count.max, 'RangeTable requires min <= max')
					-- Must use randomGen.range(_, true) for integer output;
					-- getRangeValue returns floats (correct for positions, not counts).
					count = randomGen.range(count, true)
				end
				chance = details.chance
				positionOverride = details.position
				rotateOverride = details.rotate
				scaleOverride = details.scale
				transformType = details.transform_type
			end

			if count and count >= 1 then
		if chance and not shouldApplyChance(chance) then
					-- pool missed
				else
					local useRelativeTransform = transformType == nil or transformType == 'relative'
					local baseTransform = triggerObject.rotation
					local basePos = triggerObject.position
					local baseScale = triggerObject.scale
					local baseCell = triggerObject.cell

					for _ = 1, count do
						local newPos = basePos
						local newTransform = baseTransform
						local targetScale = baseScale

						if positionOverride then
							local offset = util.vector3(
								getRangeValue(positionOverride.x),
								getRangeValue(positionOverride.y),
								getRangeValue(positionOverride.z)
							)
							if useRelativeTransform then
								newPos = newPos + offset
							else
								newPos = offset
							end
						end

						if rotateOverride then
							newTransform = getRotationValue(useRelativeTransform, rotateOverride, newTransform)
						end

						if scaleOverride then
							local referenceScale = useRelativeTransform and targetScale or 1.0
							targetScale = getScaleValue(scaleOverride, referenceScale)
						end

						local obj = world.createObject(recordId)
						obj:teleport(baseCell, newPos, newTransform)
						if scaleOverride then
							obj:setScale(targetScale)
						end
						totalCreated = totalCreated + 1
					end
				end
			end
		end

		return totalCreated
	end,
	['lock_level'] = function(object, lockData)
		if not object.type.lock then
			return false
		end

		local level
		if type(lockData) == 'number' then
			level = lockData
		elseif type(lockData) == 'table' then
			lockData.min = lockData.min or 1
			assert(lockData.min <= lockData.max, 'RangeTable requires min <= max')
			level = randomGen.range(lockData, true)
		else
			return false
		end

		if level <= 0 then
			object.type.unlock(object)
		else
			object.type.lock(object, level)
		end

		return true
	end,
	['playsound'] = function(object, soundData)
		local soundId, chance

		if type(soundData) == 'string' then
			soundId = soundData
		elseif type(soundData) == 'table' then
			soundId = soundData.id
			chance = soundData.chance
		end

		if not soundId then
			return false
		end

		if chance and randomGen.float() > chance then
			return false
		end

		ambient.playSound(soundId, { object = object })
		return true
	end,
	['set_ownership'] = function(object, ownershipData)
		local madeChange = false
		local owner = object.owner

		if ownershipData.owner then
			owner.recordId = ownershipData.owner
			madeChange = true
		end
		if ownershipData.faction then
			owner.factionId = ownershipData.faction
			madeChange = true
		end
		if ownershipData.factionRank then
			owner.factionRank = ownershipData.factionRank
			madeChange = true
		end

		return madeChange
	end,
	['key'] = function(object, keyData)
		if not object.type.setKeyRecord then
			return false
		end

		if keyData == false then
			object.type.setKeyRecord(object, nil)
			return true
		end

		for i = 1, #keyData do
			local keyId, chance = next(keyData[i])
			if shouldApplyChance(chance) then
				object.type.setKeyRecord(object, entry.id)
				return true
			end
		end

		return false
	end,
	['trap'] = function(object, trapData)
		if not object.type.setTrapSpell then
			return false
		end

		if trapData == false then
			object.type.setTrapSpell(object, nil)
			return true
		end

		for i = 1, #trapData do
			local trapId, chance = next(trapData[i])
			if shouldApplyChance(chance) then
				object.type.setTrapSpell(object, entry.id)
				return true
			end
		end

		return false
	end,
}

return actionHandlers
