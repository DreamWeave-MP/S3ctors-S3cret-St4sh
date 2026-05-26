---@omw-context player

local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")

local GOLD_ID = "gold_001"

local M = {}

local function validObject(object)
	return object and object.isValid and object:isValid()
end

local function numericGmst(id, fallback)
	local value = core.getGMST(id)
	if type(value) == "number" then
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

local function targetName(target, record)
	if record and type(record.name) == "string" and record.name ~= "" then
		return record.name
	end
	return target and target.recordId or "Travel Service"
end

local function destinationLabel(destination)
	local cellId = destination and destination.cellId
	if type(cellId) == "string" and cellId ~= "" then
		return cellId
	end
	return "Wilderness"
end

local function basePrice(target, destination)
	if target and target.cell and not target.cell.isExterior then
		return math.floor(numericGmst("fMagesGuildTravel", 10))
	end
	local travelMult = numericGmst("fTravelMult", 4000)
	local dist = distance(self.position, destination and destination.position, true)
	if travelMult ~= 0 then
		dist = dist / travelMult
	end
	return math.floor(dist)
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
---@return table[]
function M.collectRows(target)
	local info = M.serviceInfo(target)
	local rows = {}
	for index, destination in ipairs(info.destinations) do
		local price = math.max(1, basePrice(target, destination))
		rows[#rows + 1] = {
			index = index,
			destination = destination,
			cellId = destination.cellId,
			label = destinationLabel(destination),
			price = price,
			enabled = price <= info.playerGold,
		}
	end
	return rows
end

function M.travelHours(destination)
	local fTravelTimeMult = numericGmst("fTravelTimeMult", 16000)
	if fTravelTimeMult == 0 then
		return 0
	end
	return math.max(
		0,
		math.floor(distance(self.position, destination and destination.position, false) / fTravelTimeMult)
	)
end

M.GOLD_ID = GOLD_ID

return M
