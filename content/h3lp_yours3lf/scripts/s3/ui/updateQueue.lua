---@omw-context menu|player
---@module 'scripts.s3.ui.updateQueue'

local pendingUpdates = {}
local pendingCount = 0
local flushUpdates = {}
local updateGeneration = 0
local updatedElements = setmetatable({}, { __mode = 'k' })

local function queue(request)
  if request.pending then return end
  request.pending = true
  pendingCount = pendingCount + 1
  pendingUpdates[pendingCount] = request
end

local function flush()
  if pendingCount == 0 then return end

  updateGeneration = updateGeneration + 1
  local generation = updateGeneration
  local count = pendingCount

  local current = pendingUpdates
  pendingUpdates = flushUpdates
  flushUpdates = current
  pendingCount = 0

  for index = 1, count do
    local request = current[index]
    current[index] = nil
    request.pending = false

    local element = request.resolveElement()
    if element and element.layout and updatedElements[element] ~= generation then
      updatedElements[element] = generation
      element:update()
    end
  end
end

return {
  queue = queue,
  flush = flush,
}
