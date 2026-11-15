---@omw-context global

local core = require 'openmw.core'
local types = require 'openmw.types'
local world = require 'openmw.world'

local BatchCache = require 'Scripts.staticSwitcher.batchCache'
local ObjectCleanup = require 'Scripts.staticSwitcher.objectCleanup'
local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'

local DebugLog, WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  DebugLog = logger.debug
  WarnLog = logger.warn
end

local assert, next = assert, next
local Floor, Min = math.floor, math.min
local StrFormat = string.format
local Remove = table.remove

local POLL_INTERVAL_SECONDS = 0.5
local SWEEP_OBJECTS_PER_FRAME = 16

--- A trigger that starts more sweeps than this inside the window is flapping, not signalling.
local MAX_SWEEP_STARTS = 4
local SWEEP_START_WINDOW_SECONDS = 10

local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400

local Player = world.players[1]

---@type table<string, SSSSweep>
local Sweeps

---@type table<string, string>
local JournalSweepKeys

---@type SSSTriggers
local Triggers

---@type string[]
local PendingSweepKeys = {}

---@type table<string, true>
local IsSweepPending = {}

---@type table<string, true>
local SuspendedSweepKeys = {}

---@type table<string, number[]>
local SweepStartTimes = {}

---@type SSSActiveSweep?
local ActiveSweep

local secondsSincePoll = 0

---@type integer?, integer?
local knownHour, knownDay

---@type string|false|nil, string?
local knownWeatherId, knownWeatherLocation

---@type table<string, integer|false>
local KnownQuestStages = {}

---@type string?
local knownPlayerCellId

