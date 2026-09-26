---@omw-context menu

---@class S4V3RCharacterSaves
---@field autoSaveFiles string[] oldest first
---@field cellChangeSaveFile string?
---@field combatSaveFiles string[]
---@field restSaveFile string?

local DebugLog = require 'scripts.s3.S4V3R.debugLog'
local ModInfo = require 'scripts.s3.S4V3R.modInfo'

---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

local next, GSub, Remove = next, string.gsub, table.remove

local CharacterSaves, Settings, StorageGet, StorageGetCopy, StorageSet
do
  local storage = require 'openmw.storage'
  CharacterSaves, Settings =
    storage.playerSection 'S4V3RSaveFiles', storage.playerSection(ModInfo.GroupName)
  StorageGet, StorageGetCopy, StorageSet = Settings.get, CharacterSaves.getCopy, CharacterSaves.set
end

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

  local hasH3 = require('openmw.core').contentFiles.has 'H3lp Yours3lf.esp'

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
        key = 'IntervalSaveToggle',
        name = 'IntervalSaveToggleName',
        description = 'IntervalSaveToggleDesc',
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
        key = 'RestSaveToggle',
        name = 'RestSaveToggleName',
        description = 'RestSaveToggleDesc',
        default = false,
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
      hasH3 and {
        key = 'CellChangeSaveToggle',
        name = 'CellChangeSaveToggleName',
        description = 'CellChangeSaveToggleDesc',
        default = false,
        renderer = 'checkbox',
        argument = {
          l10n = 'S4V3R',
          trueLabel = 'S4V3RToggleOn',
          falseLabel = 'S4V3RToggleOff',
        },
      } or nil,
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

---@param saveDir string?
---@return S4V3RCharacterSaves
local function getCharacterSaves(saveDir)
  return saveDir and StorageGetCopy(CharacterSaves, saveDir)
    or { autoSaveFiles = {}, combatSaveFiles = {} }
end

---@param saveDir string
---@param existingSaves table<string, openmw.menu.SaveInfo>
---@param saveFile string
local function deleteSaveFile(saveDir, existingSaves, saveFile)
  local toDelete = saveFile .. '.omwsave'
  if not existingSaves[toDelete] then return end

  DebugLog('Removing save file: %s', saveFile)
  DeleteGame(saveDir, toDelete)
end

---@param saveDir string
---@param existingSaves table<string, openmw.menu.SaveInfo>
---@param saveFiles string[]
local function deleteTrackedSaves(saveDir, existingSaves, saveFiles)
  for _, saveFile in next, saveFiles do
    deleteSaveFile(saveDir, existingSaves, saveFile)
  end
end

---@param saveDir string
---@param autoSaveFiles string[]
---@param maxSaves integer
local function trimAutoSaves(saveDir, autoSaveFiles, maxSaves)
  local excessCount = #autoSaveFiles - maxSaves
  if excessCount <= 0 then return end

  local excessSaveFiles = {}
  for index = 1, excessCount do
    excessSaveFiles[index] = Remove(autoSaveFiles, 1)
  end

  deleteTrackedSaves(saveDir, GetSaves(saveDir), excessSaveFiles)
end

---@param saveInfo S4V3RSaveInfo
local function saveGame(saveInfo)
  local saveName, saveClass = saveInfo[1], saveInfo[3]

  DebugLog('Saving: %s', saveName)

  if saveClass == SaveClass.GAME_START then
    SaveGame(saveName, 'Start_Save.omwsave')
    return
  end

  local saveDir = GetCurrentSaveDir()
  local characterSaves = getCharacterSaves(saveDir)
  local autoSaveFiles, combatSaveFiles =
    characterSaves.autoSaveFiles, characterSaves.combatSaveFiles
  local combatSaveIndex = saveClass == SaveClass.COMBAT_START and 1 or 2

  local previousSaveFile
  if saveClass == SaveClass.AUTO then
    local maxSaves = StorageGet(Settings, 'MaxSaveSlots')
    if saveDir then trimAutoSaves(saveDir, autoSaveFiles, maxSaves) end

    if #autoSaveFiles >= maxSaves then previousSaveFile = autoSaveFiles[1] end
  elseif saveClass == SaveClass.REST then
    previousSaveFile = characterSaves.restSaveFile
  elseif saveClass == SaveClass.CELL_CHANGE then
    previousSaveFile = characterSaves.cellChangeSaveFile
  else
    previousSaveFile = combatSaveFiles[combatSaveIndex]
  end

  SaveGame(saveName, previousSaveFile and previousSaveFile .. '.omwsave')

  saveDir = GetCurrentSaveDir()
  if not saveDir then return end

  local savedFile = findNewestSaveFile(saveDir, saveName)
  if not savedFile then return end

  if saveClass == SaveClass.AUTO then
    if previousSaveFile then Remove(autoSaveFiles, 1) end
    autoSaveFiles[#autoSaveFiles + 1] = savedFile
  elseif saveClass == SaveClass.REST then
    characterSaves.restSaveFile = savedFile
  elseif saveClass == SaveClass.CELL_CHANGE then
    characterSaves.cellChangeSaveFile = savedFile
  else
    combatSaveFiles[combatSaveIndex] = savedFile
  end

  StorageSet(CharacterSaves, saveDir, characterSaves)
end

return {
  eventHandlers = {
    S4V3R_MENU_DELETE_ALL_SAVES = function()
      if not StorageGet(Settings, 'DeleteSavesOnDeath') then return end

      local saveDir = GetCurrentSaveDir()
      if not saveDir then return end

      local saves, characterSaves = GetSaves(saveDir), getCharacterSaves(saveDir)

      deleteTrackedSaves(saveDir, saves, characterSaves.autoSaveFiles)
      deleteTrackedSaves(saveDir, saves, characterSaves.combatSaveFiles)

      local cellChangeSaveFile, restSaveFile =
        characterSaves.cellChangeSaveFile, characterSaves.restSaveFile

      if cellChangeSaveFile then deleteSaveFile(saveDir, saves, cellChangeSaveFile) end
      if restSaveFile then deleteSaveFile(saveDir, saves, restSaveFile) end

      if saves['Start_Save.omwsave'] then DeleteGame(saveDir, 'Start_Save.omwsave') end

      StorageSet(CharacterSaves, saveDir, nil)

      require('openmw.core').quit()
    end,
    S4V3R_MENU_TriggerSave = saveGame,
  },
}
