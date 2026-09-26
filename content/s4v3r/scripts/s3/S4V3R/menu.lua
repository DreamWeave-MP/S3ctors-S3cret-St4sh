---@omw-context menu

local DebugLog = require 'scripts.s3.S4V3R.debugLog'
local ModInfo = require 'scripts.s3.S4V3R.modInfo'

---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

local pairs, GSub = pairs, string.gsub

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
        argument = {
          l10n = 'S4V3R',
          trueLabel = 'S4V3RToggleOn',
          falseLabel = 'S4V3RToggleOff',
        },
      },
      {
        key = 'DeleteSavesOnDeath',
        name = 'DeleteSavesName',
        description = 'DeleteSavesDesc',
        default = false,
        renderer = 'checkbox',
        argument = {
          l10n = 'S4V3R',
          trueLabel = 'S4V3RToggleOn',
          falseLabel = 'S4V3RToggleOff',
        },
      },
      {
        key = 'SavePrefix',
        name = 'SavePrefixName',
        description = 'SavePrefixDesc',
        default = '',
        renderer = 'textLine',
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
---@param saveDir string
---@param saveName string
---@return string? saveFile
local function findNewestSaveFile(saveDir, saveName)
  local newestSaveFile, newestCreationTime

  for saveFile, saveInfo in pairs(GetSaves(saveDir)) do
    if
      saveInfo.description == saveName
      and (not newestCreationTime or saveInfo.creationTime > newestCreationTime)
    then
      newestSaveFile, newestCreationTime = saveFile, saveInfo.creationTime
    end
  end

  return newestSaveFile and GSub(newestSaveFile, '%.omwsave$', '')
end

---@param saveInfo S4V3RSaveInfo
local function saveGame(saveInfo)
  local saveName, saveSlot, saveType = saveInfo[1], saveInfo[2], saveInfo[3]

  local trackedSaves, trackedIndex, storageKey, previousSaveFile
  if saveType == SaveClass.AUTO then
    trackedSaves, trackedIndex, storageKey = SaveSlotsToFilenames, saveSlot, 'AutoSlots'
  elseif saveType == SaveClass.COMBAT_START then
    trackedSaves, trackedIndex, storageKey = CombatSaveFiles, 1, 'CombatSlots'
  elseif saveType == SaveClass.COMBAT_END then
    trackedSaves, trackedIndex, storageKey = CombatSaveFiles, 2, 'CombatSlots'
  elseif saveType == SaveClass.GAME_START then
    previousSaveFile = 'Start_Save'
  end

  if trackedSaves then previousSaveFile = trackedSaves[trackedIndex] end

  DebugLog('Saving: %s', saveName)
  SaveGame(saveName, previousSaveFile and previousSaveFile .. '.omwsave')

  local saveDir = GetCurrentSaveDir()
  if not trackedSaves or not saveDir then return end

  local savedFile = findNewestSaveFile(saveDir, saveName)
  if not savedFile then return end

  trackedSaves[trackedIndex] = savedFile
  StorageSet(SavedSlots, storageKey, trackedSaves)
end

return {
  eventHandlers = {
    S4V3R_MENU_DELETE_ALL_SAVES = function()
      if
        not require('openmw.storage').playerSection(ModInfo.GroupName):get 'DeleteSavesOnDeath'
      then
        return
      end

      local saveDir = GetCurrentSaveDir()
      if not saveDir then return end

      local saves = GetSaves(saveDir)

      for _, saveFilePath in pairs(SaveSlotsToFilenames) do
        local toDelete = saveFilePath .. '.omwsave'
        if saves[toDelete] then
          DebugLog('Removing save file due to Ironman setting: %s', saveFilePath)
          DeleteGame(saveDir, toDelete)
        end
      end

      SaveSlotsToFilenames = {}
      StorageSet(SavedSlots, 'AutoSlots', SaveSlotsToFilenames)

      if saves['Start_Save.omwsave'] then DeleteGame(saveDir, 'Start_Save.omwsave') end

      for _, saveFilePath in pairs(CombatSaveFiles) do
        local toDelete = saveFilePath .. '.omwsave'
        if saves[toDelete] then
          DebugLog('Removing save file due to Ironman setting: %s', saveFilePath)
          DeleteGame(saveDir, toDelete)
        end
      end

      CombatSaveFiles = {}
      StorageSet(SavedSlots, 'CombatSlots', CombatSaveFiles)

      require('openmw.core').quit()
    end,
    S4V3R_MENU_TriggerSave = saveGame,
  },
}
