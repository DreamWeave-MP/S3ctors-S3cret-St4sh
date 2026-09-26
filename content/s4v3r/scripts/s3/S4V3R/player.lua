---@omw-context player

---@class S4V3RSaveInfo
---@field [1] string saveName
---@field [2] integer saveSlot
---@field [3] SaveClass
---@field [4] string? previousSaveFile

---@class S4V3RSaveResult
---@field saveClass SaveClass
---@field saveFile string
---@field saveSlot integer

---@class S4V3RStoredData
---@field chargenDone boolean
---@field pendingSave S4V3RSaveInfo?
---@field saveSlot integer
---@field sinceLastSave number
---@field trackedSaves S4V3RTrackedSaves?

---@class S4V3RTrackedSaves
---@field autoSaveFiles string[]
---@field combatSaveFiles string[]

local I = require 'openmw.interfaces'
---@class openmw.interfaces
---@field FollowerDetectionUtil FDU

---@class FDU
---Returns State of each current follower.
---Script scope: Global, NPC, Creature, Player
---@field getFollowerList fun(): table<string, table>

local CallEventHandlers, ClassReviewMenu, GetRealFrameDuration, GetRealTime, GetUIMode, Minute, Regions
local hasFDU = false

do
  ClassReviewMenu, GetUIMode = I.UI.MODE.ChargenClassReview, I.UI.getMode
  Minute = require('openmw_aux.time').minute

  local core = require 'openmw.core'
  hasFDU = core.contentFiles.has 'FollowerDetectionUtil.omwscripts'
  GetRealFrameDuration, GetRealTime, Regions =
    core.getRealFrameDuration, core.getRealTime, core.regions.records

  CallEventHandlers = require('openmw_aux.util').callEventHandlers
end

local self = require 'openmw.self'

local DebugLog = require 'scripts.s3.S4V3R.debugLog'
local ModInfo = require 'scripts.s3.S4V3R.modInfo'
---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

local SaveResults = require('openmw.storage').playerSection 'S4V3RSaveResults'
local async = require 'openmw.async'
local playerStorage = require('openmw.storage').playerSection(ModInfo.GroupName)

local Assert, Next, Type, StorageGet, Format = assert, next, type, playerStorage.get, string.format

local IsCharGenFinished, IsDead, IsOnGround, IsSwimming, SendEvent, SendMenuEvent =
  self.type.isCharGenFinished,
  self.type.isDead,
  self.type.isOnGround,
  self.type.isSwimming,
  self.sendEvent,
  self.type.sendMenuEvent

local chargenDone = IsCharGenFinished(self)

local function nullFunction() end

local currentUpdateHandler = nullFunction

local actorsInCombat, saveCompletionHandlers = {}, {}
local awaitingSaveResult, isInCombat, saveSlot, sinceLastSave = false, false, 1, 0

---@type number?
local lastCombatSaveTime

---@type S4V3RTrackedSaves
local trackedSaves = { autoSaveFiles = {}, combatSaveFiles = {} }

local CombatSaveCooldown, CombatSavesEnabled, DeleteSavesOnDeath, SaveInterval, SavePrefix, MaxSaveSlots, StartSaveEnabled, S4V3RActive =
  StorageGet(playerStorage, 'CombatSaveCooldown') * Minute,
  StorageGet(playerStorage, 'CombatSaveToggle'),
  StorageGet(playerStorage, 'DeleteSavesOnDeath'),
  StorageGet(playerStorage, 'SaveInterval') * Minute,
  StorageGet(playerStorage, 'SavePrefix'),
  StorageGet(playerStorage, 'MaxSaveSlots'),
  StorageGet(playerStorage, 'StartSaveToggle'),
  StorageGet(playerStorage, 'S4V3RActive')

---@type S4V3RSaveInfo
local SaveEventData = { '', 1, SaveClass.AUTO }

---@return boolean? allowedToSave
local function allowedToSave()
  if GetUIMode() then return DebugLog 'Cannot save - Menu is open' end

  if isInCombat then return DebugLog 'Cannot save - Player in combat' end

  if not IsOnGround(self) or IsSwimming(self) then
    return DebugLog 'Cannot save - Player not on solid ground'
  end

  return true
end

