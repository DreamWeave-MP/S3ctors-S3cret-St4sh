---@omw-context global

local types = require 'openmw.types'
local world = require 'openmw.world'

local GOLD_ID = 'gold_001'

local function validObject(object)
	return object and object.isValid and object:isValid()
end

local function dropItem(data)
	if type(data) ~= 'table' then
		return
	end
	local player = data.player
	local item = data.item
	local position = data.position
	local cellName = data.cellName
	local count = math.floor(tonumber(data.count) or 0)
	if not validObject(player) or not validObject(item) or type(cellName) ~= 'string' or not position or count < 1 then
		return
	end
	if item.parentContainer ~= player then
		return
	end

	local remaining = count
	local function dropFromStack(stack)
		if remaining < 1 or not validObject(stack) or stack.parentContainer ~= player then
			return
		end
		local stackCount = math.floor(tonumber(stack.count) or 0)
		if stackCount < 1 then
			return
		end
		local dropCount = math.min(remaining, stackCount)
		local dropped = stack
		if dropCount < stackCount then
			dropped = stack:split(dropCount)
		end
		if validObject(dropped) then
			dropped:teleport(cellName, position, { onGround = data.onGround ~= false })
			remaining = remaining - dropCount
		end
	end

	dropFromStack(item)
	if remaining < 1 then
		return
	end

	local recordId = item.recordId
	if not recordId then
		return
	end
	for _, stack in ipairs(types.Actor.inventory(player):getAll()) do
		if stack ~= item and stack.recordId == recordId then
			dropFromStack(stack)
			if remaining < 1 then
				return
			end
		end
	end
end

local function removeGold(player, price)
	local remaining = price
	local inventory = types.Actor.inventory(player)
	for _, stack in ipairs(inventory:findAll(GOLD_ID)) do
		if remaining < 1 then
			return true
		end
		if validObject(stack) then
			local take = math.min(remaining, math.floor(tonumber(stack.count) or 1))
			stack:remove(take)
			remaining = remaining - take
		end
	end
	return remaining < 1
end

local function destinationCell(cellId)
	if type(cellId) ~= 'string' or cellId == '' then
		return ''
	end
	local ok, cell = pcall(world.getCellById, cellId)
	if ok and cell then
		return cell
	end
	return cellId
end

local function resolvedCellName(cellId)
	local cell = destinationCell(cellId)
	if type(cell) == 'table' or type(cell) == 'userdata' then
		if type(cell.displayName) == 'string' and cell.displayName ~= '' then
			return cell.displayName
		end
		if type(cell.name) == 'string' and cell.name ~= '' then
			return cell.name
		end
	end
	return nil
end

local function resolveTravelCellNames(data)
	if type(data) ~= 'table' or not validObject(data.player) or type(data.cellIds) ~= 'table' then
		return
	end
	local names = {}
	for _, cellId in ipairs(data.cellIds) do
		if type(cellId) == 'string' and names[cellId] == nil then
			local name = resolvedCellName(cellId)
			if name then
				names[cellId] = name
			end
		end
	end
	data.player:sendEvent('S3UI_TravelCellNamesResolved', names)
end

local function requestTravelFollowers(data)
	if type(data) ~= 'table' or not validObject(data.player) then
		return
	end
	for _, actor in ipairs(world.activeActors) do
		if validObject(actor) and actor ~= data.player then
			actor:sendEvent('S3UI_CheckTravelFollower', { player = data.player, requestId = data.requestId })
		end
	end
end

local function travelFollowerCandidate(data)
	if type(data) ~= 'table' or not validObject(data.player) or not validObject(data.actor) then
		return
	end
	data.player:sendEvent('S3UI_TravelFollowerFound', { requestId = data.requestId, actor = data.actor })
end

local function addBarterGold(target, price)
	if not validObject(target) or not types.Actor.objectIsInstance(target) then
		return
	end
	local ok, current = pcall(types.Actor.getBarterGold, target)
	if ok and type(current) == 'number' then
		pcall(types.Actor.setBarterGold, target, current + price)
	end
end

local function executeTravel(data)
	if type(data) ~= 'table' then
		return
	end
	local player = data.player
	local price = math.max(1, math.floor(tonumber(data.price) or 0))
	if not (validObject(player) and data.position and type(data.cellId) == 'string') then
		return
	end
	local inventory = types.Actor.inventory(player)
	if inventory:countOf(GOLD_ID) < price then
		return
	end
	if not removeGold(player, price) then
		return
	end
	addBarterGold(data.target, price)
	if data.sourceExterior == true then
		local hours = math.max(0, math.floor(tonumber(data.hours) or 0))
		if hours > 0 then
			world.advanceTime(hours)
		end
	end
	if type(data.followers) == 'table' then
		for _, follower in ipairs(data.followers) do
			if validObject(follower) then
				follower:teleport(
					destinationCell(data.cellId),
					data.position,
					{ rotation = data.rotation, onGround = true }
				)
			end
		end
	end
	player:teleport(destinationCell(data.cellId), data.position, { rotation = data.rotation, onGround = true })
end

return {
	eventHandlers = {
		S3UI_DropItem = dropItem,
		S3UI_RequestTravelFollowers = requestTravelFollowers,
		S3UI_TravelFollowerCandidate = travelFollowerCandidate,
		S3UI_ResolveTravelCellNames = resolveTravelCellNames,
		S3UI_TravelExecute = executeTravel,
	},
}
