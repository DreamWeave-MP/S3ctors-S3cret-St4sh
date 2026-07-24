---@omw-context menu

local DebugLog = require 'scripts.s3.S4V3R.debugLog'

---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

local GSub = string.gsub

local SavedSlots = require('openmw.storage').playerSection 'S4V3RSavedSlots'
local StorageGetCopy, StorageSet = SavedSlots.getCopy, SavedSlots.set

---@type string[]
local SaveSlotsToFilenames = StorageGetCopy(SavedSlots, 'AutoSlots') or {}

---@type string[]
local CombatSaveFiles = StorageGetCopy(SavedSlots, 'CombatSlots') or {}

local DeleteGame, GetCurrentSaveDir, GetSaves, SaveGame
do
  local menu = require 'openmw.menu'
  DeleteGame, GetCurrentSaveDir, GetSaves, SaveGame =
    menu.deleteGame, menu.getCurrentSaveDir, menu.getSaves, menu.saveGame

  local I = require 'openmw.interfaces'
  local ModInfo = require 'scripts.s3.S4V3R.modInfo'

  I.Settings.registerPage {
    key = ModInfo.Name,
    l10n = ModInfo.Name,
    name = ModInfo.Name,
    description = 'S4V3RDesc',
  }

  I.Settings.registerGroup {
    key = ModInfo.GroupName,
    page = ModInfo.Name,
    l10n = ModInfo.Name,
    name = 'S4V3ROptions',
    permanentStorage = true,
    settings = {
      {
        key = 'S4V3RActive',
        name = 'S4V3RActiveName',
        description = 'S4V3RActiveDesc',
        default = true,
        renderer = 'checkbox',
        argument = {
          l10n = 'S4V3R',
          trueLabel = 'S4V3RToggleOn',
          falseLabel = 'S4V3RToggleOff',
        },
      },
      {
        key = 'SaveInterval',
        name = 'SaveIntervalName',
        description = 'SaveIntervalDesc',
        default = 9,
        renderer = 'number',
        min = 1,
        max = 60,
      },
      {
        key = 'MaxSaveSlots',
        name = 'MaxSaveSlotsName',
        description = 'MaxSaveSlotsDesc',
        default = 10,
        renderer = 'number',
        min = 1,
        max = 100,
      },
      {
        key = 'CombatSaveToggle',
        name = 'CombatSaveToggleName',
        description = 'CombatSaveToggleDesc',
        default = true,
        renderer = 'checkbox',
        argument = {
          l10n = 'S4V3R',
          trueLabel = 'S4V3RToggleOn',
          falseLabel = 'S4V3RToggleOff',
        },
      },
      {
        key = 'StartSaveToggle',
        name = 'StartSaveToggleName',
        description = 'StartSaveToggleDesc',
        default = true,
        renderer = 'checkbox',
      },
      {
        key = 'DebugEnable',
        name = 'DebugEnableName',
        description = 'DebugEnableDesc',
        default = false,
        renderer = 'checkbox',
        argument = {
          l10n = 'S4V3R',
          trueLabel = 'S4V3RToggleOn',
          falseLabel = 'S4V3RToggleOff',
        },
      },
    },
  }
end
local function saveNameToFilePath(saveName) return GSub(saveName, '[:\',. ]', '_') end

---@param saveInfo S4V3RSaveInfo
local function saveGame(saveInfo)
  local saveName, saveType = saveInfo[1], saveInfo[3]

  local newSaveFile, saveDir = saveNameToFilePath(saveName), GetCurrentSaveDir()

  DebugLog('Saving: %s', newSaveFile)

  local saveSlotString, saveToDelete
  if saveType == SaveClass.AUTO then
    local saveSlot = saveInfo[2]

    saveSlotString, saveToDelete, SaveSlotsToFilenames[saveSlot] =
      'S4V3R_' .. saveSlot, SaveSlotsToFilenames[saveSlot], newSaveFile

    StorageSet(SavedSlots, 'AutoSlots', SaveSlotsToFilenames)
  elseif saveType == SaveClass.COMBAT_START then
    saveSlotString, saveToDelete, CombatSaveFiles[1] =
      'S4V3R_COMBAT_START', CombatSaveFiles[1], newSaveFile

    StorageSet(SavedSlots, 'CombatSlots', CombatSaveFiles)
  elseif saveType == SaveClass.COMBAT_END then
    saveSlotString, saveToDelete, CombatSaveFiles[2] =
      'S4V3R_COMBAT_END', CombatSaveFiles[2], newSaveFile

    StorageSet(SavedSlots, 'CombatSlots', CombatSaveFiles)
  elseif saveType == SaveClass.GAME_START then
    saveSlotString, saveToDelete = 'S4V3R_START_SAVE', 'Start_Save'
  end

  if saveDir then
    if saveToDelete then
      saveToDelete = saveToDelete .. '.omwsave'
      if GetSaves(saveDir)[saveToDelete] then
        DebugLog('Deleting existing save file: %s', saveToDelete)
        DeleteGame(saveDir, saveToDelete)
      end
    end
  end

  SaveGame(saveName, saveSlotString)
end

return {
  eventHandlers = {
    S4V3R_MENU_TriggerSave = saveGame,
  },
}