---@param currentCell openmw.core.LCell
local function getCurrentLocation(currentCell)
  local location = currentCell.displayName

  if location == '' then
    local currentRegion = Regions[currentCell.region]
    if currentRegion then location = currentRegion.name end
  end

  return location
end

---@param saveName string
---@param saveClass SaveClass
---@param previousSaveFile string?
local function emitSaveEvent(saveName, saveClass, previousSaveFile)
  SaveEventData[1], SaveEventData[2], SaveEventData[3], SaveEventData[4] =
    saveName, saveSlot, saveClass, previousSaveFile

  awaitingSaveResult = saveClass ~= SaveClass.GAME_START

  SendMenuEvent(self, 'S4V3R_MENU_TriggerSave', SaveEventData)
  SendEvent(self, 'S4V3R_PLAYER_SaveComplete')

  sinceLastSave = 0
end

local function autoSaveHandler()
  if IsDead(self) then
    currentUpdateHandler = nullFunction
    return
  end

  sinceLastSave = sinceLastSave + GetRealFrameDuration()

  if sinceLastSave < SaveInterval or not allowedToSave() then return end

  local location = getCurrentLocation(self.cell)

  emitSaveEvent(
    Format('%s%s, %s', SavePrefix, saveSlot, location),
    SaveClass.AUTO,
    trackedSaves.autoSaveFiles[saveSlot]
  )

  saveSlot = saveSlot >= MaxSaveSlots and 1 or saveSlot + 1
end

local function chargenCheck()
  if not IsCharGenFinished(self) then return end

  DebugLog 'Chargen is complete! AutoSave enabled.'

  currentUpdateHandler, chargenDone = autoSaveHandler, true
end

local function selectUpdateHandler()
  if not S4V3RActive then return end

  currentUpdateHandler = chargenDone and autoSaveHandler or chargenCheck
end

SaveResults:subscribe(async:callback(function(_, key)
  ---@type S4V3RSaveResult?
  local saveResult = StorageGet(SaveResults, key)
  if not saveResult then return end

  awaitingSaveResult = false

  local saveClass, saveFile = saveResult.saveClass, saveResult.saveFile
  if saveClass == SaveClass.AUTO then
    trackedSaves.autoSaveFiles[saveResult.saveSlot] = saveFile
  elseif saveClass == SaveClass.COMBAT_START then
    trackedSaves.combatSaveFiles[1] = saveFile
  elseif saveClass == SaveClass.COMBAT_END then
    trackedSaves.combatSaveFiles[2] = saveFile
  end
end))

playerStorage:subscribe(async:callback(function(_, key)
  local value = StorageGet(playerStorage, key)

  if key == 'MaxSaveSlots' then
    MaxSaveSlots = value
    if saveSlot > MaxSaveSlots then saveSlot = 1 end
  elseif key == 'SaveInterval' then
    SaveInterval = value * Minute
  elseif key == 'SavePrefix' then
    SavePrefix = value
  elseif key == 'CombatSaveCooldown' then
    CombatSaveCooldown = value * Minute
  elseif key == 'CombatSaveToggle' then
    CombatSavesEnabled = value
  elseif key == 'DeleteSavesOnDeath' then
    DeleteSavesOnDeath = value
  elseif key == 'StartSaveToggle' then
    StartSaveEnabled = value
  elseif key == 'S4V3RActive' then
    currentUpdateHandler, S4V3RActive = value and chargenCheck or nullFunction, value
    DebugLog('S4V3R has been %s!', S4V3RActive and 'enabled' or 'disabled')
  end
end))

---@class openmw.interfaces
---@field S4V3R S4V3RInterface

