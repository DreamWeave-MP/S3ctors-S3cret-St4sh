---@omw-context global

local types              = require 'openmw.types'
local util               = require 'openmw.util'
local world              = require 'openmw.world'

---@type StaticUtil
local staticUtil         = require 'scripts.staticSwitcher.util'

local ModuleToRemove

local ipairs             = ipairs

local sendMenuEvent      = types.Player.sendMenuEvent

local DeleteManager      = require 'Scripts.staticSwitcher.deleteManager'

local StaticReplacements = require 'Scripts.staticSwitcher.staticReplacements' (
  DeleteManager
)

local ModuleCatalog      = require 'Scripts.staticSwitcher.moduleCatalog' (
  StaticReplacements
)

local InstanceModifiers  = require 'Scripts.staticSwitcher.instanceModifiers' (
  ModuleCatalog
)

local uninstallModule    = require 'Scripts.staticSwitcher.globalSettings' (
  ModuleCatalog.moduleNames,
  DeleteManager,
  StaticReplacements.ReplacedObjectSet
)

local settingsGroup      = require 'openmw.storage'.globalSection('SettingsStaticSwitcher')
if settingsGroup:get 'StaticSwitcherDisableModule' then settingsGroup:set('StaticSwitcherDisableModule', false) end

---@type openmw.GObject[]
local ActiveObjectStack = {}

local NullFunction = require 'scripts.s3.nullFunction'
local UpdateFunction = NullFunction
local processActiveObject, processDeletions, processUninstall

local REPLACE_PER_BATCH = 4

processActiveObject = function()
  local numObjects = 0

  for _ = 1, REPLACE_PER_BATCH do
    numObjects = #ActiveObjectStack

    if numObjects == 0 then break end

    local object = ActiveObjectStack[numObjects]

    if object:isValid() and object.count >= 1 then
      local instanceModificationList = InstanceModifiers.getMatchingInstanceModules(object)

      --- I don't like this.
      --- Ideally we should have like, a special type that gets assigned to each module, or something
      --- a more bespoke way to describe what *type* of module it is
      if instanceModificationList then
        InstanceModifiers.tryModifyObject(object, instanceModificationList)
      else
        StaticReplacements.tryReplaceObject(object)
      end
    end

    ActiveObjectStack[numObjects] = nil
  end

  if not DeleteManager:queueIsEmpty() then
    UpdateFunction = processDeletions
  elseif numObjects <= 1 then
    UpdateFunction = NullFunction
  end
end

processUninstall = function()
  --- When a module is removed and all objects are removed
  --- kick every player from the game and force them to save
  for _, player in ipairs(world.players) do
    sendMenuEvent(player, 'StaticSwitcherMenuRemoveModule', ModuleToRemove)
  end

  ModuleToRemove = nil
  UpdateFunction = NullFunction
end

processDeletions = function()
  DeleteManager:processDeleteQueue()

  local deletionsFinished = DeleteManager:queueIsEmpty()

  if next(ActiveObjectStack) ~= nil then
    UpdateFunction = processActiveObject
  elseif ModuleToRemove and deletionsFinished then
    UpdateFunction = processUninstall
  elseif deletionsFinished then
    UpdateFunction = NullFunction
  end
end

settingsGroup:subscribe(
  require 'openmw.async':callback(
    function(_, key)
      if key == 'StaticSwitcherDisableModule' then
        ModuleToRemove = settingsGroup:get('StaticSwitcherModuleSelect')
        uninstallModule(ModuleToRemove)
        UpdateFunction = processDeletions
      end
    end
  )
)

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
    overrideRecords = function()
      return util.makeReadOnly(StaticReplacements.OverrideRecords)
    end,
    ---@return SSSReplacedObjectSet
    replacedObjectSet = function()
      return util.makeReadOnly(StaticReplacements.ReplacedObjectSet)
    end,
    ---@param moduleName string
    uninstallModule = function(moduleName)
      ModuleToRemove = uninstallModule(moduleName)
      UpdateFunction = processDeletions
    end,
    version = 3,
  },
  interfaceName = "StaticSwitcher_G",
  engineHandlers = {
    onUpdate = function()
      UpdateFunction()
    end,
    ---@param object openmw.GObject
    onObjectActive = function(object)
      if ModuleToRemove then return end

      ActiveObjectStack[#ActiveObjectStack + 1] = object

      if UpdateFunction ~= processActiveObject then UpdateFunction = processActiveObject end
    end,
    ---@return SSSSavedState
    onSave = function()
      return {
        overrideRecords = StaticReplacements.OverrideRecords,
        objectDeleteQueue = DeleteManager.queue,
        instanceModifiers = InstanceModifiers.saveOnceCache(),
        replacedObjectSet = StaticReplacements.ReplacedObjectSet,
      }
    end,
    ---@param data SSSSavedState?
    onLoad = function(data)
      if not data then
        InstanceModifiers.loadOnceCache()
        StaticReplacements.rebuildReplacementStepBySource()
        return
      end

      staticUtil.deepCopy(StaticReplacements.OverrideRecords, data.overrideRecords)
      staticUtil.deepCopy(DeleteManager.queue, data.objectDeleteQueue)
      InstanceModifiers.loadOnceCache(data.instanceModifiers)
      staticUtil.deepCopy(StaticReplacements.ReplacedObjectSet, data.replacedObjectSet)
      StaticReplacements.rebuildReplacementStepBySource()
    end,
  }
}
