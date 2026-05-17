local async = require('openmw.async')
local world = require('openmw.world')

local serializer = require('scripts.serializer.baseserializer'):new()

-- local currentTarget

local deletedTargets = {}
local newObjects = {}
local oldTargets = {}

local function deleteTarget(eventData)

  if not eventData.target then
    if deletedTargets[eventData.playerCell] then
      local deleteCell = deletedTargets[eventData.playerCell]
      table.remove(deleteCell, #deleteCell).enabled = true
    end
    return
  end

  serializer:preserveTarget(eventData, deletedTargets).enabled = false
end

local function scaleTarget(eventData)
  serializer:preserveTarget(eventData):setScale(eventData.data)
end

local function cloneTarget(eventData)

  if eventData.target and eventData.target.recordId == eventData.object.recordId then return end

  local newObject = world.createObject(eventData.object.recordId, 1)

  if eventData.target then serializer:preserveTarget(eventData, deletedTargets).enabled = false end

  newObject:teleport(eventData.cell, eventData.position, eventData.rotation)

  async:newUnsavableGameTimer(1, function()
                                serializer:preserveTarget({target = newObject}, newObjects)
  end)
end

local function grabTarget(eventData)
  if not eventData.target or not eventData.targetPos then return end

  local target = eventData.target

  target:teleport(target.cell.name, eventData.targetPos, target.rotation)

  serializer:preserveTarget(eventData)
end

local function rotateTarget(eventData)
  if not eventData.target or not eventData.rotation then return end

  local target = eventData.target

  target:teleport(target.cell.name, target.position, eventData.rotation)
end

return {
  interfaceName = "toolTime_g",
  interface = {
    deleted = deletedTargets,
    old = oldTargets,
    all = serializer.objects,
    serializer = serializer:new()
  },
  eventHandlers = {
    Delete = deleteTarget,
    Scale = scaleTarget,
    Clone = cloneTarget,
    Rotate = rotateTarget,
    Grab = grabTarget,
  },
  engineHandlers = {
    onSave = function() serializer:dumpAll() end
  }
}
