---@omw-context global

local types = require 'openmw.types'
local world = require 'openmw.world'
local core = require 'openmw.core'

local BatchCache = require 'Scripts.staticSwitcher.batchCache'

local Player = world.players[1]
local Door = types.Door

local staticUtil = require 'Scripts.staticSwitcher.util'

local INVALID_TYPE = 'Invalid type was provided: %s'

local cellToExteriorRegion = {}

local type = type
local StrFind, StrLower, StrFormat, StrUpper = string.find, string.lower, string.format, string.upper

---@param cell openmw.core.GCell
---@param position openmw.util.Vector3
---@return string|nil
local function getExteriorRegionFromDoor(cell, position)
	local cached = cellToExteriorRegion[cell.id]

	if cached ~= nil then
		if type(cached) == 'string' then
			return cached
		end

		return
	end

	local nearestDoor
	local nearestDistSq = math.huge

	for _, door in ipairs(cell:getAll(types.Door)) do
		if Door.isTeleport(door) then
			local dest = Door.destCell(door)

			if dest and dest.isExterior then
				local distSq = (position - door.position):length2()

				if distSq < nearestDistSq then
					nearestDistSq = distSq
					nearestDoor = door
				end
			end
		end
	end

	if not nearestDoor then
		cellToExteriorRegion[cell.id] = true

		return
	end

	local region = Door.destCell(nearestDoor).region

	cellToExteriorRegion[cell.id] = region or true

	return region
end

