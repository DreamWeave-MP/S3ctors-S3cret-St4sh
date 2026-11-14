---@omw-context global

local util = require 'openmw.util'

---@type StaticUtil
local staticUtil = require 'Scripts.staticSwitcher.util'

local BatchCache = require 'Scripts.staticSwitcher.batchCache'

local DebugLog, ErrorLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  DebugLog = logger.debug
  ErrorLog = logger.error
end

local pcall, type = pcall, type
local StrFormat = string.format

local DeleteManager = require 'Scripts.staticSwitcher.deleteManager'

local StaticReplacements = require 'Scripts.staticSwitcher.staticReplacements'(DeleteManager)

local ModuleCatalog = require 'Scripts.staticSwitcher.moduleCatalog'(StaticReplacements)

StaticReplacements.setModuleResolver(ModuleCatalog.resolveModuleId)
StaticReplacements.setModuleOrder(ModuleCatalog.SortedStaticModuleIds)

local InstanceModifiers =
  require 'Scripts.staticSwitcher.instanceModifiers'(ModuleCatalog, DeleteManager)

require 'Scripts.staticSwitcher.globalSettings'

---@type openmw.GObject[]
local ActiveObjectStack = {}

local NullFunction = require 'scripts.s3.nullFunction'
local UpdateFunction = NullFunction
local processActiveObject, processDeletions

local REPLACE_PER_BATCH = 4

---@param object openmw.GObject
local function applyModulesToObject(object)
  local instanceModificationList = InstanceModifiers.getMatchingInstanceModules(object)

  -- Instance and static modules are intentionally separate pipelines.
  -- Matching instance rules own this activation; static replacement is the fallback.
  if instanceModificationList then
    InstanceModifiers.tryModifyObject(object, instanceModificationList)
  else
    StaticReplacements.tryReplaceObject(object)
  end
end

--- An object taken into an inventory or container while it was still queued has no cell.
--- Returning it to the world activates it again, so it is safe to drop from this batch.
---@param object openmw.GObject
---@return boolean
local function isPlacedInWorld(object)
  return object:isValid() and object.count >= 1 and object.cell ~= nil
end

processActiveObject = function()
  for _ = 1, REPLACE_PER_BATCH do
    local numObjects = #ActiveObjectStack
    if numObjects == 0 then break end

    local object = ActiveObjectStack[numObjects]
    ActiveObjectStack[numObjects] = nil

    if isPlacedInWorld(object) then
      local wasProcessed, processError = pcall(applyModulesToObject, object)

      if not wasProcessed then
        ErrorLog(
          StrFormat('Skipped %s (%s): %s', object.id, object.recordId, tostring(processError))
        )
      end
    end
  end

  DebugLog('Batch processed, stack: %d remaining', #ActiveObjectStack)

  if not DeleteManager:queueIsEmpty() then
    UpdateFunction = processDeletions
  elseif #ActiveObjectStack == 0 then
    UpdateFunction = NullFunction
  end
end

processDeletions = function()
  DeleteManager:processDeleteQueue()

  local deletionsFinished = DeleteManager:queueIsEmpty()

  if next(ActiveObjectStack) ~= nil then
    UpdateFunction = processActiveObject
  elseif deletionsFinished then
    UpdateFunction = NullFunction
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
    version = 5,
  },
  interfaceName = 'StaticSwitcher_G',
  engineHandlers = {
    onUpdate = function() UpdateFunction() end,
    ---@param object openmw.GObject
    onObjectActive = function(object)
      local stackWasEmpty = not next(ActiveObjectStack)

      if stackWasEmpty then
        InstanceModifiers.clearPerCellTracking()
        BatchCache.clear()
      end

      ActiveObjectStack[#ActiveObjectStack + 1] = object
      DebugLog(
        'Object active: %s (%s) [stack=%d]',
        object.id,
        object.recordId or '?',
        #ActiveObjectStack
      )

      if UpdateFunction ~= processActiveObject then UpdateFunction = processActiveObject end
    end,
    ---@return SSSSavedState
    onSave = function()
      DebugLog 'Saving SSS state'
      return {
        overrideRecords = StaticReplacements.OverrideRecords,
        objectDeleteQueue = DeleteManager.queue,
        instanceModifiers = InstanceModifiers.saveOnceCache(),
        replacementChains = StaticReplacements.saveReplacementChains(),
      }
    end,
    ---@param data SSSSavedState?
    onLoad = function(data)
      if not data then
        DebugLog 'Loading SSS state: fresh save (no data)'
        DeleteManager.queue = {}
        InstanceModifiers.loadOnceCache()
        StaticReplacements.loadReplacementChains()
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

      if not DeleteManager:queueIsEmpty() then UpdateFunction = processDeletions end
    end,
  },
}
