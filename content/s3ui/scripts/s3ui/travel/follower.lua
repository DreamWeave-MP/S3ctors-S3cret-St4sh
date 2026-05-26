---@omw-context local

local core = require 'openmw.core'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local types = require 'openmw.types'

local MAX_TRAVEL_FOLLOWER_DISTANCE2 = 800 * 800

local function validObject(object)
	return object and object.isValid and object:isValid()
end

local function sameObject(a, b)
	return validObject(a) and validObject(b) and a.id == b.id
end

local function isTravelFollowerOf(player)
	if not validObject(player) or not types.Actor.objectIsInstance(self) then
		return false
	end
	if (self.position - player.position):length2() > MAX_TRAVEL_FOLLOWER_DISTANCE2 then
		return false
	end
	if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
		return false
	end
	local package = I.AI.getActivePackage()
	if not package or package.type ~= 'Follow' then
		return false
	end
	return sameObject(package.target, player)
end

local function checkTravelFollower(data)
	if type(data) ~= 'table' or not isTravelFollowerOf(data.player) then
		return
	end
	core.sendGlobalEvent('S3UI_TravelFollowerCandidate', {
		player = data.player,
		actor = self.object or self,
		requestId = data.requestId,
	})
end

return {
	eventHandlers = {
		S3UI_CheckTravelFollower = checkTravelFollower,
	},
}
