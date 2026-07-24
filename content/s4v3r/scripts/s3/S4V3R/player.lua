---@omw-context player

---@class S4V3RSaveInfo
---@field [1] string saveName
---@field [2] integer saveSlot
---@field [3] SaveClass

---@class S4V3RStoredData
---@field chargenDone boolean
---@field saveSlot integer
---@field sinceLastSave number

local CallEventHandlers, ClassReviewMenu, GetRealFrameDuration, GetUIMode, Minute, Regions
do
  local I = require 'openmw.interfaces'
  ClassReviewMenu, GetUIMode = I.UI.MODE.ChargenClassReview, I.UI.getMode
  Minute = require('openmw_aux.time').minute

  local core = require 'openmw.core'
  GetRealFrameDuration, Regions = core.getRealFrameDuration, core.regions.records

  CallEventHandlers = require('openmw_aux.util').callEventHandlers
end

local self = require 'openmw.self'

local DebugLog = require 'scripts.s3.S4V3R.debugLog'
local ModInfo = require 'scripts.s3.S4V3R.modInfo'
---@type SaveClasses
local SaveClass = require 'scripts.s3.S4V3R.saveClass'

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
local isInCombat, saveSlot, sinceLastSave = false, 1, 0

local CombatSavesEnabled, SaveInterval, MaxSaveSlots, StartSaveEnabled, S4V3RActive =
  StorageGet(playerStorage, 'CombatSaveToggle'),
  StorageGet(playerStorage, 'SaveInterval') * Minute,
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
local function emitSaveEvent(saveName, saveClass)
  SaveEventData[1], SaveEventData[2], SaveEventData[3] = saveName, saveSlot, saveClass

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

  emitSaveEvent(Format('%s: %s, %s', ModInfo.Name, saveSlot, location), SaveClass.AUTO)

  saveSlot = saveSlot == MaxSaveSlots and 1 or saveSlot + 1
end

local function chargenCheck()
  if not IsCharGenFinished(self) then return end

  DebugLog 'Chargen is complete! AutoSave enabled.'

  currentUpdateHandler, chargenDone = autoSaveHandler, true
end

playerStorage:subscribe(require('openmw.async'):callback(function(_, key)
  local value = StorageGet(playerStorage, key)

  if key == 'MaxSaveSlots' then
    MaxSaveSlots = value
    if saveSlot > MaxSaveSlots then saveSlot = 1 end
  elseif key == 'SaveInterval' then
    SaveInterval = value * Minute
  elseif key == 'CombatSaveToggle' then
    CombatSavesEnabled = value
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
    ---@param data S4V3RStoredData?
    onLoad = function(data)
      if data then
        chargenDone, saveSlot, sinceLastSave =
          data.chargenDone or false, data.saveSlot or 1, data.sinceLastSave or 0
      end

      if not S4V3RActive then return end

      currentUpdateHandler = chargenDone and autoSaveHandler or chargenCheck
    end,
    ---@return S4V3RStoredData
    onSave = function()
      return {
        chargenDone = chargenDone,
        saveSlot = saveSlot,
        sinceLastSave = sinceLastSave,
      }
    end,
    onUpdate = function() currentUpdateHandler() end,
  },
  eventHandlers = {
    OMWMusicCombatTargetsChanged = function(targetData)
      local actor, targetInCombat, wasInCombat =
        targetData.actor, not not targetData.targets[1], isInCombat

      actorsInCombat[actor.id] = targetInCombat and actor or nil

      isInCombat = Next(actorsInCombat) ~= nil

      local shouldSkipSave = not S4V3RActive
        or not CombatSavesEnabled
        or not chargenDone
        or wasInCombat == isInCombat
        or IsDead(self)

      if shouldSkipSave then return end

      currentUpdateHandler = isInCombat and nullFunction or autoSaveHandler

      DebugLog 'Combat state changed! Triggering autosave . . .'
      local location = getCurrentLocation(self.cell)

      local saveName = Format('S4V3R Combat %s Save, %s', isInCombat and 'Start' or 'End', location)

      local saveType = isInCombat and SaveClass.COMBAT_START or SaveClass.COMBAT_END
      emitSaveEvent(saveName, saveType)
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

      emitSaveEvent('Start Save', SaveClass.GAME_START)

      currentUpdateHandler, chargenDone = autoSaveHandler, true

      DebugLog 'CharGen has completed. S4V3R is active!'
    end,
  },
  interfaceName = ModInfo.Name,
  interface = S4V3RInterface,
}
