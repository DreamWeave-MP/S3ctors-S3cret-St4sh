---@omw-context global

local clear = require 'scripts.s3.clear'
local szudzik = require 'scripts.s3.szudzik'

local Ceil, CoCreate, CoResume, CoStatus, CoYield, Error, Max, Min, Next, Pairs, Print, StrFind, StrFormat, StrGsub, StrLower, tableRemove =
  math.ceil,
  coroutine.create,
  coroutine.resume,
  coroutine.status,
  coroutine.yield,
  error,
  math.max,
  math.min,
  next,
  pairs,
  print,
  string.find,
  string.format,
  string.gsub,
  string.lower,
  table.remove

--- Maps player ids back to the previously-running weather
---@type table<string, string>
local PreviousPlayerWeathers = {}

--- Maps players to playlist initialization state
---@type table<string, boolean>
local PlayersInitialized = {}

---@type table<string, integer>
local GlobalKillCounts = {}

local pendingAdditions, previousGridCenters, seenContentFiles, seenIds, exteriorCellData =
  {}, {}, {}, {}, {}

---@type CellPresence
local CellPresence = {
  byRecord = {},
  byType = {},
  byContentFile = {},
  staticContentFiles = {},
  currentExteriorCellObjects = nil,
  nearestRegion = nil,
  areaHasHostileActors = false,
  cellHasHostileActors = false,
  cellId = nil,
  generation = nil,
}

---@type table <string, string>
local PreviousPlayerCells = {}

-- Snapshot of exterior CellPresence state, preserved through interior visits
-- so same-door exits can skip the full sweep entirely
local exteriorSnapshot = {
  byRecord = nil,
  byType = nil,
  byContentFile = nil,
  nearestRegion = nil,
  exteriorCellData = nil,
}
local exteriorSnapshotValid = false

local presenceChanged = false
local TOTAL_OBJECT_BUDGET = 16
local TARGET_TRANSITION_FRAMES, EXTERIOR_TRANSITION_MULT = 15, 3
local MIN_BATCH_SIZE, MAX_BATCH_SIZE = 24, 48
local cellTransitionCoroutine, normalUpdateHandler, transitionUpdateHandler, updateFunction
local TransitioningPlayer, TransitionCell, TransitionGeneration

local TypesToNames = {}

---@type fun(cell: openmw.core.GCell, filter?: openmw.types.Door | openmw.types.Static): openmw.GObject[]
local GetAll
--- Hoisted copy of GameObject.sendEvent
---@type fun(obj: openmw.Object, id: string, data: any)
local SendEvent
local Quit

local Cells, DoorDestination, GetCurrentWeather, GetExteriorCell, IsDoor, IsTeleportDoor, Players, PresenceSection, SqLen, StaticType, StorageSet, NPCType, CreatureType, AIFight, IsDeadFn

local NPC_FIGHT_THRESHOLD = 90
local CREATURE_FIGHT_THRESHOLD = 83

---@param object openmw.GObject
---@return boolean
local function isHostileActor(object)
  local objectType = object.type
  if objectType ~= NPCType and objectType ~= CreatureType then return false end

  local fightValue = AIFight(object).modified
  local threshold = objectType == NPCType and NPC_FIGHT_THRESHOLD or CREATURE_FIGHT_THRESHOLD
  return fightValue >= threshold and not IsDeadFn(object)
end

do
  local core = require 'openmw.core'
  local storage = require 'openmw.storage'
  local types = require 'openmw.types'
  local world = require 'openmw.world'

  Quit = core.quit
  for k, v in Pairs(types) do
    TypesToNames[v] = k
  end

  Cells, Players = world.cells, world.players
  GetCurrentWeather = core.weather.getCurrent
  GetExteriorCell = world.getExteriorCell
  DoorDestination, IsDoor, IsTeleportDoor =
    types.Door.destCell, types.Door.objectIsInstance, types.Door.isTeleport
  PresenceSection = storage.globalSection 'S3maphoreCellPresence'
  ---@diagnostic disable-next-line: param-type-mismatch
  PresenceSection:setLifeTime(storage.LIFE_TIME.Temporary)
  StorageSet = PresenceSection.set
  SqLen = require('openmw.util').vector3(0, 0, 0).length2
  StaticType = types.Static
  NPCType, CreatureType = types.NPC, types.Creature
  AIFight = types.Actor.stats.ai.fight
  IsDeadFn = types.Actor.isDead
