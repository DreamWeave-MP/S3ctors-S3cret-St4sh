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
}

local function actorHandler(instance, actor, key)
  local stats = actor.type.stats

  if key == 'level' then
    local level = stats.level(actor)
    rawset(instance, key, level)
    return level
  end

  local target = stats.dynamic[key] or stats.attributes[key] or (stats.skills and stats.skills[key]) or stats.ai[key]
  if target then
    assert(type(target) == 'function', 'Expected a function for key: ' .. key)
    local result = target(actor)
    rawset(instance, key, result)
    return result
  end
end

GameObjectWrapper._mt = {
  __index = function(instance, key)
    if key == 'ConsoleLog' then
      return LogMessage
    end

    local cached = rawget(instance, key)

    if cached then
      return cached
    end

    local gameObject = rawget(instance, 'gameObject')

    if types.Player.objectIsInstance(gameObject) then
      if key == 'combatTargets' then
        return util.makeReadOnly(CombatTargetTracker.targetData)
      elseif key == 'isInCombat' then
        return CombatTargetTracker.isInCombat()
      elseif key == 'cellsVisited' then
        return CellsVisited
      end
    end

    local keyHandler = GameObjectKeyHandlers[key]
    if keyHandler then
      return keyHandler(instance, gameObject, key)
    end

    local typeValue = gameObject.type[key]
    if typeValue then
      if type(typeValue) ~= "function" or noSelfInputFunctions[key] then
        rawset(instance, key, typeValue)
        return typeValue
      else
        local typeHandler = function(...)
          return typeValue(gameObject, ...)
        end

        rawset(instance, key, typeHandler)

        return typeHandler
      end
    end

    local recordValue = rawget(instance, 'record')[key]
    if recordValue then
      rawset(instance, key, recordValue)
      return recordValue
    end

    if types.Actor.objectIsInstance(gameObject) then
      local actorValue = actorHandler(instance, gameObject, key)
      if actorValue then return actorValue end
    end

    local animValue = animation[key]
    if animValue then
      if type(animValue) == 'function' then
        local animHandler = function(...)
          return animValue(gameObject, ...)
        end

        rawset(instance, key, animHandler)

        return animHandler
      else
        rawset(instance, key, animValue)
        return animValue
      end
    end

    local objectValue = gameObject[key]
    if ignoredBaseKeys[key] or not objectValue then return end

    if not uncacheableKeys[key] then
      rawset(instance, key, objectValue)
    end

    return objectValue
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

  function CombatTargetTracker.isInCombat()
    return next(CombatTargetTracker.targetData) ~= nil
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
