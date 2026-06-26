---@omw-context global

local async               = require 'openmw.async'
local storage             = require 'openmw.storage'
local I                   = require 'openmw.interfaces'

local staticUtil          = require 'scripts.staticswitcher.util'

local INVALID_MODULE_NAME = 'Invalid module name provided: %s. Either it does not exist, or has not replaced anything.'

local addObjectToDeleteQueue, replacedObjectSet

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
    addObjectToDeleteQueue(newObject, true)

    objectsToRemoveLength = objectsToRemoveLength + 1
    objectsToRemove[objectsToRemoveLength] = newObject
  end

  for i = 1, objectsToRemoveLength do
    local targetObject = objectsToRemove[i]
    replacedObjectSet[fileName][targetObject] = nil
  end

  return fileName
end

local settingsGroup = storage.globalSection('SettingsStaticSwitcher')
if settingsGroup:get('StaticSwitcherDisableModule') then settingsGroup:set('StaticSwitcherDisableModule', false) end

settingsGroup:subscribe(
  async:callback(
    function(_, key)
      if key == 'StaticSwitcherDisableModule' then
        uninstallModule(settingsGroup:get('StaticSwitcherModuleSelect'))
      end
    end
  )
)

---@param meshReplacementModules string[]
---@param addObjectToDeleteQueueIn fun(object: openmw.GObject, removeOrDisable: boolean)
---@param replacedObjectSetIn table <openmw.GObject, ReplacedObjectData>
return function(meshReplacementModules, addObjectToDeleteQueueIn, replacedObjectSetIn)
  if not next(meshReplacementModules) then meshReplacementModules[1] = 'INSTALL SOME MODS' end
  addObjectToDeleteQueue = assert(addObjectToDeleteQueueIn)
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