--- Requests are a set: a trigger that fires again before its sweep starts is not queued twice.
---@param sweepKey string
local function requestSweep(sweepKey)
  if not Sweeps[sweepKey] or IsSweepPending[sweepKey] or SuspendedSweepKeys[sweepKey] then
    return
  end

  IsSweepPending[sweepKey] = true
  PendingSweepKeys[#PendingSweepKeys + 1] = sweepKey
end

local function pollClock()
  local gameTime = core.getGameTime()
  local hour, day = Floor(gameTime / SECONDS_PER_HOUR), Floor(gameTime / SECONDS_PER_DAY)

  if hour ~= knownHour then
    if knownHour then requestSweep 'hour' end
    knownHour = hour
  end

  if day ~= knownDay then
    if knownDay then requestSweep 'day' end
    knownDay = day
  end
end

--- SSS can have several weather requests outstanding, and the engine drops a queued one when
--- a later one arrives. Seeing a requested weather settles it and every request made before it.
---@param weatherId string|false
---@return boolean wasRequested
local function wasWeatherRequestedBySSS(weatherId)
  local expectedWeatherIds = TriggerContext.expectedWeatherIds

  for expectedIdx = #expectedWeatherIds, 1, -1 do
    if expectedWeatherIds[expectedIdx] == weatherId then
      for _ = 1, expectedIdx do
        Remove(expectedWeatherIds, 1)
      end

      return true
    end
  end

  return false
end

--- Weather differing because the player moved somewhere else is not a weather change, and
--- neither is a change SSS asked for itself through `set_weather`.
local function pollWeather()
  local playerCell = Player.cell
  if not playerCell then return end

  local weather = core.weather.getCurrent(playerCell)
  local weatherId = weather and weather.recordId or false
  local weatherLocation = playerCell.region or playerCell.id

  if weatherLocation ~= knownWeatherLocation then
    knownWeatherLocation, knownWeatherId = weatherLocation, weatherId
    TriggerContext.expectedWeatherIds = {}
    return
  end

  if weatherId == knownWeatherId then return end
  knownWeatherId = weatherId

  if not wasWeatherRequestedBySSS(weatherId) then requestSweep 'weather' end
end

local function pollJournal()
  local quests = types.Player.quests(Player)

  for questId, sweepKey in next, JournalSweepKeys do
    local quest = quests[questId]
    local stage = quest and quest.stage or false
    local knownStage = KnownQuestStages[questId]

    if stage ~= knownStage then
      if knownStage ~= nil then requestSweep(sweepKey) end
      KnownQuestStages[questId] = stage
    end
  end
end

--- Unlike the world triggers, this fires on the first poll after a load: the player is already
--- standing in a cell, and a rule that must not repeat says so with `once`.
--- Arriving where an SSS teleport sent the player is not an entry, or two rules that send the
--- player to each other's cells would do so forever.
local function pollPlayerCell()
  local playerCell = Player.cell
  if not playerCell then return end

  local playerCellId = playerCell.id

  -- A player moved by a pass that was then abandoned turns up at the destination before being
  -- put back. While that return lasts, wherever the player is seen is noted, not entered.
  if ObjectCleanup.getReturn(Player) then
    knownPlayerCellId = playerCellId
    ObjectCleanup.observeReturn(Player, playerCellId)
    return
  end

  if playerCellId == knownPlayerCellId then return end
  knownPlayerCellId = playerCellId

  local wasSentBySSS = playerCellId == TriggerContext.expectedPlayerCellId
  TriggerContext.expectedPlayerCellId = nil

  if not wasSentBySSS then Triggers.dispatch('cell_enter', Player) end
end

--- The first poll after a load only records what the world looks like; no sweep starts for it.
---@param dt number simulation seconds since the last frame; zero while paused
local function poll(dt)
  secondsSincePoll = secondsSincePoll + dt
  if secondsSincePoll < POLL_INTERVAL_SECONDS then return end
  secondsSincePoll = 0

  if Sweeps.hour or Sweeps.day then pollClock() end
  if Sweeps.weather then pollWeather() end
  if next(JournalSweepKeys) then pollJournal() end
  if Triggers.isArmed 'cell_enter' then pollPlayerCell() end
end

---@return openmw.core.GCell[] cells the player's cell and, outdoors, the eight cells around it
local function collectNearbyCells()
  local playerCell = Player.cell
  if not playerCell then return {} end
  if not playerCell.isExterior then return { playerCell } end

  local cells = {}

  for gridOffsetX = -1, 1 do
    for gridOffsetY = -1, 1 do
      cells[#cells + 1] = world.getExteriorCell(
        playerCell.gridX + gridOffsetX,
        playerCell.gridY + gridOffsetY,
        playerCell
      )
    end
  end

  return cells
end

--- Lists the next cell's objects for a running sweep, one engine enumeration per call, so
--- that enumerating nine cells is spread over frames like the rule work is.
---@param activeSweep SSSActiveSweep
---@return boolean hasObjects false once every cell has been listed
local function listNextObjects(activeSweep)
  local cell = activeSweep.cells[activeSweep.cellIndex]
  if not cell then return false end

  local objectTypes = activeSweep.sweep.objectTypes

  if objectTypes then
    activeSweep.objects = cell:getAll(objectTypes[activeSweep.typeIndex])
    activeSweep.typeIndex = activeSweep.typeIndex + 1

    if activeSweep.typeIndex > #objectTypes then
      activeSweep.typeIndex = 1
      activeSweep.cellIndex = activeSweep.cellIndex + 1
    end
  else
    activeSweep.objects = cell:getAll()
    activeSweep.cellIndex = activeSweep.cellIndex + 1
  end

  activeSweep.nextIndex = 1
  return true
end

---@param sweepKey string
---@return boolean isFlapping
local function isSweepFlapping(sweepKey)
  local now = core.getSimulationTime()
  local startTimes = SweepStartTimes[sweepKey]

  if not startTimes then
    startTimes = {}
    SweepStartTimes[sweepKey] = startTimes
  end

  while startTimes[1] and now - startTimes[1] > SWEEP_START_WINDOW_SECONDS do
    Remove(startTimes, 1)
  end

  if #startTimes >= MAX_SWEEP_STARTS then return true end

  startTimes[#startTimes + 1] = now
  return false
end

local function startNextSweep()
  local sweepKey = Remove(PendingSweepKeys, 1)
  IsSweepPending[sweepKey] = nil

  if isSweepFlapping(sweepKey) then
    SuspendedSweepKeys[sweepKey] = true
    WarnLog(
      StrFormat(
        'Trigger "%s" fired more than %d times in %d seconds; suspended until the next load',
        sweepKey,
        MAX_SWEEP_STARTS,
        SWEEP_START_WINDOW_SECONDS
      )
    )
    return
  end

  ActiveSweep = {
    sweep = Sweeps[sweepKey],
    cells = collectNearbyCells(),
    cellIndex = 1,
    typeIndex = 1,
    objects = {},
    nextIndex = 1,
  }

  DebugLog('Sweep %s started over %d cell(s)', sweepKey, #ActiveSweep.cells)
end

--- Advances the running sweep by one frame, or starts the next requested one. A frame either
--- lists one cell's objects or runs rules on a budgeted number of them, never both.
--- The cells are fixed when a sweep starts and each cell is listed once, so objects a sweep
--- creates beside the object that made them are not swept. Conditions see the world as it is
--- on the frame they run, not as it was when the sweep began.
local function step()
  local activeSweep = ActiveSweep

  if not activeSweep then
    if PendingSweepKeys[1] then startNextSweep() end
    return
  end

  local objects = activeSweep.objects
  local firstIndex = activeSweep.nextIndex

  if firstIndex > #objects then
    if not listNextObjects(activeSweep) then
      DebugLog('Sweep %s finished', activeSweep.sweep.key)
      ActiveSweep = nil
    end

    return
  end

  BatchCache.clear()

  local triggerRules = activeSweep.sweep.rules
  local lastIndex = Min(firstIndex + SWEEP_OBJECTS_PER_FRAME - 1, #objects)

  for objectIdx = firstIndex, lastIndex do
    local object = objects[objectIdx]

    if Triggers.isPlacedInWorld(object) and object.enabled then
      Triggers.runRules(object, triggerRules)
    end
  end

  activeSweep.nextIndex = lastIndex + 1
end

---@return boolean isArmed whether any loaded rule listens to a trigger this module polls for
local function isArmed() return next(Sweeps) ~= nil or Triggers.isArmed 'cell_enter' end

---@class SSSWorldTriggers
local WorldTriggers = {
  isArmed = isArmed,
  poll = poll,
  step = step,
}

---@param moduleCatalog SSSModuleCatalog
---@param triggers SSSTriggers
---@return SSSWorldTriggers
return function(moduleCatalog, triggers)
  Sweeps = assert(moduleCatalog.Sweeps)
  JournalSweepKeys = assert(moduleCatalog.JournalSweepKeys)
  Triggers = assert(triggers)

  -- Entering a cell is only acted on when a rule listens for it, and only then does anything
  -- need to know that the player's movements are a correction rather than an arrival.
  if Triggers.isArmed 'cell_enter' then ObjectCleanup.watchReturns(Player) end
  return WorldTriggers
end
