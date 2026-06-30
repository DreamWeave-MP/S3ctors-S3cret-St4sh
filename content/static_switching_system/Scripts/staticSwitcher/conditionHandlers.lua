---@omw-context global

local types = require 'openmw.types'
local world = require 'openmw.world'
local core = require 'openmw.core'
local Weather = core.weather

local Player = world.players[1]
local Door = types.Door

local staticUtil = require 'Scripts.staticSwitcher.util'

local INVALID_TYPE = 'Invalid type was provided: %s'

local cellToExteriorRegion = {}

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
			return objectInventory:find(itemId) ~= nil
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

		local lowerSearch = matchStr:lower()

		return (cell.name and cell.name:lower():find(lowerSearch, 1, true))
			or (cell.id and cell.id:lower():find(lowerSearch, 1, true))
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
		return (object.contentFile == contentFileName:lower())
			or (not object.contentFile and contentFileName:upper() == 'GENERATED')
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

		return objectRecord.name == targetName or objectRecord.name:find(targetName, 1, true) ~= nil
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
	---@param object openmw.GObject
	---@param params { quest: string, index?: integer, min?: integer, max?: integer }
	---@return boolean
	has_journal = function(_, params)
		local questId = params.quest
		if type(questId) ~= 'string' then
			return false
		end

		local quests = types.Player.quests(Player)
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

		assert(targetType ~= nil, INVALID_TYPE:format(targetTypeName))

		return targetType.objectIsInstance(object)
	end,
	---@param object openmw.GObject
	---@param targetRecordId RecordId
	---@return boolean
	record_id = function(object, targetRecordId)
		local originalId, lowerId = object.recordId, targetRecordId:lower()

		-- Pattern matching enables ^/$ anchors (e.g. ^urn_ excludes furn_*).
		-- TES3 record IDs are alphanumeric + underscore + space + apostrophe,
		-- none of which are Lua-pattern-special, so this is backwards compatible.
		return originalId == lowerId or originalId:find(lowerId, 1) ~= nil
	end,
	---@param object openmw.GObject
	---@param targetData table<string, number[]>
	---@return boolean
	content_file_target = function(object, targetData)
		local objectContentFile = object.contentFile

		if not objectContentFile then
			return false
		end

		for contentFile, refnums in pairs(targetData) do
			if objectContentFile == contentFile:lower() then
				local _, refNum = staticUtil.getRefNum(object)

				for _, targetRef in ipairs(refnums) do
					if refNum == targetRef then
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
		local region = cell.region

		if not region and not cell.isExterior then
			region = getExteriorRegionFromDoor(cell, object.position)
		end

		return region ~= nil and region:lower() == targetRegion:lower()
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

		return worldspace ~= nil and worldspace:lower() == targetWorldspace:lower()
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
	['time_of_day'] = function(_, hourData)
		local currentHour = core.getGameTime().hour

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

		local classId = object.type.records[object.recordId].class

		if type(classData) == 'string' then
			return classId:lower() == classData:lower()
		end

		if classData[1] then
			for i = 1, #classData do
				if classId:lower() == classData[i]:lower() then
					return true
				end
			end
			return false
		end

		return false
	end,
	['player_equipped'] = function(_, equippedData)
		local equipment = Player:getEquipment()

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
		local current = Weather.getCurrent(Player.cell)

		if type(weatherData) == 'string' then
			if weatherData == 'none' then
				return current == nil
			end
			if not current then
				return false
			end
			return string.find(current.name:lower(), weatherData:lower(), 1, true) ~= nil
		end

		if weatherData[1] then
			for i = 1, #weatherData do
				if weatherData[i] == 'none' then
					if current == nil then
						return true
					end
				elseif current and string.find(current.name:lower(), weatherData[i]:lower(), 1, true) ~= nil then
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
			if not current or not string.find(current.name:lower(), weatherData.name:lower(), 1, true) then
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
conditionHandlers["not"] = function(object, innerCondition)
	local innerName, innerValue = next(innerCondition)
	local innerHandler = conditionHandlers[innerName]

	if type(innerHandler) ~= 'function' then
		error(('Condition %s is an invalid condition for the NOT handler!'):format(innerName))
	end

	-- Expand OR-lists inside the negation so
	-- `not: { nameMatch: [Guard, Soldier] }` works intuitively:
	-- if ANY value matches, the negation fails.
	if type(innerValue) == 'table' then
		local firstKey = next(innerValue)

		if firstKey and type(firstKey) == 'number' then
			for _, individualValue in ipairs(innerValue) do
				if innerHandler(object, individualValue) then
					return false
				end
			end

			return true
		end
	end

	return not innerHandler(object, innerValue)
end

return conditionHandlers
