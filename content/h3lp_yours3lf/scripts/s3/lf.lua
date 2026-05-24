---@omw-context local | player

---@alias ActorType
---| 0 # Player
---| 1 # NPC
---| 2 # Creature
---| 3 # None

---@alias S3lfRecord
---| openmw.types.CreatureRecord
---| openmw.types.NpcRecord
---| openmw.types.ArmorRecord
---| openmw.types.BookRecord
---| openmw.types.ClothingRecord
---| openmw.types.IngredientRecord
---| openmw.types.LightRecord
---| openmw.types.MiscellaneousRecord
---| openmw.types.PotionRecord
---| openmw.types.WeaponRecord
---| openmw.types.ApparatusRecord
---| openmw.types.LockpickRecord
---| openmw.types.ProbeRecord
---| openmw.types.RepairRecord
---| openmw.types.ActivatorRecord
---| openmw.types.ContainerRecord
---| openmw.types.DoorRecord
---| openmw.types.StaticRecord
---| openmw.types.LevelledCreatureRecord

local async = require 'openmw.async'
local gameSelf = require 'openmw.self'
local nearby = require 'openmw.nearby'
local storage = require 'openmw.storage'
local types = require 'openmw.types'
local util = require 'openmw.util'

local localPlayers = nearby.players

local next, rawget, rawset, type = next, rawget, rawset, type

local S3S = storage.globalSection 'S3lfColdStorage'
---@type KeyBehaviors
local KeyBehavior = S3S:get 'KeyBehavior'

S3S:subscribe(async:callback(function(_, key)
  if not key or key == 'KeyBehavior' then
    KeyBehavior = S3S:get 'KeyBehavior'
  end
end))