end

---@param player openmw.GObject
---@param playerId string
local function updatePlayerWeather(player, playerId)
  local playerCell = player.cell
  ---@cast playerCell openmw.core.GCell

  local currentWeather = GetCurrentWeather(playerCell)
  local lastKnownWeather = PreviousPlayerWeathers[playerId]

  local weatherId
  if currentWeather then weatherId = currentWeather.recordId end

  if lastKnownWeather ~= weatherId then
    SendEvent(player, 'S3maphoreWeatherChanged', weatherId)
    PreviousPlayerWeathers[playerId] = weatherId
  end
end

---@param object openmw.GObject
---@param nearestDoor openmw.GObject?
---@return openmw.GObject? nearestDoor
local function checkForRegion(object, nearestDoor)
  if not IsDoor(object) or not IsTeleportDoor(object) then return end

  local targetPos, objectPos = TransitioningPlayer.position, object.position
  if not nearestDoor or SqLen(targetPos - objectPos) < SqLen(targetPos - nearestDoor.position) then
    return object
  end
end

local function clearCellPresence()
  clear(CellPresence.byRecord)
  clear(CellPresence.byType)
  clear(CellPresence.byContentFile)
  clear(CellPresence.staticContentFiles)
  CellPresence.nearestRegion = nil
  CellPresence.cellHasHostileActors = false
  CellPresence.areaHasHostileActors = false
  CellPresence.cellId = nil
  clear(exteriorCellData)
  CellPresence.currentExteriorCellObjects = nil
end

--- Saves the current CellPresence state as the exterior snapshot.
--- Swaps in fresh empty tables so the interior sweep can populate them
--- without corrupting the saved exterior data.
--- previousGridCenters and exteriorCellData are NOT touched — preserved for exterior diff on exit.
local function saveExteriorSnapshot()
  exteriorSnapshot.byRecord = CellPresence.byRecord
  exteriorSnapshot.byType = CellPresence.byType
  exteriorSnapshot.byContentFile = CellPresence.byContentFile
  exteriorSnapshot.nearestRegion = CellPresence.nearestRegion
  exteriorSnapshot.exteriorCellData = exteriorCellData
  exteriorSnapshotValid = true

  CellPresence.byRecord = {}
  CellPresence.byType = {}
  CellPresence.byContentFile = {}
  CellPresence.staticContentFiles = {}
  exteriorCellData = {}
end

--- Restores the exterior snapshot into CellPresence.
--- The interior's tables are orphaned (GC'd).
local function restoreExteriorSnapshot()
  CellPresence.byRecord = exteriorSnapshot.byRecord
  CellPresence.byType = exteriorSnapshot.byType
  CellPresence.byContentFile = exteriorSnapshot.byContentFile
  CellPresence.nearestRegion = exteriorSnapshot.nearestRegion
  exteriorCellData = exteriorSnapshot.exteriorCellData
  exteriorSnapshotValid = false
end

--- Repopulates seenIds from exteriorCellData so onObjectActive doesn't double-count
--- objects that are already tracked from the preserved exterior state.
local function repopulateSeenIds()
  for _, cellData in Next, exteriorCellData do
    local ids = cellData.ids
    for j = 1, #ids do
      seenIds[ids[j]] = true
    end
  end
end

