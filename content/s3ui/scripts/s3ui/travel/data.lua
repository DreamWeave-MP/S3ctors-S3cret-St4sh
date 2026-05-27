---@omw-context player

local core = require 'openmw.core'
local self = require 'openmw.self'
local types = require 'openmw.types'

local GOLD_ID = 'gold_001'

---@class S3UI.TravelDataModule
local M = {}

local cellDisplayNames = {}

local function validObject(object)
	return object and object.isValid and object:isValid()
end

local function numericGmst(id, fallback)
	local value = core.getGMST(id)
	if type(value) == 'number' then
		return value
	end
	return fallback
end

local function actorRecord(actor)
	if not validObject(actor) then
		return nil
	end
	if types.NPC.objectIsInstance(actor) then
		return types.NPC.record(actor)
	elseif types.Creature.objectIsInstance(actor) then
		return types.Creature.record(actor)
	end
	return nil
end

local function distance(a, b, includeZ)
	if not (a and b) then
		return 0
	end
	local dx = (a.x or 0) - (b.x or 0)
	local dy = (a.y or 0) - (b.y or 0)
	local dz = includeZ and ((a.z or 0) - (b.z or 0)) or 0
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function playerGold()
	return types.Actor.inventory(self):countOf(GOLD_ID)
end

local function statValue(stat, field, fallback)
	if not stat then
		return fallback or 0
	end
	local value = stat[field]
	if type(value) == 'number' then
		return value
	end
	return fallback or 0
end

local function modifiedStat(stat)
	if not stat then
		return 0
	end
	if type(stat.modified) == 'number' then
		return stat.modified
	end
	return statValue(stat, 'base') + statValue(stat, 'modifier')
end

local function actorStats(actor)
	return actor and actor.type and actor.type.stats or types.Actor.stats
end

local function fatigueTerm(actor)
	local stats = actorStats(actor)
	local fatigue = stats and stats.dynamic and stats.dynamic.fatigue(actor) or nil
	local maxFatigue = modifiedStat(fatigue)
	local currentFatigue = statValue(fatigue, 'current', maxFatigue)
	local normalised = 1
	if math.floor(maxFatigue) ~= 0 then
		normalised = math.max(0, currentFatigue / maxFatigue)
	end
	return numericGmst('fFatigueBase', 1.25) - numericGmst('fFatigueMult', 0.5) * (1 - normalised)
end

local function mercantile(actor)
	local stats = actorStats(actor)
	local skill = stats and stats.skills and stats.skills.mercantile(actor) or nil
	return math.min(modifiedStat(skill), 100)
end

local function luckTerm(actor)
	local stats = actorStats(actor)
	local luck = stats and stats.attributes and stats.attributes.luck(actor) or nil
	return math.min(0.1 * modifiedStat(luck), 10)
end

local function personalityTerm(actor)
	local stats = actorStats(actor)
	local personality = stats and stats.attributes and stats.attributes.personality(actor) or nil
	return math.min(0.2 * modifiedStat(personality), 10)
end

local function truncate(value)
	if value < 0 then
		return math.ceil(value)
	end
	return math.floor(value)
end

local function targetName(target, record)
	if record and type(record.name) == 'string' and record.name ~= '' then
		return record.name
	end
	return target and target.recordId or 'Travel Service'
end

local function destinationLabel(destination)
	local cellId = destination and destination.cellId
	local displayName = cellDisplayNames[cellId]
	if type(displayName) == 'string' and displayName ~= '' then
		return displayName
	end
	if type(cellId) == 'string' and cellId ~= '' then
		return cellId
	end
	return 'Wilderness'
end

local function basePrice(target, destination)
	if target and target.cell and not target.cell.isExterior then
		return math.floor(numericGmst('fMagesGuildTravel', 10))
	end
	local travelMult = numericGmst('fTravelMult', 4000)
	local dist = distance(self.position, destination and destination.position, true)
	if travelMult ~= 0 then
		dist = dist / travelMult
	end
	return math.floor(dist)
end

function M.getBarterOffer(target, basePrice, buying)
	basePrice = math.floor(tonumber(basePrice) or 0)
	if basePrice == 0 or not validObject(target) or types.Creature.objectIsInstance(target) then
		return basePrice
	end
	if not types.NPC.objectIsInstance(target) then
		return math.max(1, basePrice)
	end
	local player = self.object or self
	local disposition = types.NPC.getDisposition(target, player)
	if type(disposition) ~= 'number' then
		disposition = 50
	end
	local pcTerm = (disposition - 50 + mercantile(player) + luckTerm(player) + personalityTerm(player))
		* fatigueTerm(player)
	local npcTerm = (mercantile(target) + luckTerm(target) + personalityTerm(target)) * fatigueTerm(target)
	local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
	local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
	return math.max(1, truncate(basePrice * (buying and buyTerm or sellTerm)))
end

---@param target openmw.Object|nil
---@return table
function M.serviceInfo(target)
	local record = actorRecord(target)
	return {
		target = target,
		record = record,
		name = targetName(target, record),
		playerGold = playerGold(),
		destinations = record and record.travelDestinations or {},
	}
end

---@param target openmw.Object|nil
---@param followerCount number|nil
---@return table[]
---@param target openmw.Object|nil
---@param followerCount integer|nil
---@return S3UI.TravelRow[]
function M.collectRows(target, followerCount)
	local info = M.serviceInfo(target)
	followerCount = math.max(0, math.floor(tonumber(followerCount) or 0))
	local rows = {}
	for index, destination in ipairs(info.destinations) do
		local base = math.max(1, basePrice(target, destination)) * (1 + followerCount)
		local price = M.getBarterOffer(target, base, true)
		rows[#rows + 1] = {
			index = index,
			destination = destination,
			cellId = destination.cellId,
			label = destinationLabel(destination),
			price = price,
			followerCount = followerCount,
			enabled = price <= info.playerGold,
		}
	end
	return rows
end

---@param destination S3UI.TravelDestination|nil
---@return number
function M.travelHours(destination)
	local fTravelTimeMult = numericGmst('fTravelTimeMult', 16000)
	if fTravelTimeMult == 0 then
		return 0
	end
	return math.max(
		0,
		math.floor(distance(self.position, destination and destination.position, false) / fTravelTimeMult)
	)
end

M.GOLD_ID = GOLD_ID

---@param names table<string, string>
---@return boolean changed
function M.setCellDisplayNames(names)
	if type(names) ~= 'table' then
		return false
	end
	local changed = false
	for cellId, displayName in pairs(names) do
		if type(cellId) == 'string' and type(displayName) == 'string' and displayName ~= '' then
			if cellDisplayNames[cellId] ~= displayName then
				cellDisplayNames[cellId] = displayName
				changed = true
			end
		end
	end
	return changed
end

return M