---@type table<string, SSSConditionHandler>
local conditionHandlers = {
	---@param object openmw.GObject
	---@param itemId RecordId|table<RecordId, integer>
	---@return boolean
	carrying = function(object, itemId)
		if not object.type then
			return false
		end

		local objectHasInventory = object.type.inventory ~= nil
		if not objectHasInventory then
			return false
		end

		local objectInventory = object.type.inventory(object)

		local itemType = type(itemId)
		if itemType == 'string' then
			return StrFind(objectInventory, itemId) ~= nil
		else
			local itemName, itemCount = next(itemId)

			return objectInventory:countOf(itemName) >= itemCount
		end
	end,
	---@param object openmw.GObject
	---@param cellName string
	---@return boolean
	cell = function(object, cellName)
		return object.cell.name == cellName or object.cell.id == cellName
	end,
	---@param object openmw.GObject
	---@param matchStr string
	---@return boolean
	cell_match = function(object, matchStr)
		local cell = object.cell
		if not cell then
			return false
		end

		local cellId, cellName = StrLower(cell.id), cell.name
		if cellName ~= '' then
			cellName = StrLower(cellName)
		end

		return (cellName and StrFind(cellName, matchStr, 1, true) ~= nil)
				or (cellId and StrFind(cellId, matchStr, 1, true) ~= nil)
	end,
	---@param object openmw.GObject
	---@param cellCoords ExteriorGrid
	---@return boolean
	coords = function(object, cellCoords)
		if not object.cell.isExterior then
			return false
		end
		return object.cell.gridX == cellCoords.x and object.cell.gridY == cellCoords.y
	end,
	---@param object openmw.GObject
	---@param contentFileName string
	---@return boolean
	content_file = function(object, contentFileName)
		return (object.contentFile == contentFileName)
				or (not object.contentFile and StrUpper(contentFileName) == 'GENERATED')
	end,
	---@param object openmw.GObject
	---@param shouldBeExterior boolean
	---@return boolean
	exterior = function(object, shouldBeExterior)
		return object.cell ~= nil and object.cell.isExterior == shouldBeExterior
	end,
	---@param object openmw.GObject
	---@param shouldBeQuasiExterior boolean
	---@return boolean
	quasi_exterior = function(object, shouldBeQuasiExterior)
		return object.cell ~= nil and object.cell.isQuasiExterior == shouldBeQuasiExterior
	end,
	---@param object openmw.GObject
	---@param targetName string
	---@return boolean
	nameMatch = function(object, targetName)
		--- Statics may never have a name
		if types.Static.objectIsInstance(object) or not object.type then
			return false
		end

		local objectRecord = object.type.records[object.recordId]

		if objectRecord.name == nil or objectRecord.name == '' then
			return false
		end

		return objectRecord.name == targetName or StrFind(objectRecord.name, targetName, 1, true) ~= nil
	end,
	---@param object openmw.GObject
	---@param shouldHaveName boolean
	---@return boolean
	has_name = function(object, shouldHaveName)
		if not object.type then
			return shouldHaveName == false
		end

		local objectRecord = object.type.records[object.recordId]
		local objectName = objectRecord and objectRecord.name
		local objectHasName = objectName ~= nil and objectName ~= ''

		return objectHasName == shouldHaveName
	end,
	locked = function(object, lockData)
		local objType = object.type

		if not objType then
			return false
		end

		local isLockedFn = objType.isLocked
		if not isLockedFn then
			return false
		end

		local locked = isLockedFn(object)

		local dataType = type(lockData)

		if dataType == 'boolean' then
			return locked == lockData
		end

		if dataType == 'number' then
			if not locked then
				return false
			end

			return objType.getLockLevel(object) >= lockData
		end

		if dataType == 'table' then
			if not locked then
				return false
			end

			local level = objType.getLockLevel(object)

			if lockData.min and level < lockData.min then
				return false
			end

			if lockData.max and level > lockData.max then
				return false
			end

			return true
		end

		return false
	end,
	has_key = function(object, keyData)
		local getKeyRecord = object.type.getKeyRecord
		if not getKeyRecord then
			return false
		end

		local keyId = getKeyRecord(object)
		local keyRecordId = keyId and keyId.id

		if keyData == true then
			return keyRecordId ~= nil
		end
		if keyData == false then
			return keyRecordId == nil
		end

		if type(keyData) == 'string' then
			return keyRecordId == keyData
		end

		if keyData[1] then
			for i = 1, #keyData do
				if keyRecordId == keyData[i] then
					return true
				end
			end
		end

		return false
	end,
	has_trap = function(object, trapData)
		local getTrapSpell = object.type.getTrapSpell
		if not getTrapSpell then
			return false
		end

		local trapId = getTrapSpell(object)
		local trapRecordId = trapId and trapId.id

		if trapData == true then
			return trapRecordId ~= nil
		end
		if trapData == false then
			return trapRecordId == nil
		end

		if type(trapData) == 'string' then
			return trapRecordId == trapData
		end

		if trapData[1] then
			for i = 1, #trapData do
				if trapRecordId == trapData[i] then
					return true
				end
			end
		end

		return false
	end,
	---@param _ openmw.GObject
	---@param params { quest: string, index?: integer, min?: integer, max?: integer }
	---@return boolean
	has_journal = function(_, params)
		local questId = params.quest
		if type(questId) ~= 'string' then
			return false
		end

		local quests = BatchCache.playerQuests()
		local quest = quests[questId]
		if not quest then
			return false
		end

		local stage = quest.stage
		local minStage = params.index or params.min or 0
		local maxStage = params.max or math.huge

		return stage >= minStage and stage <= maxStage
	end,
	---@param object openmw.GObject
	---@param targetMesh string
	---@return boolean
	mesh = function(object, targetMesh)
		if not object.type then
			return false
		end

		local objectRecord = object.type.records[object.recordId]
		local objectMesh = objectRecord and objectRecord.model

		if not objectMesh then
			return false
		end

		return staticUtil.normalizePath(staticUtil.getMeshPath(objectMesh))
				== staticUtil.normalizePath(staticUtil.getMeshPath(targetMesh))
	end,
	---@param object openmw.GObject
	---@param targetTypeName string
	---@return boolean
	object_type = function(object, targetTypeName)
		local targetType = types[targetTypeName]

		assert(targetType ~= nil, StrFormat(INVALID_TYPE, targetTypeName))

		return targetType.objectIsInstance(object)
	end,
	---@param object openmw.GObject
	---@param targetRecordId RecordId
	---@return boolean
	record_id = function(object, targetRecordId)
		local originalId, targetId = object.recordId, targetRecordId

		-- Pattern matching enables ^/$ anchors (e.g. ^urn_ excludes furn_*).
		-- TES3 record IDs are alphanumeric + underscore + space + apostrophe,
		-- none of which are Lua-pattern-special, so this is backwards compatible.
		return originalId == targetId or StrFind(originalId, targetId, 1) ~= nil
	end,
	---@param object openmw.GObject
	---@param targetData table<string, number[]>
	---@return boolean
	content_file_target = function(object, targetData)
		local objectContentFile = object.contentFile

		if not objectContentFile then
			return false
		end

		local _, refNum = staticUtil.getRefNum(object)

		for contentFile, refnums in pairs(targetData) do
			if objectContentFile == contentFile then
				for refIndex = 1, #refnums do
					if refNum == refnums[refIndex] then
						return true
					end
				end

				return false
			end
		end

		return false
	end,
	---@param object openmw.GObject
	---@param shouldBeGenerated boolean
	---@return boolean
	generated = function(object, shouldBeGenerated)
		local isGenerated = staticUtil.getRefNum(object)

		return isGenerated == shouldBeGenerated
	end,
	---@param object openmw.GObject
	---@param targetRegion string
	---@return boolean
	region = function(object, targetRegion)
		local cell = object.cell
		---@cast cell openmw.core.GCell
		---@type string?
		local region = cell.region

		if not region and not cell.isExterior then
			region = getExteriorRegionFromDoor(cell, object.position)
		end

		return region ~= nil and StrLower(region) == targetRegion
	end,
	---@param object openmw.GObject
	---@param targetScale SSSNumericRange
	---@return boolean
	scale = function(object, targetScale)
		if type(targetScale) == 'number' then
			return object.scale == targetScale
		end

		return object.scale >= (targetScale.min or -math.huge) and object.scale <= targetScale.max
	end,
	---@param object openmw.GObject
	---@param targetWorldspace string
	---@return boolean
	worldspace = function(object, targetWorldspace)
		local worldspace = object.cell and object.cell.worldSpaceId

		return worldspace ~= nil and StrLower(worldspace) == targetWorldspace
	end,
	['player_level'] = function(_, levelData)
		local currentLevel = Player.type.stats.level(Player).current

		if type(levelData) == 'number' then
			return currentLevel >= levelData
		end

		if levelData.min and currentLevel < levelData.min then
			return false
		end
		if levelData.max and currentLevel > levelData.max then
			return false
		end

		return true
	end,
	['target_level'] = function(object, levelData)
		if not object.type then
			return false
		end

		local stats = object.type.stats
		if not stats then
			return false
		end

		local currentLevel = stats.level(object).current

		if type(levelData) == 'number' then
			return currentLevel >= levelData
		end

		if levelData.min and currentLevel < levelData.min then
			return false
		end
		if levelData.max and currentLevel > levelData.max then
			return false
		end

		return true
	end,
	['player_attribute'] = function(_, attrData)
		local getStat = BatchCache.attributeStat

		for attrId, attrValue in pairs(attrData) do
			local value = getStat(nil, attrId).modified

			if type(attrValue) == 'number' then
				if value < attrValue then
					return false
				end
			else
				if attrValue.min and value < attrValue.min then
					return false
				end

				if attrValue.max and value > attrValue.max then
					return false
				end
			end
		end

		return true
	end,
	['player_skill'] = function(_, skillData)
		local getStat = BatchCache.skillStat

		for skillId, skillValue in pairs(skillData) do
			local value = getStat(nil, skillId).modified

			if type(skillValue) == 'number' then
				if value < skillValue then
					return false
				end
			else
				if skillValue.min and value < skillValue.min then
					return false
				end

				if skillValue.max and value > skillValue.max then
					return false
				end
			end
		end

		return true
	end,
	['target_attribute'] = function(object, attrData)
		local objType = object.type
		if not objType then
			return false
		end

		local stats = objType.stats
		if not stats then
			return false
		end

		local getStat = BatchCache.attributeStat

		for attrId, attrValue in pairs(attrData) do
			local value = getStat(object, attrId).modified

			if type(attrValue) == 'number' then
				if value < attrValue then
					return false
				end
			else
				if attrValue.min and value < attrValue.min then
					return false
				end

				if attrValue.max and value > attrValue.max then
					return false
				end
			end
		end

		return true
	end,
	['target_skill'] = function(object, skillData)
		local objType = object.type
		if not objType then
			return false
		end

		local stats = objType.stats
		if not stats or not stats.skills then
			return false
		end

		local getStat = BatchCache.skillStat

		for skillId, skillValue in pairs(skillData) do
			local value = getStat(object, skillId).modified

			if type(skillValue) == 'number' then
				if value < skillValue then
					return false
				end
			else
				if skillValue.min and value < skillValue.min then
					return false
				end

				if skillValue.max and value > skillValue.max then
					return false
				end
			end
		end

		return true
	end,
	['time_of_day'] = function(_, hourData)
		local currentHour = (core.getGameTime() / 3600) % 24

		if type(hourData) == 'number' then
			return currentHour >= hourData
		end

		if hourData.min and currentHour < hourData.min then
			return false
		end
		if hourData.max and currentHour > hourData.max then
			return false
		end

		return true
	end,
	['player_faction'] = function(_, factionData)
		local faction = factionData.faction
		local rank = Player.type.getFactionRank(Player, faction)

		if factionData.rank then
			return rank >= factionData.rank
		end

		if factionData.min and rank < factionData.min then
			return false
		end
		if factionData.max and rank > factionData.max then
			return false
		end

		return rank > 0
	end,
	['faction_owner_id'] = function(object, factionId)
		local ownerFaction = object.owner.factionId
		if not ownerFaction then
			return false
		end

		return ownerFaction == factionId
	end,
	['owner_id'] = function(object, ownerRecordId)
		local ownerId = object.owner.recordId
		if not ownerId then
			return false
		end

		return ownerId == ownerRecordId
	end,
	['faction_owner_rank'] = function(object, rankData)
		local rank = object.owner.factionRank
		if not rank then
			return false
		end

		if type(rankData) == 'number' then
			return rank >= rankData
		end

		if rankData.min and rank < rankData.min then
			return false
		end
		if rankData.max and rank > rankData.max then
			return false
		end

		return true
	end,
	['target_faction'] = function(object, factionData)
		if object.type ~= types.NPC then
			return false
		end

		local faction = factionData.faction
		local rank = object.type.getFactionRank(object, faction)

		if factionData.rank then
			return rank >= factionData.rank
		end

		if factionData.min and rank < factionData.min then
			return false
		end
		if factionData.max and rank > factionData.max then
			return false
		end

		return rank > 0
	end,
	['target_class'] = function(object, classData)
		if object.type ~= types.NPC then
			return false
		end

		local objectRecord = object.type.records[object.recordId]
		local classId = objectRecord and objectRecord.class
		if not classId then
			return false
		end

		if type(classData) == 'string' then
			return StrLower(classId) == classData
		end

		if classData[1] then
			for i = 1, #classData do
				if StrLower(classId) == classData[i] then
					return true
				end
			end
			return false
		end

		return false
	end,
	['player_equipped'] = function(_, equippedData)
		local equipment = BatchCache.playerEquipment()

		if type(equippedData) == 'string' then
			for _, item in pairs(equipment) do
				if item.recordId == equippedData then
					return true
				end
			end
			return false
		end

		if equippedData[1] then
			for _, item in pairs(equipment) do
				for i = 1, #equippedData do
					if item.recordId == equippedData[i] then
						return true
					end
				end
			end
			return false
		end

		return false
	end,
	['current_weather'] = function(_, weatherData)
		local current = BatchCache.currentWeather(Player.cell)

		if type(weatherData) == 'string' then
			if weatherData == 'none' then
				return current == nil
			end
			if not current then
				return false
			end
			return StrFind(StrLower(current.name), weatherData, 1, true) ~= nil
		end

		if weatherData[1] then
			for i = 1, #weatherData do
				if weatherData[i] == 'none' then
					if current == nil then
						return true
					end
				elseif current and StrFind(StrLower(current.name), weatherData[i], 1, true) ~= nil then
					return true
				end
			end
			return false
		end

		if weatherData.isStorm ~= nil then
			if not current or current.isStorm ~= weatherData.isStorm then
				return false
			end
		end
		if weatherData.name then
			if not current or not StrFind(StrLower(current.name), StrLower(weatherData.name), 1, true) then
				return false
			end
		end

		return true
	end,
}

