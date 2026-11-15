---@omw-context global

local I = require 'openmw.interfaces'
local types = require 'openmw.types'
local util = require 'openmw.util'

---@type StaticUtil
local staticUtil = require 'Scripts.staticSwitcher.util'

local BatchCache = require 'Scripts.staticSwitcher.batchCache'
local ObjectCleanup = require 'Scripts.staticSwitcher.objectCleanup'
local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'

local DebugLog, ErrorLog, WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  DebugLog = logger.debug
  ErrorLog = logger.error
  WarnLog = logger.warn
end

local pcall, tostring, type = pcall, tostring, type
local StrFind, StrFormat = string.find, string.format

local DeleteManager = require 'Scripts.staticSwitcher.deleteManager'

local StaticReplacements = require 'Scripts.staticSwitcher.staticReplacements'(DeleteManager)

local ModuleCatalog = require 'Scripts.staticSwitcher.moduleCatalog'(StaticReplacements)

StaticReplacements.setModuleResolver(ModuleCatalog.resolveModuleId)
StaticReplacements.setModuleOrder(ModuleCatalog.SortedStaticModuleIds)

local InstanceModifiers =
  require 'Scripts.staticSwitcher.instanceModifiers'(ModuleCatalog, DeleteManager)

local Triggers = require 'Scripts.staticSwitcher.triggers'(ModuleCatalog, InstanceModifiers)
local WorldTriggers = require 'Scripts.staticSwitcher.worldTriggers'(ModuleCatalog, Triggers)

require 'Scripts.staticSwitcher.globalSettings'

---@type openmw.GObject[]
local ActiveObjectStack = {}

local ActiveRules = ModuleCatalog.RulesByTrigger[TriggerContext.ACTIVE]

local NullFunction = require 'scripts.s3.nullFunction'

--- World triggers cost nothing unless a loaded rule listens to one. Sweeps only advance on
--- frames with no activation or deletion work, so newly active objects always settle first.
local PollWorldTriggers = WorldTriggers.isArmed() and WorldTriggers.poll or NullFunction
local IdleFunction = WorldTriggers.isArmed() and WorldTriggers.step or NullFunction

local UpdateFunction = IdleFunction
local processActiveObject, processDeletions

local REPLACE_PER_BATCH = 4

local DEATH_WATCHER_SCRIPT = 'scripts/staticSwitcher/deathWatcher.lua'
local watchesDeaths = Triggers.isArmed 'death'
local hasWarnedOfUnwatchedActor = false

--- What OpenMW says when the plugin in use does not declare the death watcher script at all.
local UNDECLARED_SCRIPT_ERRORS = { 'Unknown script', 'CUSTOM tag' }

local ACTIVATABLE_TYPE_NAMES = {
  'Activator',
  'Apparatus',
  'Armor',
  'Book',
  'Clothing',
  'Container',
  'Creature',
  'Door',
  'Ingredient',
  'Light',
  'Lockpick',
  'Miscellaneous',
  'NPC',
  'Potion',
  'Probe',
  'Repair',
  'Weapon',
}

local USABLE_TYPE_NAMES = {
  'Apparatus',
  'Armor',
  'Book',
  'Clothing',
  'Ingredient',
  'Light',
  'Lockpick',
  'Miscellaneous',
  'Potion',
  'Probe',
  'Repair',
  'Weapon',
}

---@param object openmw.GObject
---@param activeRules SSSTriggerRule[]
local function applyModulesToObject(object, activeRules)
  local instanceModificationList = InstanceModifiers.getMatchingInstanceModules(object, activeRules)

  -- Instance and static modules are intentionally separate pipelines.
  -- Matching instance rules own this activation; static replacement is the fallback.
  if instanceModificationList then
    InstanceModifiers.tryModifyObject(object, instanceModificationList)
  else
    StaticReplacements.tryReplaceObject(object)
  end
end

