---@alias ActorType
---| 0 # Player
---| 1 # NPC
---| 2 # Creature
---| 3 # None

local gameSelf = require 'openmw.self'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'
local util = require 'openmw.util'

local localPlayers = nearby.players

local next, rawget, rawset, type = next, rawget, rawset, type

---@type KeyBehaviors
local KeyBehavior = require 'openmw.storage'.globalSection 'S3lfColdStorage':get 'KeyBehavior'

---@class S3lfObject
---@field actorType ActorType
local instance = {
  consoleLog = require 'scripts.s3.logmessage',
}

local sortedPairs = require 'scripts.s3.table'.sortedPairs

local function alphabeticalParts()
  local parts = {}
  local methodParts = {}
  local userDataParts = {}

  for key, value in sortedPairs(instance) do
    local valueType = type(value)

    if valueType == 'function' then
      methodParts[#methodParts + 1] = key
    elseif valueType == 'userdata' then
      userDataParts[#userDataParts + 1] = ('%s = %s'):format(
        key,
        value
      )
    else
      parts[#parts + 1] = ('%s = %s'):format(
        key,
        value
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

local cellsVisited

do
  local animation = require 'openmw.animation'

  local ActorType, AI, Attributes, Dynamic, Level, Skills, Stats
  local MyType = gameSelf.type

  if not types.Actor.objectIsInstance(gameSelf) then
    ActorType = 3
  elseif MyType == types.Creature then
    ActorType = 2
  elseif MyType == types.NPC then
    ActorType = 1
  elseif MyType == types.Player then
    ActorType = 0
  else
    error('Invalid actor type!!!!')
  end

  if ActorType < 3 then
    Stats = MyType.stats
    AI, Attributes, Dynamic, Level, Skills = Stats.ai, Stats.attributes, Stats.dynamic, Stats.level, Stats.skills
  end

  if ActorType == 0 then
    cellsVisited = {}
    rawset(instance, 'cellsVisited', cellsVisited)
    rawset(instance, 'cell', gameSelf.cell)
  end

  setmetatable(instance, {
    __index = function(_, key)
      ---@type KeyBehavior?
      local behavior = KeyBehavior[key]

      if behavior == 0 then     -- Ignored
        return
      elseif behavior == 1 then -- Uncacheable
        return gameSelf[key]
      end

      local typeValue = MyType[key]

      if typeValue ~= nil then
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

      if ActorType < 3 then
        local dynamicStat = Dynamic[key]
        if dynamicStat then
          local result = dynamicStat(gameSelf)

          rawset(instance, key, result)

          return result
        end

        local attribute = Attributes[key]
        if attribute then
          local result = attribute(gameSelf)

          rawset(instance, key, result)

          return result
        end

        if ActorType < 2 then
          local skill = Skills[key]

          if skill then
            local result = skill(gameSelf)

            rawset(instance, key, result)

            return result
          end
        end

        if key == 'level' then
          local level = Level(gameSelf)
          rawset(instance, key, level)
          return level
        end

        local aiStat = AI[key]
        if aiStat ~= nil then
          local stat = aiStat(gameSelf)
          rawset(instance, key, stat)
          return stat
        end
      end

      local record = rawget(instance, 'record')

      if not record then
        record = gameSelf.type.records[gameSelf.recordId]
        rawset(instance, 'record', record)
      end

      local recordValue = record[key]
      if recordValue ~= nil then
        rawset(instance, key, recordValue)
        return recordValue
      end

      local objectValue = gameSelf[key]
      if objectValue ~= nil then
        rawset(instance, key, objectValue)
        return objectValue
      end

      --- Values from animation, pretty cold path
      local animValue = animation[key]
      if animValue ~= nil then
        local insertValue
        if type(animValue) == 'function' then
          insertValue = function(...)
            return animValue(gameSelf, ...)
          end
        else
          insertValue = animValue
        end

        rawset(instance, key, insertValue)

        return insertValue
      end

      if key == 'bounds' then
        return gameSelf:getBoundingBox()
      elseif key == 'display' then
        return instanceDisplay()
      end
    end,
    __name = 'S3LFOBJECT',
    __metatable = 'S3LFOBJECT',
  })
end

if instance.actorType == 0 then
  local debug = require 'openmw.debug'
  local ui = require 'openmw.ui'

  local staticTargetData = {}
  local staticTargetDataView = util.makeReadOnly(staticTargetData)

  function instance.isInCombat()
    return next(staticTargetData) ~= nil and debug.isAIEnabled()
  end

  function instance.targetData()
    return staticTargetDataView
  end

  return {
    engineHandlers = {
      onLoad = function(data)
        if not data then return end

        if data.staticTargetData then
          staticTargetData = data.staticTargetData
          staticTargetDataView = util.makeReadOnly(staticTargetData)
        end
        if data.cellsVisited then
          cellsVisited = data.cellsVisited
          rawset(instance, 'cellsVisited', cellsVisited)
        end
      end,
      onSave = function()
        return {
          staticTargetData = staticTargetData,
          cellsVisited = cellsVisited,
        }
      end,
      onUpdate = function()
        rawset(instance, 'position', gameSelf.position)

        local currentCell = gameSelf.cell
        if currentCell == rawget(instance, 'cell') then return end

        local currentCellId = currentCell.id

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