--- Rebuilds staticContentFiles from exteriorCellData — the authoritative record of what's
--- in the current 3×3. Called after exterior diff/sweep/gap-fill to ensure
--- staticContentFiles reflects exactly the current grid, including kept cells' statics.
local function rebuildStaticListFromExteriorCellData()
  local outContentFiles = CellPresence.staticContentFiles
  clear(outContentFiles)
  clear(seenContentFiles)

  for _, cellData in Next, exteriorCellData do
    local staticContentFiles = cellData.presence.staticContentFiles
    for i = 1, #staticContentFiles do
      local contentFile = staticContentFiles[i]

      if not seenContentFiles[contentFile] then
        outContentFiles[#outContentFiles + 1] = contentFile
        seenContentFiles[contentFile] = true
      end
    end
  end
end

---@param target table<string, integer>
---@param key string
---@param count integer
---@param mapName string
local function subtractCount(target, key, count, mapName)
  local current = target[key]
  if not current or current < count then
    Error(StrFormat('subtractCount: %s[%s] is below the requested count', mapName, key))
  end

  if current == count then
    target[key] = nil
  else
    target[key] = current - count
  end
end

---@param cellData table
local function removeCellPresence(cellData)
  local presence = cellData.presence
  local byContentFile, byRecord, byType =
    CellPresence.byContentFile, CellPresence.byRecord, CellPresence.byType

  for recordId, count in Next, presence.byRecord do
    subtractCount(byRecord, recordId, count, 'byRecord')
  end

  for typeName, count in Next, presence.byType do
    subtractCount(byType, typeName, count, 'byType')
  end

  for contentFile, count in Next, presence.byContentFile do
    subtractCount(byContentFile, contentFile, count, 'byContentFile')
  end
end

---@param cell openmw.core.GCell
---@param cellKey string?
---@return boolean hasCombatTargets true if this cell contains any alive actors with fight >= threshold
local function collectPresenceAndStatics(cell, cellKey)
  local objects = GetAll(cell)
  CoYield()

  local nearestDoor
  local cellPresence = {
    byRecord = {},
    byType = {},
    byContentFile = {},
    staticContentFiles = {},
  }
  local cellData = cellKey and { ids = {}, presence = cellPresence, hasHostileActors = false }
  local seenCellStaticContentFiles = {}

  local numObjects = #objects
  local targetFrames = cell.isExterior and TARGET_TRANSITION_FRAMES * EXTERIOR_TRANSITION_MULT
    or TARGET_TRANSITION_FRAMES

  local batchSize = Max(MIN_BATCH_SIZE, Min(MAX_BATCH_SIZE, Ceil(numObjects / targetFrames)))

  local untilYield = batchSize

  local cellHasHostile

  for i = 1, numObjects do
    local obj = objects[i]
    local id, objType, recordId, contentFile = obj.id, obj.type, obj.recordId, obj.contentFile
    local typeName = TypesToNames[objType]

    if typeName then
      if cellKey then cellData.ids[#cellData.ids + 1] = id end

      seenIds[id] = true

      cellPresence.byRecord[recordId] = (cellPresence.byRecord[recordId] or 0) + 1
      cellPresence.byType[typeName] = (cellPresence.byType[typeName] or 0) + 1
      if contentFile then
        cellPresence.byContentFile[contentFile] = (cellPresence.byContentFile[contentFile] or 0) + 1
      end

      if objType == StaticType and contentFile and not seenCellStaticContentFiles[contentFile] then
        local staticContentFiles = cellPresence.staticContentFiles
        staticContentFiles[#staticContentFiles + 1] = contentFile
        seenCellStaticContentFiles[contentFile] = true
      end

      -- Combat check: does this cell contain any aggressive living actor (excluding the player)?
      if not cellHasHostile and isHostileActor(obj) then cellHasHostile = true end

      -- Door tracking for interior cells without an own region
      if not cellKey and not cell.region then nearestDoor = checkForRegion(obj, nearestDoor) end
    end

    untilYield = untilYield - 1
    if untilYield == 0 then
      untilYield = batchSize
      CoYield()
    end
  end

  -- Commit the full cell atomically — if the coroutine was aborted mid-loop,
  -- neither its per-cell data nor its deltas are published.
  local byContentFile, byRecord, byType =
    CellPresence.byContentFile, CellPresence.byRecord, CellPresence.byType
  for recordId, delta in Next, cellPresence.byRecord do
    byRecord[recordId] = (byRecord[recordId] or 0) + delta
  end

  for typeName, delta in Next, cellPresence.byType do
    byType[typeName] = (byType[typeName] or 0) + delta
  end

  for contentFile, delta in Next, cellPresence.byContentFile do
    byContentFile[contentFile] = (byContentFile[contentFile] or 0) + delta
  end

  if not cellKey then
    local staticContentFiles = cellPresence.staticContentFiles
    for i = 1, #staticContentFiles do
      local contentFile = staticContentFiles[i]
      if not seenContentFiles[contentFile] then
        CellPresence.staticContentFiles[#CellPresence.staticContentFiles + 1] = contentFile
        seenContentFiles[contentFile] = true
      end
    end
  end

  if cellKey then
    cellData.hasHostileActors = cellHasHostile or false
    exteriorCellData[cellKey] = cellData
  else
    local region = cell.region
    if not region and nearestDoor then region = DoorDestination(nearestDoor).region end
    if region then CellPresence.nearestRegion = region end
  end

  return cellHasHostile or false
end

local function flushPendingAdditions(budget)
  if budget <= 0 or not pendingAdditions[1] then return end

  local byRecord, byType, byContentFile =
    CellPresence.byRecord, CellPresence.byType, CellPresence.byContentFile
  local processed = 0

  for i = #pendingAdditions, 1, -1 do
    if processed >= budget then break end

    local obj = pendingAdditions[i]
    seenIds[obj.id] = nil

    local objType = obj.type
    local typeName, recordId, contentFile = TypesToNames[objType], obj.recordId, obj.contentFile

    local recordCount = byRecord[recordId]
    byRecord[recordId] = (recordCount or 0) + 1

    local typeCount = byType[typeName]
    byType[typeName] = (typeCount or 0) + 1

    if contentFile then
      local contentFileCount = byContentFile[contentFile]
      byContentFile[contentFile] = (contentFileCount or 0) + 1
    end

    -- Track in exteriorCellData so the diff/remove path can account for it
    local objCell = obj.cell
    if objCell.isExterior then
      local cellKey = szudzik.getIndex(objCell.gridX, objCell.gridY)
      local cellData = exteriorCellData[cellKey]
      if cellData then
        cellData.ids[#cellData.ids + 1] = obj.id

        local presence = cellData.presence
        presence.byRecord[recordId] = (presence.byRecord[recordId] or 0) + 1
        presence.byType[typeName] = (presence.byType[typeName] or 0) + 1
        if contentFile then
          presence.byContentFile[contentFile] = (presence.byContentFile[contentFile] or 0) + 1
        end

        if objType == StaticType and contentFile then
          local staticContentFiles = presence.staticContentFiles
          local found = false
          for j = 1, #staticContentFiles do
            if staticContentFiles[j] == contentFile then
              found = true
              break
            end
          end
          if not found then staticContentFiles[#staticContentFiles + 1] = contentFile end
        end

        if isHostileActor(obj) then
          cellData.hasHostileActors = true
          CellPresence.areaHasHostileActors = true
          if CellPresence.currentExteriorCellObjects == presence then
            CellPresence.cellHasHostileActors = true
          end
        end
      end
    elseif
      not TransitionCell.isExterior
      and objCell.id == TransitionCell.id
      and isHostileActor(obj)
    then
      CellPresence.cellHasHostileActors = true
      CellPresence.areaHasHostileActors = true
    end

    tableRemove(pendingAdditions)
    processed = processed + 1
  end
end

local function cellTransitionCoroutineHandler()
  CoYield() -- Breathe before allocating

  -- Clear stale work queues and dedup sets
  -- NOTE: seenContentFiles is NOT cleared here —
  -- it is cleared per-branch to preserve exterior statics across diffs and snapshots
  clear(pendingAdditions)
  clear(seenIds)
  CellPresence.nearestRegion = nil
  presenceChanged = false

  if TransitionCell.isExterior then
    local gridX, gridY = TransitionCell.gridX, TransitionCell.gridY
    local center = szudzik.getIndex(gridX, gridY)
    local playerId = TransitioningPlayer.id

    -- Commit the new center immediately so any abort sees the correct diff base
    local oldCenter = previousGridCenters[playerId]
    previousGridCenters[playerId] = center

    -- Fast path: returning to the same exterior grid from an interior
    if exteriorSnapshotValid and oldCenter == center then
      restoreExteriorSnapshot()
      repopulateSeenIds()
    else
      -- Slow path: grid changed or first exterior entry
      if exteriorSnapshotValid then
        -- Grid changed (e.g., divine intervention) — restore exterior base before diffing
        restoreExteriorSnapshot()
        repopulateSeenIds()
      end

      -- First time stepping into an exterior (coming from interior or fresh start): clear everything
      if not oldCenter then clearCellPresence() end

      CoYield()

      -- Diff: only process cells entering the new 3×3
      local oldMinX, oldMaxX, oldMinY, oldMaxY
      if oldCenter then
        local px, py = szudzik.unpair(oldCenter)
        oldMinX, oldMaxX = px - 1, px + 1
        oldMinY, oldMaxY = py - 1, py + 1
      end

      for offsetX = -1, 1 do
        for offsetY = -1, 1 do
          local cellX, cellY = gridX + offsetX, gridY + offsetY
          local cellKey = szudzik.getIndex(cellX, cellY)
          local isNew = (
            not oldCenter
            or cellX < oldMinX
            or cellX > oldMaxX
            or cellY < oldMinY
            or cellY > oldMaxY
          ) and not exteriorCellData[cellKey]
          if isNew then
            CoYield() -- Breathe before GetAll

            local exteriorCell = GetExteriorCell(cellX, cellY)
            if exteriorCell then collectPresenceAndStatics(exteriorCell, cellKey) end

            CoYield() -- Between cells
          end
        end
      end

      -- Remove all exteriorCellData entries outside the new 3×3
      -- (covers both normal leaving-cells and orphans from aborted coroutines)
      for cellKey, cellData in Next, exteriorCellData do
        local cellX, cellY = szudzik.unpair(cellKey)
        if cellX < gridX - 1 or cellX > gridX + 1 or cellY < gridY - 1 or cellY > gridY + 1 then
          removeCellPresence(cellData)
          exteriorCellData[cellKey] = nil
        end
      end

      -- Fill in any cells the previous coroutine never committed (abort survivability)
      for offsetX = -1, 1 do
        for offsetY = -1, 1 do
          local cellKey = szudzik.getIndex(gridX + offsetX, gridY + offsetY)
          if not exteriorCellData[cellKey] then
            CoYield() -- Breathe before GetAll
            local cell = GetExteriorCell(gridX + offsetX, gridY + offsetY)
            if cell then collectPresenceAndStatics(cell, cellKey) end
          end
        end
      end
    end

    local centerData = exteriorCellData[center]
    if not centerData then Error 'Current exterior cell is missing from exteriorCellData' end

    -- Derive all exterior-facing state from the authoritative retained cells.
    rebuildStaticListFromExteriorCellData()
    CellPresence.currentExteriorCellObjects = centerData.presence
    CellPresence.cellHasHostileActors = centerData.hasHostileActors

    local areaHasHostileActors = false
    for _, cellData in Next, exteriorCellData do
      if cellData.hasHostileActors then
        areaHasHostileActors = true
        break
      end
    end
    CellPresence.areaHasHostileActors = areaHasHostileActors
  else
    -- Interior: save exterior state if coming from exterior, then clear + rebuild
    local playerId = TransitioningPlayer.id

    if previousGridCenters[playerId] and not exteriorSnapshotValid then
      -- Exterior→interior: save exterior state for fast-path restore on exit
      saveExteriorSnapshot()
    else
      -- Interior→interior or fresh start: previous cell's data needs clearing
      clear(CellPresence.byRecord)
      clear(CellPresence.byType)
      clear(CellPresence.byContentFile)
      clear(CellPresence.staticContentFiles)
    end

    -- Preserve previousGridCenters — do NOT nil it
    -- This allows the exterior diff to work on exit
    clear(seenContentFiles)
    CellPresence.nearestRegion = nil
    CellPresence.cellHasHostileActors = false
    CellPresence.areaHasHostileActors = false
    CellPresence.cellId = nil

    CoYield() -- Breathe before GetAll
    local cellHostile = collectPresenceAndStatics(TransitionCell)
    CellPresence.cellHasHostileActors = cellHostile
    CellPresence.areaHasHostileActors = cellHostile
    CellPresence.currentExteriorCellObjects = nil
  end

  -- Stamp the source cell so the player-side subscriber can reject stale writes
  CellPresence.cellId = TransitionCell.id
  CellPresence.generation = TransitionGeneration

  -- Mark presence changed so the next normal update flushes to storage
  presenceChanged = true
end

local function startCellTransition()
  cellTransitionCoroutine = CoCreate(cellTransitionCoroutineHandler)
  updateFunction = transitionUpdateHandler
end

transitionUpdateHandler = function()
  local success, err = CoResume(cellTransitionCoroutine)
  if not success then
    cellTransitionCoroutine = nil
    updateFunction = normalUpdateHandler
    Print(StrFormat('[ S3MAPHORE ]: Fatal presence collection error: %s', err))
    return Quit()
  end

  if CoStatus(cellTransitionCoroutine) == 'dead' then
    cellTransitionCoroutine = nil
    updateFunction = normalUpdateHandler
  end
end

normalUpdateHandler = function()
  for i = 1, #Players do
    local player = Players[i]
    local playerId = player.id

    local initialized = PlayersInitialized[playerId] ~= nil

    if initialized then updatePlayerWeather(player, playerId) end
  end

  -- Don't flush or write storage during a cell transition
  if not cellTransitionCoroutine then
    flushPendingAdditions(TOTAL_OBJECT_BUDGET)

    if presenceChanged and not pendingAdditions[1] then
      StorageSet(PresenceSection, TransitioningPlayer.id, CellPresence)
      presenceChanged = false
    end
  end
end

updateFunction = normalUpdateHandler

local function updatePresenceInfo(transitionInfo)
  local player, oldCell, generation = transitionInfo[1], transitionInfo[2], transitionInfo[3]

  PreviousPlayerCells[player.id] = oldCell

  TransitioningPlayer, TransitionCell, TransitionGeneration = player, player.cell, generation
  startCellTransition()
end

return {
  interfaceName = 'S3maphoreG',
  interface = {
    findCellMatches = function(pattern)
      local cellStr = ''

      for i = 1, #Cells do
        local cell = Cells[i]
        local cellName = cell.name

        if cellName and cellName ~= '' and StrFind(StrLower(cellName), pattern) then
          cellStr =
            StrFormat('%s[\'%s\'] = true,\n', cellStr, StrGsub(StrLower(cellName), '\'', '\\\''))
        end
      end

      return cellStr
    end,
  },

  engineHandlers = {
    onObjectActive = function(object)
      --- We only care about scripted spawns.
      --- Engine markers don't have a `type` field, so we always skip those,
      --- but they're much rarer than placed objects.
      local objectId = object.id
      if object.contentFile or not object.type or seenIds[objectId] or cellTransitionCoroutine then
        return
      end

      local player = Players[1]
      local oldCell = PreviousPlayerCells[player.id]
      if not oldCell or player.cell.id == oldCell then return end

      seenIds[objectId] = true

      pendingAdditions[#pendingAdditions + 1] = object
      presenceChanged = true
    end,
    onUpdate = function() updateFunction() end,

    onLoad = function(data)
      if not data then return end

      if data.KillCounts then
        GlobalKillCounts = data.KillCounts
        StorageSet(PresenceSection, 'GlobalKillCounts', GlobalKillCounts)
      end
    end,

    onSave = function()
      return {
        KillCounts = GlobalKillCounts,
      }
    end,
  },
  eventHandlers = {
    S3maphoreUpdatePresence = updatePresenceInfo,

    ---@param transitionInfo { [1]: openmw.GObject, [2]: string?, [3]: integer }
    S3maphoreInitializationComplete = function(transitionInfo)
      local player = transitionInfo[1]
      PlayersInitialized[player.id] = true
      if not SendEvent then SendEvent = player.sendEvent end
      if not GetAll then GetAll = player.cell.getAll end
      updatePresenceInfo(transitionInfo)
    end,

    S3maphoreDeathCountIncrement = function(killedRecordId)
      GlobalKillCounts[killedRecordId] = (GlobalKillCounts[killedRecordId] or 0) + 1
      GlobalKillCounts.TotalKills = (GlobalKillCounts.TotalKills or 0) + 1
      StorageSet(PresenceSection, 'GlobalKillCounts', GlobalKillCounts)
    end,
  },
}