--- Death is only announced to an actor's own scripts, so a live actor gets a script that
--- relays it. A plugin that does not declare the script cannot attach it at all.
---@param object openmw.GObject
local function watchForDeath(object)
  if
    not types.Actor.objectIsInstance(object)
    or types.Player.objectIsInstance(object)
    or types.Actor.isDead(object)
    or object:hasScript(DEATH_WATCHER_SCRIPT)
  then
    return
  end

  local wasAttached, attachError = pcall(object.addScript, object, DEATH_WATCHER_SCRIPT)
  if wasAttached then return end

  local failure = tostring(attachError)

  for errorIdx = 1, #UNDECLARED_SCRIPT_ERRORS do
    if StrFind(failure, UNDECLARED_SCRIPT_ERRORS[errorIdx], 1, true) then
      watchesDeaths = false
      ErrorLog(StrFormat('The death trigger is unavailable: %s', failure))
      return
    end
  end

  if hasWarnedOfUnwatchedActor then return end
  hasWarnedOfUnwatchedActor = true

  WarnLog(StrFormat('The death of %s cannot be watched: %s', object.recordId, failure))
end

--- Runs before the engine's own activation, so an item is still in the world when rules see it.
--- Returns nothing: rules observe an activation, they do not replace it.
---@param object openmw.GObject
---@param actor openmw.GObject
local function onObjectActivated(object, actor) Triggers.dispatch('activate', object, actor) end

--- A used item sits in an inventory and has no cell, so `use` rules run on the actor using it.
---@param item openmw.GObject
---@param actor openmw.GObject
local function onItemUsed(item, actor) Triggers.dispatch('use', actor, actor, item) end

---@param typeNames string[]
---@param addHandlerForType fun(objectType: table, handler: fun(object: openmw.GObject, actor: openmw.GObject))
---@param handler fun(object: openmw.GObject, actor: openmw.GObject)
local function addHandlerForTypes(typeNames, addHandlerForType, handler)
  for typeIdx = 1, #typeNames do
    local objectType = types[typeNames[typeIdx]]
    if objectType then addHandlerForType(objectType, handler) end
  end
end

if Triggers.isArmed 'activate' then
  local Activation = I.Activation

  if Activation then
    addHandlerForTypes(ACTIVATABLE_TYPE_NAMES, Activation.addHandlerForType, onObjectActivated)
  else
    ErrorLog 'The activate trigger is unavailable: the Activation interface is missing'
  end
end

if Triggers.isArmed 'use' then
  local ItemUsage = I.ItemUsage

  if ItemUsage then
    addHandlerForTypes(USABLE_TYPE_NAMES, ItemUsage.addHandlerForType, onItemUsed)
  else
    ErrorLog 'The use trigger is unavailable: the ItemUsage interface is missing'
  end
end

---@param triggerName string custom trigger name, without the `custom:` prefix
---@param object openmw.GObject
---@return boolean wasDispatched
local function fireCustomTrigger(triggerName, object)
  if type(triggerName) ~= 'string' or not staticUtil.isGObject(object) then return false end

  return Triggers.dispatch(StrFormat('custom:%s', triggerName), object)
end

