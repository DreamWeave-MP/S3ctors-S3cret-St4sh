local concat, error, insert, ipairs, next, pairs, pcall, rawget, rawset, require, setmetatable, sort, tostring, type =
    table.concat, error, table.insert, ipairs, next, pairs, pcall, rawget, rawset, require, setmetatable, table.sort,
    tostring, type

local animation = require 'openmw.animation'
local debug
local gameSelf = require 'openmw.self'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local ui
local util = require 'openmw.util'

local isGlobal = pcall(require, 'openmw.world')
if isGlobal then
  error('S3lf is not compatible with global scripts! Sorry!', 2)
end

local LogMessage = require 'scripts.s3.logmessage'

local isActor, isCreature, isNPC, isPlayer =
    types.Actor.objectIsInstance(gameSelf), types.Creature.objectIsInstance(gameSelf),
    types.NPC.objectIsInstance(gameSelf), types.Player.objectIsInstance(gameSelf)

if isPlayer then
  debug = require 'openmw.debug'
  ui = require 'openmw.ui'
end

local CellsVisited = {}

local CombatTargetTracker
do
  if isPlayer then
    CombatTargetTracker = {}
    CombatTargetTracker.targetData = {}

    function CombatTargetTracker:updateCombatants(combatantInfo)
      local shouldRemove = next(combatantInfo.targets) == nil

      local eventName
      if shouldRemove then
        self.targetData[combatantInfo.actor.id] = nil
        eventName = 'S3CombatTargetRemoved'
      else
        self.targetData[combatantInfo.actor.id] = combatantInfo.actor
        eventName = 'S3CombatTargetAdded'
      end

      gameSelf:sendEvent(eventName, combatantInfo.actor)
    end

    function CombatTargetTracker.isInCombat()
      return next(CombatTargetTracker.targetData) ~= nil and debug.isAIEnabled()
    end
  end
end

local ObjectHelpers = {}
local S3lfCache = {}

local NoSelfInputFunctions = {
  ['createRecordDraft'] = true,
}

local ValidObjectTypes = {
  ['MWLua::LObject'] = true,
  ['MWLua::SelfObject'] = true,
}

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do insert(a, n) end

  sort(a, f)
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
    concat(parts, ', '),
    concat(methodParts, ', '),
    concat(userDataParts, ', ')
  )
end

local function instanceDisplay(instance)
  local resultString = alphabeticalParts(instance.__instance)
  for _, player in ipairs(nearby.players) do
    player:sendEvent('S3LFDisplay', resultString)
  end
end

local function instanceDistance(instance, other)
  return (instance.object.position - other.position):length()
end

local ignoredBaseKeys = {
  baseType = true,
  stats = true,
  type = true,
}

local uncacheableKeys = {
  cell = true,
  count = true,
  enabled = true,
  owner = true,
  parentContainer = true,
  position = true,
  rotation = true,
  scale = true,
}

local keyHandlers = {

  --- Indexes fields of `type`, but not stats
  function(instance, object, key)
    local typeValue = object.type[key]

    if not typeValue then return end

    if type(typeValue) ~= "function" or NoSelfInputFunctions[key] then
      rawset(instance, key, typeValue)

      return typeValue
    else
      local typeHandler = function(...)
        return typeValue(object, ...)
      end

      rawset(instance, key, typeHandler)

      return typeHandler
    end
  end,

  --- Indexes record fields
  function(instance, _, key)
    local recordValue = rawget(instance, 'record')[key]

    if not recordValue then return end

    rawset(instance, key, recordValue)

    return recordValue
  end,

  --- Handle keys from the root gameObject, without special casing
  function(instance, object, key)
    local objectValue = object[key]
    if objectValue == nil then return end

    rawset(instance, key, objectValue)
    return objectValue
  end,

  --- Handle keys from the animation module
  function(instance, object, key)
    local animValue = animation[key]

    if not animValue then return end

    local insertKey = animValue

    if type(animValue) == 'function' then
      insertKey = function(...)
        return animValue(object, ...)
      end
    end

    rawset(instance, key, insertKey)

    return insertKey
  end,
}

function ObjectHelpers.From(gameObject)
  local typeName = gameObject.__type.name

  if not ValidObjectTypes[typeName] then
    error('S3GameSelf.From is only compatible with GameObjects! You passed: ' .. typeName, 2)
  end

  local objectId = gameObject.id
  if not S3lfCache[objectId] then
    S3lfCache[objectId] = ObjectHelpers.createInstance(gameObject)
  end

  return S3lfCache[objectId]
end

