local gameSelf = require 'openmw.self'
local types = require 'openmw.types'

---@alias ActorType
---| 0 # Player
---| 1 # NPC
---| 2 # Creature
---| 3 # None

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end

  table.sort(a, f)
  local i = 0

  local iter = function()
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

local function alphabeticalParts(input)
  local inputType = type(input)
  if inputType ~= 'table' then
    error('Cannot sort something that isn\'t a table! ' .. type(input), 2)
  end

  local parts = {}
  local methodParts = {}
  local userDataParts = {}

  for key, value in pairsByKeys(input) do
    if type(value) == 'function' then
      methodParts[#methodParts + 1] = ('%s'):format(tostring(key))
    elseif type(value) == 'userdata' then
      userDataParts[#userDataParts + 1] = ('%s = %s'):format(
        tostring(key),
        tostring(value)
      )
    elseif key ~= '__instance' then
      parts[#parts + 1] = ('%s = %s'):format(
        tostring(key),
        tostring(value)
      )
    end
  end

  return (
    'S3GameGameSelf {\n Fields: { %s },\n Methods: { %s },\n UserData: { %s }\n}'):format(
    table.concat(parts, ', '),
    table.concat(methodParts, ', '),
    table.concat(userDataParts, ', ')
  )
end

local function instanceDisplay(instance)
  local nearby = require 'openmw.nearby'

  local resultString = alphabeticalParts(instance.__instance)
  for _, player in ipairs(nearby.players) do
    player:sendEvent('S3LFDisplay', resultString)
  end
end

local function instanceDistance(_, other)
  return (gameSelf.position - other.position):length()
end

---@type KeyBehaviors
local KeyBehavior = require 'openmw.storage'.globalSection 'S3lfColdStorage':get 'KeyBehavior'

--- Indexes fields of `type`, but not stats
local function indexTypeFields(instance, object, key)
  local typeValue = object.type[key]

  if not typeValue then return end

  if type(typeValue) ~= "function" or key == 'createRecordDraft' then
    rawset(instance, key, typeValue)

    return typeValue
  else
    local typeHandler = function(...)
      return typeValue(object, ...)
    end

    rawset(instance, key, typeHandler)

    return typeHandler
  end
end

--- Indexes record fields
local function indexRecordFields(instance, _, key)
  local record = rawget(instance, 'record')

  if not record then
    do
      local object = rawget(instance, 'object')
      record = object.type.records[object.recordId]
      rawset(instance, 'record', record)
    end
  end

  local recordValue = record[key]

  if not recordValue then return end

  rawset(instance, key, recordValue)

  return recordValue
end

--- Handle keys from the root gameObject, without special casing
local function indexObjectFields(instance, object, key)
  local objectValue = object[key]
  if objectValue == nil then return end

  rawset(instance, key, objectValue)
  return objectValue
end

--- Handle keys from the animation module
local function indexAnimationFields(instance, object, key)
  local animValue = require 'openmw.animation'[key]

  if not animValue then return end

  local insertKey = animValue

  if type(animValue) == 'function' then
    insertKey = function(...)
      return animValue(object, ...)
    end
  end

  rawset(instance, key, insertKey)

  return insertKey
end

local KeyHandlers
local function keyHandlers()
  KeyHandlers = KeyHandlers or {
    indexTypeFields,
    indexRecordFields,
    indexObjectFields,
    indexAnimationFields,
  }

  return KeyHandlers
end

local function getBoundingBox()
  return gameSelf:getBoundingBox()
end

local function sendObjectEvent(_, eventName, eventData)
  gameSelf:sendEvent(eventName, eventData)
end

---@type table<string, function>?
local FunctionsAsFields
local function functionsAsFields()
  if not FunctionsAsFields and not types.Player.objectIsInstance(gameSelf) then
    FunctionsAsFields = {
      bounds = getBoundingBox,
    }
  end

  return FunctionsAsFields
end

local function createS3lfInstance(gameObject)
  print('constructing new instance of s3lf for', tostring(gameObject))

  local actorType, myType = nil, gameSelf.type
  if not types.Actor.objectIsInstance(gameSelf) then
    actorType = 3
  elseif myType == types.Creature then
    actorType = 2
  elseif myType == types.NPC then
    actorType = 1
  elseif myType == types.Player then
    actorType = 0
  else
    error('Invalid actor type!!!!')
  end

  local objectCell = gameObject.cell

  ---@class S3lfObject
  local instance = {
    actorType = actorType,
    consoleLog = require 'scripts.s3.logmessage',
    display = instanceDisplay,
    distance = instanceDistance,
    getBoundingBox = getBoundingBox,
    object = gameObject,
    lObject = gameObject.object,
    sendEvent = sendObjectEvent,
  }

  if actorType < 3 then
    --- Table class designed to duplicate data out of OpenMW's userdata objects for faster indexing
    --- Only used on actor classes for performance reasons as mostly they're the only ones whom move and/or
    --- Are worth caching this stuff for due to sheer heat
    ---@class CellInfo
    instance.cellInfo = {
      displayName = objectCell.displayName,
      gridX = objectCell.gridX,
      gridY = objectCell.gridY,
      hasSky = objectCell.hasSky,
      hasWater = objectCell.hasWater,
      id = objectCell.id,
      isExterior = objectCell.isExterior,
      isFakeExterior = objectCell:hasTag('QuasiExterior'),
      name = objectCell.name,
      region = objectCell.region,
      waterLevel = objectCell.waterLevel,
    }

    instance.level = gameSelf.type.stats.level(gameSelf)

    do
      local MyStats = gameSelf.type.stats
      local StatFields = { 'ai', 'attributes', 'dynamic', }

      if actorType < 2 then
        table.insert(StatFields, 'skills')
      end

      for _, subTable in ipairs(StatFields) do
        local statFunctions = MyStats[subTable]

        for statName, statFunction in pairs(statFunctions) do
          instance[statName] = statFunction(gameSelf)
        end
      end
    end
  end

  if actorType == 0 then
    rawset(instance, 'cellsVisited', {})
    rawset(instance, 'cell', gameObject.cell)
    rawset(instance, 'position', gameObject.position)
  end

  --- The outer s3lf interface that is exposed to users is a userdata, edited to not really be the original thing
  --- Thus we keep a reference to the original instance inside of the instance so that when you use `:` notation for the respective functions they can pass the original instance
  --- table into the desired functions, instead of the read-only userdata exposed through the interface.
  --- It fixes things, I promise.
  --- Alternatively we could expose a metatable which *returns* the `instance` in its __index, but I don't know if I prefer that or not.
  --- Both options suck, I think.
  ---@private
  instance.__instance = instance

  local IGNORED_KEY, UNCACHEABLE_KEY = 0, 1
  setmetatable(instance, {
    __index = function(this, key)
      ---@type KeyBehavior?
      local behavior = KeyBehavior[key]

      if behavior == IGNORED_KEY then
        return
      elseif behavior == UNCACHEABLE_KEY then
        return gameSelf[key]
      end

      local impliedField = rawget(functionsAsFields(), key)
      if impliedField then return impliedField() end

      for _, handler in ipairs(keyHandlers()) do
        local result = handler(this, gameSelf, key)

        if result ~= nil then return result end
      end
    end,
    __name = 'S3LFOBJECT',
    __metatable = 'S3LFOBJECT',
  })

  return instance
end

local instance, Index, engineHandlers, eventHandlers

if types.Player.objectIsInstance(gameSelf) then
  eventHandlers, engineHandlers = {}, {}

  instance = createS3lfInstance(gameSelf)

  local CombatTargetTracker = {
    targetData = {},
    updateCombatants = function(self, combatantInfo)
      local shouldRemove = next(combatantInfo.targets) == nil

      local targetData, eventName = self.targetData, nil

      if shouldRemove then
        targetData[combatantInfo.actor.id] = nil
        eventName = 'S3CombatTargetRemoved'
      else
        targetData[combatantInfo.actor.id] = combatantInfo.actor
        eventName = 'S3CombatTargetAdded'
      end

      gameSelf:sendEvent(eventName, combatantInfo.actor)
    end,

    isInCombat = function(self)
      return next(self.targetData) ~= nil and require 'openmw.debug'.isAIEnabled()
    end,
  }

  FunctionsAsFields = {
    bounds = getBoundingBox,
    isInCombat = function()
      return CombatTargetTracker:isInCombat()
    end,
    targetData = function()
      --- FIXME: Use tableUtil's makeReadOnly function
      return rawget(CombatTargetTracker, 'targetData')
    end,
  }

  engineHandlers.onSave = function()
    return {
      targetData = rawget(CombatTargetTracker, 'targetData'),
      cellsVisited = rawget(instance, 'cellsVisited'),
    }
  end

  engineHandlers.onLoad = function(data)
    if not data then return end

    local targetData = rawget(data, 'targetData')
    if targetData then
      rawset(CombatTargetTracker, 'targetData', targetData)
    end

    local cellsVisited = rawget(data, 'cellsVisited')
    if cellsVisited then
      rawset(instance, 'cellsVisited', cellsVisited)
    end
  end

  engineHandlers.onUpdate = function()
    local currentPosition = gameSelf.position
    if rawget(instance, 'position') ~= currentPosition then rawset(instance, 'position', currentPosition) end

    local currentCell = gameSelf.cell
    if currentCell == rawget(instance, 'cell') then return end

    local currentCellId = currentCell.id

    local cellsVisited = rawget(instance, 'cellsVisited')
    local cellWasVisited = rawget(cellsVisited, currentCellId)
    if not cellWasVisited then rawset(cellsVisited, currentCellId, true) end

    rawset(instance, 'cell', currentCell)

    local cellInfo = assert(rawget(instance, 'cellInfo'), 'Failed to find cellInfo table in S3lf Instance!!!')

    rawset(cellInfo, 'displayName', currentCell.displayName)
    rawset(cellInfo, 'gridX', currentCell.gridX)
    rawset(cellInfo, 'gridY', currentCell.gridY)
    rawset(cellInfo, 'hasSky', currentCell.hasSky)
    rawset(cellInfo, 'hasWater', currentCell.hasWater)
    rawset(cellInfo, 'id', currentCell.id)
    rawset(cellInfo, 'isTrueExterior', currentCell.isExterior)
    rawset(cellInfo, 'isFakeExterior', currentCell:hasTag('QuasiExterior'))
    rawset(cellInfo, 'name', currentCell.name)
    rawset(cellInfo, 'region', currentCell.region)
    rawset(cellInfo, 'waterLevel', currentCell.waterLevel)

    gameSelf:sendEvent('S3LFCellChanged', currentCellId)
  end

  eventHandlers.S3LFDisplay = function(resultString)
    local ui = require 'openmw.ui'
    ui.printToConsole(resultString, ui.CONSOLE_COLOR.Success)
  end

  eventHandlers.OMWMusicCombatTargetsChanged = function(targetData)
    CombatTargetTracker:updateCombatants(targetData)
  end

  Index = instance
else
  Index = function(this, k)
    local s3lf = rawget(this, 's3lf')

    if not s3lf then
      s3lf = createS3lfInstance(gameSelf)
    end

    return s3lf[k]
  end
end

return {
  engineHandlers = engineHandlers,
  eventHandlers = eventHandlers,
  interfaceName = 's3lf',
  interface = setmetatable({}, { __index = Index, }
  ),
}
