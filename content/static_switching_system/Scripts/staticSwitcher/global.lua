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

settingsGroup:subscribe(
  require 'openmw.async':callback(
    function(_, key)
      if key == 'StaticSwitcherDisableModule' then
        ModuleToRemove = settingsGroup:get('StaticSwitcherModuleSelect')
        uninstallModule(ModuleToRemove)
      end
    end
  )
)

return {
  interface = {
    getRefNum = staticUtil.getRefNum,
    objectModificationStore = function()
      return util.makeReadOnly(ModuleCatalog.ObjectModificationStore)
    end,
    overrideRecords = function()
      return util.makeReadOnly(StaticReplacements.OverrideRecords)
    end,
    replacedObjectSet = function()
      return util.makeReadOnly(StaticReplacements.ReplacedObjectSet)
    end,
    uninstallModule = function(moduleName)
      ModuleToRemove = uninstallModule(moduleName)
    end,
    version = 3,
  },
  interfaceName = "StaticSwitcher_G",
  engineHandlers = {
    onUpdate = function()
      DeleteManager:processDeleteQueue()

      if not ModuleToRemove or not DeleteManager:queueIsEmpty() then return end

      --- When a module is removed and all objects are removed
      --- kick every player from the game and force them to save
      for _, player in ipairs(world.players) do
        sendMenuEvent(player, 'StaticSwitcherMenuRemoveModule', ModuleToRemove)
      end

      ModuleToRemove = nil
    end,
    onObjectActive = function(object)
      local instanceModificationList = InstanceModifiers.getMatchingInstanceModules(object)

      --- I don't like this.
      --- Ideally we should have like, a special type that gets assigned to each module, or something
      --- a more bespoke way to describe what *type* of module it is
      if instanceModificationList then
        InstanceModifiers.tryModifyObject(object)
      else
        StaticReplacements.tryReplaceObject(object)
      end
    end,
    onSave = function()
      return {
        overrideRecords = StaticReplacements.OverrideRecords,
        objectDeleteQueue = DeleteManager.queue,
        replacedObjectSet = StaticReplacements.ReplacedObjectSet,
      }
    end,
    onLoad = function(data)
      if not data then return end

      staticUtil.deepCopy(StaticReplacements.OverrideRecords, data.overrideRecords)
      staticUtil.deepCopy(DeleteManager.queue, data.objectDeleteQueue)
      staticUtil.deepCopy(StaticReplacements.ReplacedObjectSet, data.replacedObjectSet)
    end,
  }
}
