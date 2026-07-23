---@omw-context none

local TICKS_TO_DELETE = 3

local next, remove = next, table.remove

--- Adds an object to the delete queue, to be processed on another frame
---@param object openmw.GObject
---@param removeOrDisable boolean true removes the object, false disables it
local function addObjectToDeleteQueue(self, object, removeOrDisable)
	self.queue[#self.queue + 1] = {
		object = object,
		ticks = TICKS_TO_DELETE,
		removeOrDisable = removeOrDisable,
	}
end

--- Removes pending queue entries for an object, optionally filtered by operation.
---@param targetObject openmw.GObject
---@param removeOrDisable boolean? true removes, false disables, nil removes either operation
local function removeObjectFromDeleteQueue(self, targetObject, removeOrDisable)
	local targetId = targetObject.id

	for i = #self.queue, 1, -1 do
		local objectInfo = self.queue[i]
		local queuedObject = objectInfo.object

		if
				queuedObject:isValid()
				and queuedObject.id == targetId
				and (removeOrDisable == nil or objectInfo.removeOrDisable == removeOrDisable)
		then
			remove(self.queue, i)
		end
	end
end

--- Processes delayed object deletion/disable work and removes completed queue entries.
local function processDeleteQueue(self)
	for i = #self.queue, 1, -1 do
		local objectInfo = self.queue[i]

		if objectInfo.ticks > 0 then
			objectInfo.ticks = objectInfo.ticks - 1
		else
			local object = objectInfo.object

			if objectInfo.removeOrDisable then
				if object:isValid() and object.count > 0 then
					object:remove()
				end

				remove(self.queue, i)
			else
				if object:isValid() and object.count > 0 then
					object.enabled = false
				end

				remove(self.queue, i)
			end
		end
	end
end

---@return boolean isEmpty whether the delete queue has no pending objects
local function queueIsEmpty(self)
	return next(self.queue) == nil
end

---@type SSSDeleteManager
return {
	addObjectToDeleteQueue = addObjectToDeleteQueue,
	processDeleteQueue = processDeleteQueue,
	queueIsEmpty = queueIsEmpty,
	removeObjectFromDeleteQueue = removeObjectFromDeleteQueue,
	queue = {},
}
