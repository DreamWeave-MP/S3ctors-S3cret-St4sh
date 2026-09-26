---@omw-context menu

local DebugLog = require 'scripts.s3.S4V3R.debugLog'
local ModInfo = require 'scripts.s3.S4V3R.modInfo'

---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

local next, GSub = next, string.gsub

local SaveResults, StorageSet
do
  local storage = require 'openmw.storage'
  SaveResults = storage.playerSection 'S4V3RSaveResults'
  SaveResults:setLifeTime(storage.LIFE_TIME.Temporary)
  StorageSet = SaveResults.set
end

---@type S4V3RSaveResult
local SaveResult = { saveClass = SaveClass.AUTO, saveFile = '', saveSlot = 1 }

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
        key = 'CombatSaveCooldown',
        name = 'CombatSaveCooldownName',
        description = 'CombatSaveCooldownDesc',
        default = 1,
        renderer = 'number',
        min = 0,
        max = 60,
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

  for saveFile, saveInfo in next, GetSaves(saveDir) do
    if
      saveInfo.description == saveName
      and (not newestCreationTime or saveInfo.creationTime > newestCreationTime)
    then
      newestSaveFile, newestCreationTime = saveFile, saveInfo.creationTime
    end
  end

  return newestSaveFile and GSub(newestSaveFile, '%.omwsave$', '')
end

---@param saveDir string
---@param existingSaves table<string, openmw.menu.SaveInfo>
---@param saveFiles string[]
local function deleteTrackedSaves(saveDir, existingSaves, saveFiles)
  for _, saveFile in next, saveFiles do
    local toDelete = saveFile .. '.omwsave'
    if existingSaves[toDelete] then
      DebugLog('Removing save file due to Ironman setting: %s', saveFile)
      DeleteGame(saveDir, toDelete)
    end
  end
end

---@param saveInfo S4V3RSaveInfo
local function reportSaveFile(saveInfo)
  local saveDir = GetCurrentSaveDir()
  if not saveDir then return end

  local saveFile = findNewestSaveFile(saveDir, saveInfo[1])
  if not saveFile then return end

  SaveResult.saveClass, SaveResult.saveFile, SaveResult.saveSlot =
    saveInfo[3], saveFile, saveInfo[2]

  StorageSet(SaveResults, 'LastSave', SaveResult)
end

---@param saveInfo S4V3RSaveInfo
local function saveGame(saveInfo)
  local saveName, previousSaveFile = saveInfo[1], saveInfo[4]

  DebugLog('Saving: %s', saveName)
  SaveGame(saveName, previousSaveFile and previousSaveFile .. '.omwsave')

  if saveInfo[3] == SaveClass.GAME_START then return end

  reportSaveFile(saveInfo)
end

return {
  eventHandlers = {
    ---@param trackedSaves S4V3RTrackedSaves
    S4V3R_MENU_DELETE_ALL_SAVES = function(trackedSaves)
      if
        not require('openmw.storage').playerSection(ModInfo.GroupName):get 'DeleteSavesOnDeath'
      then
        return
      end

      local saveDir = GetCurrentSaveDir()
      if not saveDir then return end

      local saves = GetSaves(saveDir)

      deleteTrackedSaves(saveDir, saves, trackedSaves.autoSaveFiles)
      deleteTrackedSaves(saveDir, saves, trackedSaves.combatSaveFiles)

      if saves['Start_Save.omwsave'] then DeleteGame(saveDir, 'Start_Save.omwsave') end

      require('openmw.core').quit()
    end,
    S4V3R_MENU_ResolveSave = reportSaveFile,
    S4V3R_MENU_TriggerSave = saveGame,
  },
}