---@class S4V3RInterface
local S4V3RInterface = {
  ---@param handler fun(saveName: string, saveSlot: integer): boolean?
  addSaveCompletionHandler = function(handler)
    Assert(
      Type(handler) == 'function',
      'S4V3R.addSaveCompletionHandler was passed a non-function value!'
    )

    saveCompletionHandlers[#saveCompletionHandlers + 1] = handler
  end,
  ---@return boolean canSave
  canSave = function() return sinceLastSave >= SaveInterval and allowedToSave() ~= nil end,
  ---@return integer
  getCurrentSaveSlot = function() return saveSlot end,
  ---@return integer
  getMaxSaves = function() return MaxSaveSlots end,
  ---@return number timeBetweenSaves
  getSaveInterval = function() return SaveInterval end,
  ---@return number timeRemaining
  untilNextSave = function() return SaveInterval - sinceLastSave end,
  version = 1,
}

return {
  engineHandlers = {
    onInit = selectUpdateHandler,
    ---@param data S4V3RStoredData?
    onLoad = function(data)
      if data then
        chargenDone, saveSlot, sinceLastSave, trackedSaves =
          data.chargenDone or false,
          data.saveSlot or 1,
          data.sinceLastSave or 0,
          data.trackedSaves or trackedSaves

        if data.pendingSave then SendMenuEvent(self, 'S4V3R_MENU_ResolveSave', data.pendingSave) end
      end

      selectUpdateHandler()
    end,
    ---@return S4V3RStoredData
    onSave = function()
      return {
        chargenDone = chargenDone,
        pendingSave = awaitingSaveResult and SaveEventData or nil,
        saveSlot = saveSlot,
        sinceLastSave = sinceLastSave,
        trackedSaves = trackedSaves,
      }
    end,
    onUpdate = function() currentUpdateHandler() end,
  },
  eventHandlers = {
    Died = function()
      if not DeleteSavesOnDeath then return end
      SendMenuEvent(self, 'S4V3R_MENU_DELETE_ALL_SAVES', trackedSaves)
    end,
    OMWMusicCombatTargetsChanged = function(targetData)
      local actor, targetInCombat, wasInCombat =
        targetData.actor, not not targetData.targets[1], isInCombat

      local followerList = hasFDU and I.FollowerDetectionUtil.getFollowerList() or nil

      if followerList and followerList[actor.id] then return end

      local fightingMe = false
      if targetInCombat then
        local myId = self.id

        for i = 1, #targetData.targets do
          local targetId = targetData.targets[i].id

          if targetId == myId then
            fightingMe = true
            break
          end

          if followerList and followerList[targetId] then
            fightingMe = true
            break
          end
        end
      end

      local wasFightingMe = actorsInCombat[actor.id] ~= nil
      actorsInCombat[actor.id] = fightingMe and actor or nil
      isInCombat = Next(actorsInCombat) ~= nil

      local shouldSkipSave = not S4V3RActive
        or not CombatSavesEnabled
        or not chargenDone
        or not (fightingMe or wasFightingMe)
        or wasInCombat == isInCombat
        or IsDead(self)

      if shouldSkipSave then return end

      currentUpdateHandler = isInCombat and nullFunction or autoSaveHandler

      local currentTime = GetRealTime()
      if lastCombatSaveTime and currentTime - lastCombatSaveTime < CombatSaveCooldown then
        DebugLog 'Combat state changed, but combat saves are on cooldown.'
        return
      end

      lastCombatSaveTime = currentTime

      DebugLog 'Combat state changed! Triggering autosave . . .'
      local location = getCurrentLocation(self.cell)

      local saveName =
        Format('%sCombat %s Save, %s', SavePrefix, isInCombat and 'Start' or 'End', location)

      local saveType, combatSaveIndex =
        isInCombat and SaveClass.COMBAT_START or SaveClass.COMBAT_END, isInCombat and 1 or 2

      emitSaveEvent(saveName, saveType, trackedSaves.combatSaveFiles[combatSaveIndex])
    end,
    S4V3R_PLAYER_SaveComplete = function()
      CallEventHandlers(
        saveCompletionHandlers,
        SaveEventData[1],
        SaveEventData[2],
        SaveEventData[3]
      )
    end,
    UiModeChanged = function(modeChangeData)
      if
        not S4V3RActive
        or modeChangeData.newMode
        or not StartSaveEnabled
        or modeChangeData.oldMode ~= ClassReviewMenu
      then
        return
      end

      emitSaveEvent('Start Save', SaveClass.GAME_START, 'Start_Save')

      currentUpdateHandler, chargenDone = autoSaveHandler, true

      DebugLog 'CharGen has completed. S4V3R is active!'
    end,
  },
  interfaceName = ModInfo.Name,
  interface = S4V3RInterface,
}