processActiveObject = function()
  for _ = 1, REPLACE_PER_BATCH do
    local numObjects = #ActiveObjectStack
    if numObjects == 0 then break end

    local object = ActiveObjectStack[numObjects]
    ActiveObjectStack[numObjects] = nil

    if Triggers.isPlacedInWorld(object) then
      Triggers.runGuarded(applyModulesToObject, object, ActiveRules)
    end
  end

  DebugLog('Batch processed, stack: %d remaining', #ActiveObjectStack)

  if not DeleteManager:queueIsEmpty() then
    UpdateFunction = processDeletions
  elseif #ActiveObjectStack == 0 then
    UpdateFunction = IdleFunction
  end
end

processDeletions = function()
  DeleteManager:processDeleteQueue()

  local deletionsFinished = DeleteManager:queueIsEmpty()

  if next(ActiveObjectStack) ~= nil then
    UpdateFunction = processActiveObject
  elseif deletionsFinished then
    UpdateFunction = IdleFunction
  end

  DebugLog('Deletions: queue empty=%s, stack=%d', deletionsFinished, #ActiveObjectStack)
end

return {
  interface = {
    ---@return boolean isGenerated, number refNum
    getRefNum = staticUtil.getRefNum,
    ---@return table<string, SSSModule> moduleData Map of file names handling mesh replacements to the data contained therein
    composedReplacements = function()
      return util.makeReadOnly(StaticReplacements.ComposedReplacements)
    end,
    ---@return SSSObjectModificationStore
    objectModificationStore = function()
      return util.makeReadOnly(ModuleCatalog.ObjectModificationStore)
    end,
    ---@return SSSOverrideRecords
    overrideRecords = function() return util.makeReadOnly(StaticReplacements.OverrideRecords) end,
    --- Runs every rule listening to `custom:<triggerName>` on the object. Returns false when
    --- no rule listens, the object is not in the world, or the call was debounced.
    trigger = fireCustomTrigger,
    version = 6,
  },
  interfaceName = 'StaticSwitcher_G',
  engineHandlers = {
    ---@param dt number
    onUpdate = function(dt)
      PollWorldTriggers(dt)
      if ObjectCleanup.hasPending() then ObjectCleanup.step() end
      UpdateFunction()
    end,
    ---@param object openmw.GObject
    onObjectActive = function(object)
      local stackWasEmpty = not next(ActiveObjectStack)

      if stackWasEmpty then
        InstanceModifiers.clearPerCellTracking()
        BatchCache.clear()
      end

      if watchesDeaths then watchForDeath(object) end

      ActiveObjectStack[#ActiveObjectStack + 1] = object
      DebugLog(
        'Object active: %s (%s) [stack=%d]',
        object.id,
        object.recordId or '?',
        #ActiveObjectStack
      )

      if UpdateFunction ~= processActiveObject then UpdateFunction = processActiveObject end
    end,
    ---@param object openmw.GObject
    ---@param actor openmw.GObject
    onDropped = function(object, actor) Triggers.dispatch('drop', object, actor) end,
    ---@param object openmw.GObject
    ---@param actor openmw.GObject
    onPlaced = function(object, actor) Triggers.dispatch('place', object, actor) end,
    ---@return SSSSavedState
    onSave = function()
      DebugLog 'Saving SSS state'
      return {
        overrideRecords = StaticReplacements.OverrideRecords,
        objectDeleteQueue = DeleteManager.queue,
        instanceModifiers = InstanceModifiers.saveOnceCache(),
        replacementChains = StaticReplacements.saveReplacementChains(),
        pendingCorrections = ObjectCleanup.saveCorrections(),
      }
    end,
    ---@param data SSSSavedState?
    onLoad = function(data)
      if not data then
        DebugLog 'Loading SSS state: fresh save (no data)'
        DeleteManager.queue = {}
        InstanceModifiers.loadOnceCache()
        StaticReplacements.loadReplacementChains()
        ObjectCleanup.loadCorrections()
        return
      end

      DebugLog 'Loading SSS state from save data'
      staticUtil.deepCopy(StaticReplacements.OverrideRecords, data.overrideRecords)
      StaticReplacements.migrateOverrideRecords()
      DeleteManager.queue = {}
      if type(data.objectDeleteQueue) == 'table' then
        staticUtil.deepCopy(DeleteManager.queue, data.objectDeleteQueue)
      end
      InstanceModifiers.loadOnceCache(data.instanceModifiers)
      StaticReplacements.loadReplacementChains(data.replacementChains, data.replacedObjectSet)
      ObjectCleanup.loadCorrections(data.pendingCorrections)

      if not DeleteManager:queueIsEmpty() then UpdateFunction = processDeletions end
    end,
  },
  eventHandlers = {
    ---@param actor openmw.GObject
    StaticSwitcherActorDied = function(actor)
      if staticUtil.isGObject(actor) then Triggers.dispatch('death', actor) end
    end,
    --- Any script can send this, so nothing about the payload is taken on trust.
    ---@param data SSSCustomTriggerEvent
    StaticSwitcherTrigger = function(data)
      if type(data) == 'table' then fireCustomTrigger(data.name, data.object) end
    end,
  },
}
