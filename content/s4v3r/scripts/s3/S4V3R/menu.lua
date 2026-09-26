---@omw-context menu

---@class S4V3RCharacterSaves
---@field autoSlots string[]
---@field combatSlots string[]

local DebugLog = require 'scripts.s3.S4V3R.debugLog'
local ModInfo = require 'scripts.s3.S4V3R.modInfo'

---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

local next, GSub = next, string.gsub

local CharacterSaves = require('openmw.storage').playerSection 'S4V3RCharacterSaves'
local LegacySavedSlots = require('openmw.storage').playerSection 'S4V3RSavedSlots'
local StorageGetCopy, StorageSet = CharacterSaves.getCopy, CharacterSaves.set

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

---@param legacySaveFiles string[]?
---@param existingSaves table<string, openmw.menu.SaveInfo>
---@return string[]
local function adoptLegacySaveFiles(legacySaveFiles, existingSaves)
  local adoptedSaveFiles = {}

  for index, saveFile in next, legacySaveFiles or {} do
    if existingSaves[saveFile .. '.omwsave'] then adoptedSaveFiles[index] = saveFile end
  end

  return adoptedSaveFiles
end

---@param saveDir string
---@return S4V3RCharacterSaves
local function getCharacterSaves(saveDir)
  local characterSaves = StorageGetCopy(CharacterSaves, saveDir)
  if characterSaves then return characterSaves end

  local existingSaves = GetSaves(saveDir)

  return {
    autoSlots = adoptLegacySaveFiles(StorageGetCopy(LegacySavedSlots, 'AutoSlots'), existingSaves),
    combatSlots = adoptLegacySaveFiles(
      StorageGetCopy(LegacySavedSlots, 'CombatSlots'),
      existingSaves
    ),
  }
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
local function saveGame(saveInfo)
  local saveName, saveSlot, saveType = saveInfo[1], saveInfo[2], saveInfo[3]

  local saveDir = GetCurrentSaveDir()
  local characterSaves = saveDir and getCharacterSaves(saveDir)
    or { autoSlots = {}, combatSlots = {} }

  local trackedSaves, trackedIndex, previousSaveFile
  if saveType == SaveClass.AUTO then
    trackedSaves, trackedIndex = characterSaves.autoSlots, saveSlot
  elseif saveType == SaveClass.COMBAT_START then
    trackedSaves, trackedIndex = characterSaves.combatSlots, 1
  elseif saveType == SaveClass.COMBAT_END then
    trackedSaves, trackedIndex = characterSaves.combatSlots, 2
  elseif saveType == SaveClass.GAME_START then
    previousSaveFile = 'Start_Save'
  end

  if trackedSaves then previousSaveFile = trackedSaves[trackedIndex] end

  DebugLog('Saving: %s', saveName)
  SaveGame(saveName, previousSaveFile and previousSaveFile .. '.omwsave')

  saveDir = GetCurrentSaveDir()
  if not trackedSaves or not saveDir then return end

  local savedFile = findNewestSaveFile(saveDir, saveName)
  if not savedFile then return end

  trackedSaves[trackedIndex] = savedFile
  StorageSet(CharacterSaves, saveDir, characterSaves)
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

      local saves, characterSaves = GetSaves(saveDir), getCharacterSaves(saveDir)

      deleteTrackedSaves(saveDir, saves, characterSaves.autoSlots)
      deleteTrackedSaves(saveDir, saves, characterSaves.combatSlots)

      if saves['Start_Save.omwsave'] then DeleteGame(saveDir, 'Start_Save.omwsave') end

      StorageSet(CharacterSaves, saveDir, { autoSlots = {}, combatSlots = {} })

      require('openmw.core').quit()
    end,
    S4V3R_MENU_TriggerSave = saveGame,
  },
}