---Dynamic convenience facade for the current object.
---Fields are resolved lazily from openmw.self, the object's type module,
---actor stats, records, animation helpers, and s3-specific helpers. Some
---members only exist for relevant object kinds at runtime.
---@class S3lfObject: openmw.SelfObject
---@field actorType ActorType
---@field record? S3lfRecord
---@field bounds? openmw.util.Box
---@field cellsVisited? table<string, boolean>
---@field consoleLog fun(...: any)
---@field distance fun(other: openmw.Object): number
---@field sendObjectEvent fun(eventName: string, eventData?: any)
---@field asActor fun(): S3lfActorObject?
---@field asNPC fun(): S3lfNpcLikeObject? OpenMW NPC type APIs include Player.
---@field asPlayer fun(): S3lfPlayerObject?
---@field asCreature fun(): S3lfCreatureObject?
---@field asNonActor fun(): S3lfNonActorObject?
---@field isInCombat? fun(): boolean Player-only helper.
---@field targetData? fun(): table<string, openmw.LObject> Player-only helper.
---@field getEncumbrance fun(): number Bound Actor method.
---@field getCapacity fun(): number Bound Actor method.
---@field getBarterGold fun(): number Bound Actor method.
---@field setBarterGold fun(amount: number) Bound Actor method.
---@field isDead fun(): boolean Bound Actor method.
---@field isDeathFinished fun(): boolean Bound Actor method.
---@field getPathfindingAgentBounds fun(): table Bound Actor method.
---@field isInActorsProcessingRange fun(): boolean Bound Actor method.
---@field inventory fun(): openmw.core.Inventory Bound Actor method.
---@field canMove fun(): boolean Bound Actor method.
---@field getRunSpeed fun(): number Bound Actor method.
---@field getWalkSpeed fun(): number Bound Actor method.
---@field getCurrentSpeed fun(): number Bound Actor method.
---@field isOnGround fun(): boolean Bound Actor method.
---@field isSwimming fun(): boolean Bound Actor method.
---@field getStance fun(): number Bound Actor method.
---@field setStance fun(stance: number) Bound Actor method.
---@field hasEquipped fun(item: openmw.Object): boolean Bound Actor method.
---@field getEquipment fun(slot?: number): openmw.types.EquipmentTable|openmw.Object|nil Bound Actor method.
---@field setEquipment fun(equipment: openmw.types.EquipmentTable) Bound Actor method.
---@field getSelectedSpell fun(): openmw.core.Spell|nil Bound Actor method.
---@field setSelectedSpell fun(spell: openmw.core.Spell|string|nil) Bound Actor method.
---@field clearSelectedCastable fun() Bound Actor method.
---@field getSelectedEnchantedItem fun(): openmw.Object|nil Bound Actor method.
---@field setSelectedEnchantedItem fun(item: openmw.Object|string) Bound Actor method.
---@field activeEffects fun(): openmw.types.ActorActiveEffects Bound Actor method.
---@field activeSpells fun(): openmw.types.ActorActiveSpells Bound Actor method.
---@field spells fun(): openmw.types.ActorSpells Bound Actor method.
---@field health openmw.types.DynamicStat
---@field magicka openmw.types.DynamicStat
---@field fatigue openmw.types.DynamicStat
---@field alarm openmw.types.AIStat
---@field fight openmw.types.AIStat
---@field flee openmw.types.AIStat
---@field hello openmw.types.AIStat
---@field strength openmw.types.AttributeStat
---@field intelligence openmw.types.AttributeStat
---@field willpower openmw.types.AttributeStat
---@field agility openmw.types.AttributeStat
---@field speed openmw.types.AttributeStat
---@field endurance openmw.types.AttributeStat
---@field personality openmw.types.AttributeStat
---@field luck openmw.types.AttributeStat
---@field level openmw.types.LevelStat
---@field block openmw.types.SkillStat
---@field armorer openmw.types.SkillStat
---@field mediumarmor openmw.types.SkillStat
---@field heavyarmor openmw.types.SkillStat
---@field bluntweapon openmw.types.SkillStat
---@field longblade openmw.types.SkillStat
---@field axe openmw.types.SkillStat
---@field spear openmw.types.SkillStat
---@field athletics openmw.types.SkillStat
---@field enchant openmw.types.SkillStat
---@field destruction openmw.types.SkillStat
---@field alteration openmw.types.SkillStat
---@field illusion openmw.types.SkillStat
---@field conjuration openmw.types.SkillStat
---@field mysticism openmw.types.SkillStat
---@field restoration openmw.types.SkillStat
---@field alchemy openmw.types.SkillStat
---@field unarmored openmw.types.SkillStat
---@field security openmw.types.SkillStat
---@field sneak openmw.types.SkillStat
---@field acrobatics openmw.types.SkillStat
---@field lightarmor openmw.types.SkillStat
---@field shortblade openmw.types.SkillStat
---@field marksman openmw.types.SkillStat
---@field mercantile openmw.types.SkillStat
---@field speechcraft openmw.types.SkillStat
---@field handtohand openmw.types.SkillStat
---@field getFactions fun(): string[] Bound NPC method.
---@field getFactionRank fun(faction: string): number Bound NPC method.
---@field setFactionRank fun(faction: string, value: number) Bound NPC method.
---@field modifyFactionRank fun(faction: string, value: number) Bound NPC method.
---@field joinFaction fun(faction: string) Bound NPC method.
---@field leaveFaction fun(faction: string) Bound NPC method.
---@field getFactionReputation fun(faction: string): number Bound NPC method.
---@field setFactionReputation fun(faction: string, value: number) Bound NPC method.
---@field modifyFactionReputation fun(faction: string, value: number) Bound NPC method.
---@field expel fun(faction: string) Bound NPC method.
---@field clearExpelled fun(faction: string) Bound NPC method.
---@field isExpelled fun(faction: string): boolean Bound NPC method.
---@field getDisposition fun(player: openmw.Object): number Bound NPC method.
---@field getBaseDisposition fun(player: openmw.Object): number Bound NPC method.
---@field setBaseDisposition fun(player: openmw.Object, value: number) Bound NPC method.
---@field modifyBaseDisposition fun(player: openmw.Object, value: number) Bound NPC method.
---@field isWerewolf fun(): boolean Bound NPC method.
---@field setWerewolf fun(werewolf: boolean) Bound NPC method.
---@field getCrimeLevel fun(): number Bound Player method.
---@field setCrimeLevel fun(crimeLevel: number) Bound Player/global-only method for self/player use.
---@field isCharGenFinished fun(): boolean Bound Player method.
---@field isTeleportingEnabled fun(): boolean Bound Player method.
---@field setTeleportingEnabled fun(state: boolean) Bound Player method.
---@field quests fun(): table<string, openmw.types.PlayerQuest|nil> Bound Player method.
---@field addTopic fun(topicId: string) Bound Player method.
---@field journal fun(): openmw.types.PlayerJournal Bound Player method.
---@field getControlSwitch fun(key: openmw.types.ControlSwitch): boolean Bound Player method.
---@field setControlSwitch fun(key: openmw.types.ControlSwitch, value: boolean) Bound Player method.
---@field getBirthSign fun(): string Bound Player method.
---@field sendMenuEvent fun(eventName: string, eventData?: any) Bound Player method.
---@field isCreature boolean Record-derived field.
---@field combatSkill number Record-derived field.
---@field name? string Record-derived field.
---@field model? string Record-derived field.
---@field baseGold? number Record-derived field.
---@class S3lfActorObject: S3lfObject
---@field actorType 0|1|2
---@field record openmw.types.NpcRecord|openmw.types.CreatureRecord

