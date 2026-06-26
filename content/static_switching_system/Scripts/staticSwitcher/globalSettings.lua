---@omw-context global

local I                   = require 'openmw.interfaces'

local staticUtil          = require 'scripts.staticswitcher.util'

local INVALID_MODULE_NAME = 'Invalid module name provided: %s. Either it does not exist, or has not replaced anything.'

---@type SSSDeleteManager?
local DeleteManager

local replacedObjectSet

--- Remove all objects which were replaced by a given module
--- After all objects from this module are inserted into the delete queue, mark this module as unusable for replacements
---@param fileName string
local function uninstallModule(fileName)
  local objectsToRemove, objectsToRemoveLength = {}, 0
  local localModuleReplacements = replacedObjectSet[fileName]

  if not localModuleReplacements then
    return staticUtil.Log(
      INVALID_MODULE_NAME:format(fileName)
    )
  end

  for newObject, oldObject in pairs(localModuleReplacements) do
    oldObject.enabled = true
    assert(DeleteManager):addObjectToDeleteQueue(newObject, true)

    objectsToRemoveLength = objectsToRemoveLength + 1
    objectsToRemove[objectsToRemoveLength] = newObject
  end

  for i = 1, objectsToRemoveLength do
    local targetObject = objectsToRemove[i]
    replacedObjectSet[fileName][targetObject] = nil
  end

  return fileName
end

---@param meshReplacementModules string[]
---@param deleteManager SSSDeleteManager
---@param replacedObjectSetIn table <openmw.GObject, ReplacedObjectData>
return function(meshReplacementModules, deleteManager, replacedObjectSetIn)
  if not next(meshReplacementModules) then meshReplacementModules[1] = 'INSTALL SOME MODS' end

  DeleteManager = assert(deleteManager)
  replacedObjectSet = assert(replacedObjectSetIn)

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
        default = meshReplacementModules[1] or 'WTF',
        argument = {
          l10n = 'StaticSwitcher',
          items = meshReplacementModules,
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
