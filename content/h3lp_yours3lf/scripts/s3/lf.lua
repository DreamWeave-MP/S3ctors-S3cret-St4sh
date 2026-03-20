---@alias ActorType
---| 0 # Player
---| 1 # NPC
---| 2 # Creature
---| 3 # None

local animation = require 'openmw.animation'
local gameSelf = require 'openmw.self'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local util = require 'openmw.util'

local localPlayers = nearby.players

local rawget, rawset, type = rawget, rawset, type

---@type KeyBehaviors
local KeyBehavior = require 'openmw.storage'.globalSection 'S3lfColdStorage':get 'KeyBehavior'

---@class S3lfObject
---@field actorType ActorType
local instance = {
  consoleLog = require 'scripts.s3.logmessage',
}

local sortedPairs = require 'scripts.s3.table'.sortedPairs

local function alphabeticalParts()
  local inputType = type(instance)
  if inputType ~= 'table' then
    error('Cannot sort something that isn\'t a table! ' .. type(instance), 2)
  end

  local parts = {}
  local methodParts = {}
  local userDataParts = {}

  for key, value in sortedPairs(instance) do
    if type(value) == 'function' then
      methodParts[#methodParts + 1] = ('%s'):format(tostring(key))
    elseif type(value) == 'userdata' then
      userDataParts[#userDataParts + 1] = ('%s = %s'):format(
        tostring(key),
        tostring(value)
      )
    else
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

local function instanceDisplay()
  local resultString = alphabeticalParts()

  for _, player in ipairs(localPlayers) do
    player:sendEvent('S3LFDisplay', resultString)
  end
end

function instance.distance(other)
  return (gameSelf.position - other.position):length()
end

function instance.sendObjectEvent(eventName, eventData)
  gameSelf:sendEvent(eventName, eventData)
end

--- Indexes fields of `type`, but not stats
local function indexTypeFields(key)
  local typeValue = gameSelf.type[key]

  if not typeValue then return end

  if type(typeValue) ~= "function" or key == 'createRecordDraft' then
    rawset(instance, key, typeValue)

    return typeValue
  else
    local typeHandler = function(...)
      return typeValue(gameSelf, ...)
    end

    rawset(instance, key, typeHandler)

    return typeHandler
  end
end

--- Indexes record fields
local function indexRecordFields(key)
  local record = rawget(instance, 'record')

  if not record then
    do
      record = gameSelf.type.records[gameSelf.recordId]
      rawset(instance, 'record', record)
    end
  end

  local recordValue = record[key]

  if not recordValue then return end

  rawset(instance, key, recordValue)

  return recordValue
end

--- Handle keys from the root gameObject, without special casing
local function indexObjectFields(key)
  local objectValue = gameSelf[key]
  if objectValue == nil then return end

  rawset(instance, key, objectValue)
  return objectValue
end

--- Handle keys from the animation module
local function indexAnimationFields(key)
  local animValue = animation[key]

  if animValue == nil then return end

  local insertKey = animValue

  if type(animValue) == 'function' then
    insertKey = function(...)
      return animValue(gameSelf, ...)
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

do
  local actorType, myType = nil, gameSelf.type
  if not types.Actor.objectIsInstance(gameSelf) then
    instance.actorType = 3
  elseif myType == types.Creature then
    instance.actorType = 2
  elseif myType == types.NPC then
    instance.actorType = 1
  elseif myType == types.Player then
    instance.actorType = 0
  else
    error('Invalid actor type!!!!')
  end


  if actorType < 3 then
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
    rawset(instance, 'cell', gameSelf.cell)
  end

  local IGNORED_KEY, UNCACHEABLE_KEY = 0, 1
  setmetatable(instance, {
    __index = function(_, key)
      ---@type KeyBehavior?
      local behavior = KeyBehavior[key]

      if behavior == IGNORED_KEY then
        return
      elseif behavior == UNCACHEABLE_KEY then
        return gameSelf[key]
      end

      if key == 'bounds' then
        return gameSelf:getBoundingBox()
      elseif key == 'display' then
        return instanceDisplay()
      end

      for _, handler in ipairs(keyHandlers()) do
        local result = handler(key)

        if result ~= nil then return result end
      end
    end,
    __name = 'S3LFOBJECT',
    __metatable = 'S3LFOBJECT',
  })
end

if instance.actorType == 0 then
  local staticTargetData = {}

  function instance.isInCombat()
    return next(staticTargetData) ~= nil and require 'openmw.debug'.isAIEnabled()
  end

  function instance.targetData()
    return util.makeReadOnly(staticTargetData)
  end

  return {
    engineHandlers = {
      onLoad = function(data)
        if not data then return end

        if data.staticTargetData then staticTargetData = data.staticTargetData end
        if data.cellsVisited then rawset(instance, 'cellsVisited', data.cellsVisited) end
      end,
      onSave = function()
        return {
          staticTargetData = staticTargetData,
          cellsVisited = rawget(instance, 'cellsVisited'),
        }
      end,
      onUpdate = function()
        rawset(instance, 'position', gameSelf.position)

        local currentCell = gameSelf.cell
        if currentCell == rawget(instance, 'cell') then return end

        local currentCellId = currentCell.id

        local cellsVisited = rawget(instance, 'cellsVisited')
        if not cellsVisited[currentCellId] then cellsVisited[currentCellId] = true end

        rawset(instance, 'cell', currentCell)

        gameSelf:sendEvent('S3LFCellChanged', currentCellId)
      end,
    },
    eventHandlers = {
      OMWMusicCombatTargetsChanged = function(incomingTargetData)
        local shouldRemove = next(incomingTargetData.targets) == nil

        local eventName

        if shouldRemove then
          staticTargetData[incomingTargetData.actor.id] = nil
          eventName = 'S3CombatTargetRemoved'
        else
          staticTargetData[incomingTargetData.actor.id] = incomingTargetData.actor
          eventName = 'S3CombatTargetAdded'
        end

        gameSelf:sendEvent(eventName, incomingTargetData.actor)
      end,
      S3LFDisplay = function(resultString)
        local ui = require 'openmw.ui'
        ui.printToConsole(resultString, ui.CONSOLE_COLOR.Success)
      end,
    },
    interfaceName = 's3',
    interface = {
      lf = instance,
    }
  }
else
  return {
    engineHandlers = {},
    eventHandlers = {},
    interfaceName = 's3',
    interface = {
      lf = instance,
    }
  }
end
