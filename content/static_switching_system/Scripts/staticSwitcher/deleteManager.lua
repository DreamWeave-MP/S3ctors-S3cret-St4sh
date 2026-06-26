---@omw-context none

local TICKS_TO_DELETE = 3

---@class SSSDeleteManager
local DeleteManager = {
  ---@type ObjectDeleteData[]
  queue = {},
}
--- Adds an object to the delete queue, to be processed on another frame
---@param object openmw.GObject
function DeleteManager:addObjectToDeleteQueue(object, removeOrDisable)
  self.queue[#self.queue + 1] = {
    object = object,
    ticks = TICKS_TO_DELETE,
    removeOrDisable = removeOrDisable,
  }
end

function DeleteManager:processDeleteQueue()
  for i = #self.queue, 1, -1 do
    local objectInfo = self.queue[i]

    if objectInfo.ticks > 0 then
      objectInfo.ticks = objectInfo.ticks - 1
    else
      local object = objectInfo.object

      if objectInfo.removeOrDisable then
        if object.count > 0 and object:isValid() then
          object:remove()
          table.remove(self.queue, i)
        end
      else
        object.enabled = false
        table.remove(self.queue, i)
      end
    end
  end
end

function DeleteManager:queueIsEmpty()
  return next(self.queue) == nil
end
