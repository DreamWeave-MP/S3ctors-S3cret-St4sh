---@omw-context menu|player
---@module 'scripts.h3.ui.updateQueue'

local SetMetatable = setmetatable

local FlushUpdates, PendingUpdates, WeakKeys = {}, {}, { __mode = 'k' }

local PendingCount, UpdateGeneration = 0, 0

local UpdatedElements = SetMetatable({}, WeakKeys)

---@param request H3UI.UpdateRequest
---@return nil
local function queue(request)
  if request.pending then return end

  request.pending = true

  PendingCount = PendingCount + 1
  PendingUpdates[PendingCount] = request
end

---@return nil
local function flush()
  if PendingCount == 0 then return end

  UpdateGeneration = UpdateGeneration + 1
  local generation = UpdateGeneration
  local count = PendingCount

  local current = PendingUpdates
  PendingUpdates = FlushUpdates
  FlushUpdates = current
  PendingCount = 0

  for index = 1, count do
    local request = current[index]
    current[index] = nil
    request.pending = false

    local element = request.resolveElement()

    if element and element.layout and UpdatedElements[element] ~= generation then
      UpdatedElements[element] = generation
      element:update()
    end
  end
end

return {
  queue = queue,
  flush = flush,
}
