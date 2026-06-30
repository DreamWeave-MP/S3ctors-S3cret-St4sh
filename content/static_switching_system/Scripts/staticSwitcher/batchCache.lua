---@omw-context global

---@type SSSBatchCache
---@field clear fun() Clears all cached values between activation batches.
---@field playerQuests fun(): table Returns the player's quest table, cached per batch.
---@field playerEquipment fun(): table Returns the player's equipment table, cached per batch.
---@field currentWeather fun(cell: openmw.core.Cell): openmw.core.WeatherRecord? Returns current weather for a cell, cached per batch.

local types = require 'openmw.types'
local core = require 'openmw.core'

local Player = require('openmw.world').players[1]

local Cache = {}

local clear
if table.clear then
	clear = table.clear
else
	clear = function(t)
		for k in pairs(t) do
			t[k] = nil
		end
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

return {
	clear = clearCache,
	playerQuests = playerQuests,
	playerEquipment = playerEquipment,
	currentWeather = currentWeather,
}
