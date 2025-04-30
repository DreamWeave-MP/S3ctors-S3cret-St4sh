local animation = require('openmw.animation')
local gameSelf = require('openmw.self')
local types = require('openmw.types')

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
  local result, _ = object.type.records[object.recordId].__type.name:gsub('ESM::', '')
  return result:lower()
end


local GameObjectWrapper = {}

local function nullHandler() end

local GameObjectKeyHandlers = {
  id = function(instance, gameObject, key)
    local id = gameObject.id
    rawset(instance, key, id)
    return id
  end,
  object = function(_, gameObject, _)
    return gameObject
  end,
  baseType = nullHandler,
  stats = nullHandler,
  type = nullHandler,
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
    local cached = rawget(instance, key)

    if cached then
      return cached
    end

    local gameObject = rawget(instance, 'gameObject')

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
    if objectValue then
      rawset(instance, key, objectValue)
      return objectValue
    end
  end,
}

local ObjectHelpers = {}

function ObjectHelpers.From(gameObject)
  local typeName = gameObject.__type.name

  assert(typeName == 'MWLua::LObject',
    'S3GameSelf.From is only compatible with Local GameObjects! You passed: ' .. typeName)

  return ObjectHelpers.createInstance(gameObject)
end

function ObjectHelpers.distance(object1, object2)
  return (object1.position - object2.position):length()
end

function ObjectHelpers.createInstance(gameObject)
  local instance = {
    gameObject = gameObject,
    record = gameObject.type.records[gameObject.recordId],
    From = ObjectHelpers.From,
  }

  function instance.distance(object2)
    return ObjectHelpers.distance(gameObject, object2)
  end

  instance.display = function()
    instanceDisplay(instance)
  end

  instance.objectType = function()
    return getObjectType(gameObject)
  end

  setmetatable(instance, GameObjectWrapper._mt)

  return instance
end

local instance = ObjectHelpers.createInstance(gameSelf)


local eventHandlers = {}

if PlayerType.objectIsInstance(gameSelf) then
  local ui = require('openmw.ui')
  eventHandlers.S3LFDisplay = function(resultString)
    ui.printToConsole(resultString, ui.CONSOLE_COLOR.Success)
  end
end

return {
  eventHandlers = eventHandlers,
  interfaceName = 's3lf',
  interface = instance,
}