--- Invert a single inner condition. Defined outside the table constructor
--- so conditionHandlers is already assigned when this closure captures it.
--- The value is a condition table like `{nameMatch = "Guard"}` — the inner
--- condition is extracted, evaluated through its own handler, and the result
--- is negated.
---
--- Multiple exclusions use multiple `not` entries (ANDed together):
--- ```yaml
--- conditions:
---   - not: { nameMatch: Guard }
---   - not: { nameMatch: Soldier }
--- ```
---@param object openmw.GObject
---@param innerCondition table<string, any>
---@return boolean
conditionHandlers['not'] = function(object, innerCondition)
	local innerName, innerValue = next(innerCondition)
	local innerHandler = conditionHandlers[innerName]

	if type(innerHandler) ~= 'function' then
		error(StrFormat('Condition %s is an invalid condition for the NOT handler!', innerName))
	end

	-- Expand OR-lists inside the negation so
	-- `not: { nameMatch: [Guard, Soldier] }` works intuitively:
	-- if ANY value matches, the negation fails.
	if type(innerValue) == 'table' then
		local firstKey = next(innerValue)

		if firstKey and type(firstKey) == 'number' then
			for valIndex = 1, #innerValue do
				if innerHandler(object, innerValue[valIndex]) then
					return false
				end
			end

			return true
		end
	end

	return not innerHandler(object, innerValue)
end

return conditionHandlers
