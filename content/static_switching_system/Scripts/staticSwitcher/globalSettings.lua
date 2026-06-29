---@omw-context global

local I                   = require 'openmw.interfaces'

local staticUtil          = require 'scripts.staticswitcher.util'

local INVALID_MODULE_NAME = 'Invalid module name provided: %s. Either it does not exist, or has not replaced anything.'

---@type SSSDeleteManager
local DeleteManager

---@type SSSReplacedObjectSet
local ReplacedObjectSet

---@type (fun(fileName: string): string?)?
local ChainUninstallModule

local assert, next, pairs = assert, next, pairs

--- Remove all objects which were replaced by a given module
--- After all objects from this module are inserted into the delete queue, mark this module as unusable for replacements
---@param fileName string
---@return string? removedModule
local function uninstallModule(fileName)
  if ChainUninstallModule then
    local removedModule = ChainUninstallModule(fileName)

    if not removedModule then
      return staticUtil.Log(
        INVALID_MODULE_NAME:format(fileName)
      )
    end

    return removedModule
  end

  local objectsToRemove, objectsToRemoveLength = {}, 0
  local localModuleReplacements = ReplacedObjectSet[fileName]

  if not localModuleReplacements then
    return staticUtil.Log(
      INVALID_MODULE_NAME:format(fileName)
    )
  end

  for newObject, oldObject in pairs(localModuleReplacements) do
    if oldObject:isValid() and oldObject.count >= 1 then oldObject.enabled = true end
    DeleteManager:addObjectToDeleteQueue(newObject, true)

    objectsToRemoveLength = objectsToRemoveLength + 1
    objectsToRemove[objectsToRemoveLength] = newObject
  end

  for i = 1, objectsToRemoveLength do
    local targetObject = objectsToRemove[i]
    ReplacedObjectSet[fileName][targetObject] = nil
  end

  return fileName
end

---@param moduleIds string[] canonical loaded module ids
---@param deleteManager SSSDeleteManager
---@param replacedObjectSet SSSReplacedObjectSet
---@param chainUninstallModule (fun(fileName: string): string?)?
---@return fun(fileName: string): string? uninstallModule
return function(moduleIds, deleteManager, replacedObjectSet, chainUninstallModule)
  if not next(moduleIds) then moduleIds[1] = 'INSTALL SOME MODS' end

  DeleteManager = assert(deleteManager)
  ReplacedObjectSet = assert(replacedObjectSet)
  ChainUninstallModule = chainUninstallModule

  I.Settings.registerGroup {
    key = 'SettingsStaticSwitcher',
    l10n = 'StaticSwitcher',
    page = 'StaticSwitcherPage',
    name = 'StaticSwitcherSettings',
    description = '',
    permanentStorage = true,
    settings = {
      {
        renderer = 'select',
        key = 'StaticSwitcherModuleSelect',
        name = 'StaticSwitcherModuleSelection',
        description = 'StaticSwitcherModuleSelectionDesc',
        default = moduleIds[1] or 'WTF',
        argument = {
          l10n = 'StaticSwitcher',
          items = moduleIds,
        },
      },
      {
        key = 'StaticSwitcherDisableModule',
        renderer = 'checkbox',
        name = 'StaticSwitcherModuleDisableButton',
        description = 'StaticSwitcherModuleDisableDesc',
        argument = {
          l10n = 'StaticSwitcher',
          trueLabel = 'StaticSwitcherTrueLabel',
          falseLabel = 'StaticSwitcherFalseLabel',
        }
      }
    }
  }

  return uninstallModule
end
