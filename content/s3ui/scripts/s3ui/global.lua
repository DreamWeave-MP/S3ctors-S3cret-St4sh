---@omw-context global

local types = require("openmw.types")

local function validObject(object)
	return object and object.isValid and object:isValid()
end

local function dropItem(data)
	if type(data) ~= "table" then
		return
	end
	local player = data.player
	local item = data.item
	local position = data.position
	local cellName = data.cellName
	local count = math.floor(tonumber(data.count) or 0)
	if not validObject(player) or not validObject(item) or type(cellName) ~= "string" or not position or count < 1 then
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

return {
	eventHandlers = {
		S3UI_DropItem = dropItem,
	},
}
