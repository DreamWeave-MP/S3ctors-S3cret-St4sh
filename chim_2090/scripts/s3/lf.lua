local gameSelf = require('openmw.self')
local types = require('openmw.types')

local noSelfInputFunctions = {
  ['createRecordDraft'] = true,
}

local function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0
  local iter = function ()
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
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

  return string.format('S3GameGameSelf{ Fields: { %s }, Methods: { %s }, UserData: { %s } }'
                       , table.concat(parts, ', ')
                       , table.concat(methodParts, ', ')
                       , table.concat(userDataParts, ', '))
end

local GameObjectWrapper = {}

GameObjectWrapper._mt = {
  __index = function(instance, key)
    local gameObject = rawget(instance, 'gameObject')
    -- There's a name conflict between `gameObject.id` and `record.id`
    -- since gameObject.recordId is a thing, gameObject.id always wins over record.id
    if key == 'id' then
      local id = gameObject.id
      rawset(instance, key, id)
      return id
    -- Record function does whole-ass map lookups which are slow, so hardcode it out
    elseif key == 'record' then
      local record = gameObject.type.records[gameObject.recordId]
      rawset(instance, key, record)
      return record
    elseif key == 'object' then
      return gameObject
    elseif key == 'baseType' or key == 'type' or key == 'stats' then
      return nil
    end

    local isActor = types.Actor.objectIsInstance(gameObject)
    local isNPC = types.NPC.objectIsInstance(gameObject)
    local record = rawget(instance, 'record')
    if record == nil then
      record = gameObject.type.records[gameObject.recordId]
      rawset(instance, 'record', record)
    end
    local recordValue = record[key]
    local stats = gameObject.type.stats

    if gameObject.type[key] then
      local value = gameObject.type[key]
      if type(value) ~= "function" or noSelfInputFunctions[key] then
        rawset(instance, key, value)
      else
        rawset(instance, key, function(...) return value(gameObject, ...) end)
      end
    elseif recordValue then
      rawset (instance, key, recordValue)
    elseif isNPC and stats.skills[key] then
      rawset(instance, key, stats.skills[key](gameObject))
    elseif isActor and key == 'level' then
      rawset(instance, key, stats.level(gameObject))
    elseif isActor and stats.ai[key] then
      rawset(instance, key, stats.ai[key](gameObject))
    elseif isActor and stats.attributes[key] then
      rawset(instance, key, stats.attributes[key](gameObject))
    elseif isActor and stats.dynamic[key] then
      rawset(instance, key, stats.dynamic[key](gameObject))
    elseif gameObject[key] then
      rawset(instance, key, gameObject[key])
    end
    return rawget(instance, key)
  end,
  __tostring = alphabeticalParts,
  __call = alphabeticalParts
}

local function From(gameObject)
  local instance = { gameObject = gameObject }
  setmetatable(instance, GameObjectWrapper._mt)
  return instance
end

local instance = { gameObject = gameSelf, From = From }
setmetatable(instance, GameObjectWrapper._mt)
return instance
