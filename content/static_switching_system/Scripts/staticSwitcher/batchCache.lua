---@omw-context global

---@type SSSBatchCache

local types  = require 'openmw.types'
local core   = require 'openmw.core'
local world  = require 'openmw.world'

local Player = world.players[1]

local Cache  = {}

local clear
---@diagnostic disable-next-line: undefined-field
clear        = table.clear or function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local function clearCache()
	clear(Cache)
end

local function playerQuests()
	local quests = Cache._playerQuests
	if not quests then
		quests = types.Player.quests(Player)
		Cache._playerQuests = quests
	end
	return quests
end

local function playerEquipment()
	local equipment = Cache._playerEquipment
	if not equipment then
		equipment = Player:getEquipment()
		Cache._playerEquipment = equipment
	end
	return equipment
end

local function currentWeather(cell)
	local byCell = Cache._currentWeather
	if not byCell then
		byCell = {}
		Cache._currentWeather = byCell
	end

	local weather = byCell[cell]
	if weather == nil then
		weather = core.weather.getCurrent(cell)
		byCell[cell] = weather or false
	end

	return weather ~= false and weather or nil
end

local function attributeStat(object, attrId)
	object = object or Player
	local byObject = Cache._attrStats
	if not byObject then
		byObject = {}
		Cache._attrStats = byObject
	end
	local byAttr = byObject[object.id]
	if not byAttr then
		byAttr = {}
		byObject[object.id] = byAttr
	end
	local stat = byAttr[attrId]
	if not stat then
		local stats = object.type.stats
		stat = stats.attributes[attrId](object)
		byAttr[attrId] = stat
	end
	return stat
end

local function skillStat(object, skillId)
	object = object or Player
	local byObject = Cache._skillStats
	if not byObject then
		byObject = {}
		Cache._skillStats = byObject
	end
	local bySkill = byObject[object.id]
	if not bySkill then
		bySkill = {}
		byObject[object.id] = bySkill
	end
	local stat = bySkill[skillId]
	if not stat then
		local stats = object.type.stats
		stat = stats.skills[skillId](object)
		bySkill[skillId] = stat
	end
	return stat
end

local function dynamicStat(object, statName)
	object = object or Player
	local byObject = Cache._dynStats
	if not byObject then
		byObject = {}
		Cache._dynStats = byObject
	end
	local byStat = byObject[object.id]
	if not byStat then
		byStat = {}
		byObject[object.id] = byStat
	end
	local stat = byStat[statName]
	if not stat then
		local stats = object.type.stats
		stat = stats.dynamic[statName](object)
		byStat[statName] = stat
	end
	return stat
end

local function actorSpells(object)
	object = object or Player
	local spellsFn = object.type.spells
	if not spellsFn then
		return
	end

	local byObject = Cache._actorSpells
	if not byObject then
		byObject = {}
		Cache._actorSpells = byObject
	end
	local spells = byObject[object.id]
	if not spells then
		spells = spellsFn(object)
		byObject[object.id] = spells
	end
	return spells
end

local function globalVariables()
	local byPlayer = Cache._globals
	if not byPlayer then
		byPlayer = {}
		Cache._globals = byPlayer
	end
	local globals = byPlayer[Player.id]
	if not globals then
		globals = world.mwscript.getGlobalVariables(Player)
		byPlayer[Player.id] = globals
	end
	return globals
end

return {
	clear = clearCache,
	playerQuests = playerQuests,
	playerEquipment = playerEquipment,
	currentWeather = currentWeather,
	attributeStat = attributeStat,
	skillStat = skillStat,
	dynamicStat = dynamicStat,
	actorSpells = actorSpells,
	globalVariables = globalVariables,
}