---OpenMW NPC type APIs include Player.
---@class S3lfNpcLikeObject: S3lfActorObject
---@field actorType 0|1
---@field record openmw.types.NpcRecord
---@class S3lfNpcObject: S3lfNpcLikeObject
---@field actorType 1
---@field record openmw.types.NpcRecord

---@class S3lfPlayerObject: S3lfNpcLikeObject
---@field actorType 0
---@field record openmw.types.NpcRecord
---@field cellsVisited table<string, boolean>
---@field isInCombat fun(): boolean
---@field targetData fun(): table<string, openmw.LObject>

---@class S3lfCreatureObject: S3lfActorObject
---@field actorType 2
---@field record openmw.types.CreatureRecord
---@field isCreature boolean
---@field combatSkill number

---@class S3lfNonActorObject: S3lfObject
---@field actorType 3
---@field record? S3lfRecord

---@class openmw.interfaces.s3
---@field lf S3lfObject

---@class openmw.interfaces
---@field s3? openmw.interfaces.s3
local instance = {
  consoleLog = require 'scripts.s3.logmessage',
}
---@cast instance S3lfObject

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

  rawset(instance, 'actorType', ActorType)

  ---@return S3lfActorObject?
  function instance.asActor()
    if ActorType < 3 then
      local actor = instance
      ---@cast actor S3lfActorObject
      return actor
    end
  end

  ---OpenMW NPC type includes Player.
  ---@return S3lfNpcLikeObject?
  function instance.asNPC()
    if ActorType < 2 then
      local npc = instance
      ---@cast npc S3lfNpcLikeObject
      return npc
    end
  end

  ---@return S3lfPlayerObject?
  function instance.asPlayer()
    if ActorType == 0 then
      local player = instance
      ---@cast player S3lfPlayerObject
      return player
    end
  end

  ---@return S3lfCreatureObject?
  function instance.asCreature()
    if ActorType == 2 then
      local creature = instance
      ---@cast creature S3lfCreatureObject
      return creature
    end
  end

  ---@return S3lfNonActorObject?
  function instance.asNonActor()
    if ActorType == 3 then
      local nonActor = instance
      ---@cast nonActor S3lfNonActorObject
      return nonActor
    end
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
      if not KeyBehavior then return end

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

---@omw-context-begin player
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

        --- Even players actually will not have a nil cell in onUpdate
        ---@diagnostic disable-next-line: need-check-nil
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
  ---@omw-context-end player
  ---@omw-context-begin local
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
---@omw-context-end local
