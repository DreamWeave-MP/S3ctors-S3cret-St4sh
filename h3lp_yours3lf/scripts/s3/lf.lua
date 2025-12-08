local animation = require('openmw.animation')
local gameSelf = require('openmw.self')
local types = require('openmw.types')
local util = require 'openmw.util'

local LogMessage = require 'scripts.s3.logmessage'

local CombatTargetTracker = {}
local CellsVisited = {}

local noSelfInputFunctions = {
  ['createRecordDraft'] = true,
}

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
  assert(type(input) == 'table', 'Cannot sort something that isn\'t a table!')
  local parts = {}
  local methodParts = {}
  local userDataParts = {}

  for key, value in pairsByKeys(input) do
    if type(value) == 'function' then
      methodParts[#methodParts + 1] = string.format('%s'
      , tostring(key))
    elseif type(value) == 'userdata' then
      userDataParts[#userDataParts + 1] = string.format('%s = %s'
      , tostring(key)
      , tostring(value))
    else
      parts[#parts + 1] = string.format('%s = %s'
      , tostring(key)
      , tostring(value))
    end
  end

  return string.format('S3GameGameSelf {\n Fields: { %s },\n Methods: { %s },\n UserData: { %s }\n}'
  , table.concat(parts, ', ')
  , table.concat(methodParts, ', ')
  , table.concat(userDataParts, ', '))
end

local nearby = require('openmw.nearby')
local PlayerType = types.Player
local function instanceDisplay(instance)
  local resultString = alphabeticalParts(instance)
  for _, actor in pairs(nearby.actors) do
    if PlayerType.objectIsInstance(actor) then
      actor:sendEvent('S3LFDisplay', resultString)
    end
  end
end

local function getObjectType(object)
  if PlayerType.objectIsInstance(object) then
    return 'player'
  end

  local result, _ = object.type.records[object.recordId].__type.name:gsub('ESM::', '')
  return result:lower()
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

    if type(typeValue) ~= "function" or noSelfInputFunctions[key] then
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

    assert(type(target) == 'function', 'Expected a function for key: ' .. key)
    local result = target(actor)
    rawset(instance, key, result)
    return result
  end,

  --- Handle keys from the root gameObject, without special casing
  function(instance, object, key)
    local objectValue = object[key]

    if not objectValue then return end

    if not uncacheableKeys[key] then
      rawset(instance, key, objectValue)
    end

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

local ObjectHelpers = {}
local s3lfCache = {}

local validObjectTypes = {
  ['MWLua::LObject'] = true,
  ['MWLua::SelfObject'] = true,
}

function ObjectHelpers.From(gameObject)
  local typeName = gameObject.__type.name

  assert(validObjectTypes[typeName],
    'S3GameSelf.From is only compatible with GameObjects! You passed: ' .. typeName)

  if not s3lfCache[gameObject.id] then
    s3lfCache[gameObject.id] = ObjectHelpers.createInstance(gameObject)
  end

  return s3lfCache[gameObject.id]
end

function ObjectHelpers.distance(object1, object2)
  return (object1.position - object2.position):length()
end

function ObjectHelpers.createInstance(gameObject)
  local instance = {
    gameObject = gameObject,
    record = gameObject.type.records[gameObject.recordId],
    objectType = getObjectType(gameObject),
    From = ObjectHelpers.From,
    isActor = types.Actor.objectIsInstance(gameObject),
    isPlayer = types.Player.objectIsInstance(gameObject),
  }

  function instance.distance(object2)
    return ObjectHelpers.distance(gameObject, object2)
  end

  instance.display = function()
    instanceDisplay(instance)
  end

  setmetatable(instance, GameObjectWrapper._mt)

  return instance
end

local instance = ObjectHelpers.createInstance(gameSelf)

local eventHandlers = {
  Died = function()
    s3lfCache = {}
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

  local I = require 'openmw.interfaces'
  local prevCell = nil
  engineHandlers.onFrame = function()
    local currentCell = I.s3lf.cell
    if not currentCell then return end

    if currentCell ~= prevCell then
      gameSelf:sendEvent('S3LFCellChanged', currentCell.id)

      if not CellsVisited[currentCell.id] then CellsVisited[currentCell.id] = true end
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

  local debug = require 'openmw.debug'
  function CombatTargetTracker.isInCombat()
    return next(CombatTargetTracker.targetData) ~= nil and debug.isAIEnabled()
  end

  local ui = require('openmw.ui')

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