function ObjectHelpers.distance(object1, object2)
  return (object1.position - object2.position):length()
end

---@type table<string, function>
local FunctionsAsFields = {}

if isPlayer then
  FunctionsAsFields.isInCombat = function()
    return CombatTargetTracker.isInCombat()
  end

  FunctionsAsFields.targetData = function()
    return util.makeReadOnly(rawget(CombatTargetTracker, 'targetData'))
  end
end

local GameObjectMeta = {
  __index = function(instance, key)
    if rawget(ignoredBaseKeys, key) then return end

    local object = rawget(instance, 'object')

    local keyIsUncacheable = rawget(uncacheableKeys, key)

    if not keyIsUncacheable then
      local cached = rawget(instance, key)
      if cached ~= nil then return cached end
    else
      return object[key]
    end

    local impliedField = rawget(FunctionsAsFields, key)
    if impliedField then return impliedField() end

    for _, handler in ipairs(keyHandlers) do
      local result = handler(instance, object, key)

      if result ~= nil then return result end
    end
  end,
}

local function sendObjectEvent(instance, eventName, eventData)
  rawget(instance, 'object'):sendEvent(eventName, eventData)
end

function ObjectHelpers.createInstance(gameObject)
  local objectCell = gameObject.cell
  ---@class S3lfObject
  local instance = {
    cell = gameObject.cell,
    --- Table class designed to duplicate data out of OpenMW's userdata objects for faster indexing
    ---@class CellInfo
    cellInfo = {
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
    },
    consoleLog = LogMessage,
    display = instanceDisplay,
    distance = instanceDistance,
    ---@private
    id = gameObject.id,
    isActor = isActor,
    isCreature = isCreature,
    isNPC = isNPC,
    isPlayer = isPlayer,
    object = gameObject,
    position = gameObject.position,
    record = gameObject.type.records[gameObject.recordId],
    sendEvent = sendObjectEvent,
    From = ObjectHelpers.From,
  }

  if isActor then
    instance.level = gameSelf.type.stats.level(gameSelf)

    if not isNPC and not isCreature then
      error('How am I not neither an NPC nor creature??????? ' .. tostring(gameSelf))
    end

    do
      local MyStats = gameSelf.type.stats
      local StatFields = { 'ai', 'attributes', 'dynamic', }

      if isNPC then
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

  if isPlayer then
    instance.cellsVisited = CellsVisited
  end

  --- The outer s3lf interface that is exposed to users is a userdata, edited to not really be the original thing
  --- Thus we keep a reference to the original instance inside of the instance so that when you use `:` notation for the respective functions they can pass the original instance
  --- table into the desired functions, instead of the read-only userdata exposed through the interface.
  --- It fixes things, I promise.
  --- Alternatively we could expose a metatable which *returns* the `instance` in its __index, but I don't know if I prefer that or not.
  --- Both options suck, I think.
  ---@private
  instance.__instance = instance

  setmetatable(instance, GameObjectMeta)

  return instance
end

local Instance = ObjectHelpers.createInstance(gameSelf)
local eventHandlers = {}
local engineHandlers = {}

if isPlayer then
  engineHandlers.onSave = function()
    return {
      targetData = CombatTargetTracker.targetData,
      cellsVisited = CellsVisited,
    }
  end

  engineHandlers.onLoad = function(data)
    if not data then return end

    if data.targetData then
      CombatTargetTracker.targetData = data.targetData
    end

    if data.cellsVisited then
      CellsVisited = data.cellsVisited
    end
  end

  engineHandlers.onUpdate = function()
    local currentPosition = gameSelf.position
    if rawget(Instance, 'position') ~= currentPosition then rawset(Instance, 'position', currentPosition) end

    local currentCell = gameSelf.cell
    if currentCell == rawget(Instance, 'cell') then return end

    local currentCellId = currentCell.id

    local cellVisited = rawget(CellsVisited, currentCellId)
    if not cellVisited then rawset(CellsVisited, currentCellId, true) end

    rawset(Instance, 'cell', currentCell)

    local cellInfo = assert(rawget(Instance, 'cellInfo'), 'Failed to find cellInfo table in S3lf Instance!!!')

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
    ui.printToConsole(resultString, ui.CONSOLE_COLOR.Success)
  end

  eventHandlers.OMWMusicCombatTargetsChanged = function(targetData)
    CombatTargetTracker:updateCombatants(targetData)
  end
end

return {
  engineHandlers = engineHandlers,
  eventHandlers = eventHandlers,
  interfaceName = 's3lf',
  interface = Instance,
}
