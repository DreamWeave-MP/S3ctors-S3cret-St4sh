local isGlobal = pcall(require, 'openmw.world')
if isGlobal then
  error('S3lf is not compatible with global scripts! Sorry!', 2)
end

local animation = require 'openmw.animation'
local debug
local gameSelf = require 'openmw.self'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local ui
local util = require 'openmw.util'

local concat, error, insert, ipairs, next, pairs, rawget, rawset, sort, tostring, type
= table.concat, error, table.insert, ipairs, next, pairs, rawget, rawset, table.sort, tostring, type

local LogMessage = require 'scripts.s3.logmessage'
local PlayerType = types.Player

if PlayerType.objectIsInstance(gameSelf) then
  debug = require 'openmw.debug'
  ui = require 'openmw.ui'
end

local CellsVisited = {}
local CombatTargetTracker = {}
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
  return (instance.gameObject.position - other.position):length()
end

local GameObjectWrapper = {}

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

local GameObjectKeyHandlers = {
  id = function(instance, gameObject, key)
    local id = gameObject.id
    rawset(instance, key, id)
    return id
  end,
  object = function(_, gameObject, _)
    return gameObject
  end,
  --- Not sure if you actually work or not!
  sendEvent = function(instance, gameObject, key)
    rawset(instance, key, function(...)
      return gameObject:sendEvent(...)
    end)
  end,
}

local knownKeys = {
  ConsoleLog = function()
    return LogMessage
  end,
  cellsVisited = function()
    return CellsVisited
  end,
  combatTargets = function()
    return util.makeReadOnly(CombatTargetTracker.targetData)
  end,
  isInCombat = function()
    return CombatTargetTracker.isInCombat()
  end,
}

local keyHandlers = {

  --- Handle uncacheable keys from the root gameObject, which later are skipped
  function(_, object, key)
    if uncacheableKeys[key] then return object[key] end
  end,

  --- Indexes fields already found, always runs first
  function(instance, _, key)
    local cached = rawget(instance, key)
    if cached ~= nil then return cached end
  end,

  --- Indexes fields of GameObject which are special cased
  function(instance, object, key)
    local keyHandler = GameObjectKeyHandlers[key]

    if not keyHandler then return end

    return keyHandler(instance, object, key)
  end,

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

  --- Indexes fields of ActorStats
  function(instance, actor, key)
    if not rawget(instance, 'isActor') then return end

    local stats = actor.type.stats

    local target = stats.dynamic[key]
        or stats.attributes[key]
        or (stats.skills and stats.skills[key])
        or stats[key]
        or stats.ai[key]

    if not target then return end

    if type(target) ~= 'function' then
      error('Expected a function for stats key: ' .. key)
    end

    local result = target(actor)
    rawset(instance, key, result)

    return result
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

  --- Handles 'known keys', hardcoded ones with utility functions etc that should always exist, but run last because they're relatively unlikely searches.
  function(instance, _, key)
    if not rawget(instance, 'isPlayer') then return end

    local knownKey = knownKeys[key]

    if knownKey then return knownKey() end
  end,
}

GameObjectWrapper._mt = {
  __index = function(instance, key)
    if ignoredBaseKeys[key] then return end

    local object = rawget(instance, 'gameObject')

    for _, handler in ipairs(keyHandlers) do
      local result = handler(instance, object, key)

      if result ~= nil then return result end
    end
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

function ObjectHelpers.createInstance(gameObject)
  ---@class S3lfObject
  local instance = {
    gameObject = gameObject,
    record = gameObject.type.records[gameObject.recordId],
    From = ObjectHelpers.From,
    isActor = types.Actor.objectIsInstance(gameObject),
    isPlayer = types.Player.objectIsInstance(gameObject),
    display = instanceDisplay,
    distance = instanceDistance,
  }

  --- The outer s3lf interface that is exposed to users is a userdata, edited to not really be the original thing
  --- Thus we keep a reference to the original instance inside of the instance so that when you use `:` notation for the respective functions they can pass the original instance
  --- table into the desired functions, instead of the read-only userdata exposed through the interface.
  --- It fixes things, I promise.
  --- Alternatively we could expose a metatable which *returns* the `instance` in its __index, but I don't know if I prefer that or not.
  --- Both options suck, I think.
  ---@private
  instance.__instance = instance

  setmetatable(instance, GameObjectWrapper._mt)

  return instance
end

local instance = ObjectHelpers.createInstance(gameSelf)

local eventHandlers = {
  Died = function()
    S3lfCache = {}
  end,
}
local engineHandlers = {}

if PlayerType.objectIsInstance(gameSelf) then
  CombatTargetTracker.targetData = {}

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

  local prevCell

  engineHandlers.onUpdate = function()
    local currentCell = gameSelf.cell.id

    if currentCell ~= prevCell then
      gameSelf:sendEvent('S3LFCellChanged', currentCell)

      if not CellsVisited[currentCell] then CellsVisited[currentCell] = true end
    end

    prevCell = currentCell
  end

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
  interface = instance,
}
