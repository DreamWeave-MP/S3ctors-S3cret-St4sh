---@omw-context global

local clear = require 'scripts.s3.clear'
local szudzik = require 'scripts.s3.szudzik'

local Ceil, CoCreate, CoResume, CoStatus, CoYield, Error, Max, Min, Next, Pairs, StrFind, StrFormat, StrGsub, StrLower, tableRemove =
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

local pendingAdditions, previousGridCenters, seenContentFiles, seenIds, cellObjectIds =
  {}, {}, {}, {}, {}

-- Reusable per-cell delta scratch — cleared at the start of each collectPresenceAndStatics call
local recordDeltas, typeDeltas, contentFileDeltas = {}, {}, {}

---@type CellPresence
local CellPresence = {
  byRecord = {},
  byType = {},
  byContentFile = {},
  staticContentFiles = {},
  nearestRegion = nil,
  areaHasHostileActors = false,
  cellHasHostileActors = false,
  cellId = nil,
}

---@type table <string, string>
local PreviousPlayerCells = {}

-- Snapshot of exterior CellPresence state, preserved through interior visits
-- so same-door exits can skip the full sweep entirely
local exteriorSnapshot = {
  byRecord = nil,
  byType = nil,
  byContentFile = nil,
  staticContentFiles = nil,
  nearestRegion = nil,
  cellHasHostileActors = false,
  areaHasHostileActors = false,
}
local exteriorSnapshotValid = false

local presenceChanged = false
local TOTAL_OBJECT_BUDGET = 16
local TARGET_TRANSITION_FRAMES, EXTERIOR_TRANSITION_MULT = 15, 3
local MIN_BATCH_SIZE, MAX_BATCH_SIZE = 24, 48
local cellTransitionCoroutine, normalUpdateHandler, transitionUpdateHandler, updateFunction
local TransitioningPlayer, TransitionCell

local TypesToNames = {}

---@type fun(cell: openmw.core.GCell, filter?: openmw.types.Door | openmw.types.Static): openmw.GObject[]
local GetAll
--- Hoisted copy of GameObject.sendEvent
---@type fun(obj: openmw.Object, id: string, data: any)
local SendEvent

local Cells, DoorDestination, GetCurrentWeather, GetExteriorCell, IsDoor, IsTeleportDoor, Players, PresenceSection, SqLen, StaticType, StorageSet, NPCType, CreatureType, AIFight, IsDeadFn

local NPC_FIGHT_THRESHOLD = 90
local CREATURE_FIGHT_THRESHOLD = 83

do
  local core = require 'openmw.core'
  local storage = require 'openmw.storage'
  local types = require 'openmw.types'
  local world = require 'openmw.world'

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
  clear(cellObjectIds)
end

--- Saves the current CellPresence state as the exterior snapshot.
--- Swaps in fresh empty tables so the interior sweep can populate them
--- without corrupting the saved exterior data.
--- previousGridCenters and cellObjectIds are NOT touched — preserved for exterior diff on exit.
local function saveExteriorSnapshot()
  exteriorSnapshot.byRecord = CellPresence.byRecord
  exteriorSnapshot.byType = CellPresence.byType
  exteriorSnapshot.byContentFile = CellPresence.byContentFile
  exteriorSnapshot.staticContentFiles = CellPresence.staticContentFiles
  exteriorSnapshot.nearestRegion = CellPresence.nearestRegion
  exteriorSnapshot.cellHasHostileActors = CellPresence.cellHasHostileActors
  exteriorSnapshot.areaHasHostileActors = CellPresence.areaHasHostileActors
  exteriorSnapshotValid = true

  CellPresence.byRecord = {}
  CellPresence.byType = {}
  CellPresence.byContentFile = {}
  CellPresence.staticContentFiles = {}
end

--- Restores the exterior snapshot into CellPresence.
--- The interior's tables are orphaned (GC'd).
local function restoreExteriorSnapshot()
  CellPresence.byRecord = exteriorSnapshot.byRecord
  CellPresence.byType = exteriorSnapshot.byType
  CellPresence.byContentFile = exteriorSnapshot.byContentFile
  CellPresence.staticContentFiles = exteriorSnapshot.staticContentFiles
  CellPresence.nearestRegion = exteriorSnapshot.nearestRegion
  CellPresence.cellHasHostileActors = exteriorSnapshot.cellHasHostileActors
  CellPresence.areaHasHostileActors = exteriorSnapshot.areaHasHostileActors
  exteriorSnapshotValid = false
end

--- Repopulates seenIds from cellObjectIds so onObjectActive doesn't double-count
--- objects that are already tracked from the preserved exterior state.
local function repopulateSeenIds()
  for _, cellData in Next, cellObjectIds do
    local ids = cellData.ids
    for j = 1, #ids do
      seenIds[ids[j]] = true
    end
  end
end

--- Rebuilds staticContentFiles from cellObjectIds — the authoritative record of what's
--- in the current 3×3. Called after exterior diff/sweep/gap-fill to ensure
--- staticContentFiles reflects exactly the current grid, including kept cells' statics.
local function rebuildStaticListFromCellObjectIds()
  local outContentFiles = CellPresence.staticContentFiles
  clear(outContentFiles)
  clear(seenContentFiles)

  for _, cellData in Next, cellObjectIds do
    local numEntries = #cellData.ids
    for j = 1, numEntries do
      if cellData.objectTypes[j] == 'Static' then
        local contentFile = cellData.contentFiles[j]

        if contentFile and not seenContentFiles[contentFile] then
          outContentFiles[#outContentFiles + 1] = contentFile
          seenContentFiles[contentFile] = true
        end
      end
    end
  end
end

---@param recordId string
---@param objectType string
---@param contentFile string?
local function removeFromPresence(recordId, objectType, contentFile)
  local byContentFile, byRecord, byType =
    CellPresence.byContentFile, CellPresence.byRecord, CellPresence.byType

  local recordCount = byRecord[recordId]
  if not recordCount then Error(StrFormat('removeFromPresence: byRecord[%s] is nil', recordId)) end
  if recordCount <= 1 then
    byRecord[recordId] = nil
  else
    byRecord[recordId] = recordCount - 1
  end

  local typeCount = byType[objectType]
  if not typeCount then Error(StrFormat('removeFromPresence: byType[%s] is nil', objectType)) end
  if typeCount <= 1 then
    byType[objectType] = nil
  else
    byType[objectType] = typeCount - 1
  end

  if contentFile then
    local contentFileCount = byContentFile[contentFile]
    if not contentFileCount then
      Error(StrFormat('removeFromPresence: byContentFile[%s] is nil', contentFile))
    end
    if contentFileCount <= 1 then
      byContentFile[contentFile] = nil
    else
      byContentFile[contentFile] = contentFileCount - 1
    end
  end
end

---@param cell openmw.core.GCell
---@param cellKey string?
---@return boolean hasCombatTargets true if this cell contains any alive actors with fight >= threshold
local function collectPresenceAndStatics(cell, cellKey)
  local objects = GetAll(cell)
  CoYield()

  local nearestDoor
  local objIds, objRecordIds, objTypes, objContentFiles

  if cellKey then
    objIds, objRecordIds, objTypes, objContentFiles = {}, {}, {}, {}
  end

  local numObjects = #objects
  local targetFrames = cell.isExterior and TARGET_TRANSITION_FRAMES * EXTERIOR_TRANSITION_MULT
    or TARGET_TRANSITION_FRAMES

  local batchSize = Max(MIN_BATCH_SIZE, Min(MAX_BATCH_SIZE, Ceil(numObjects / targetFrames)))

  local untilYield = batchSize

  -- Per-cell accumulators — cleared and reused across cells, committed to CellPresence only after the full cell loop
  clear(recordDeltas)
  clear(typeDeltas)
  clear(contentFileDeltas)
  local cellHasHostile

  local outContentFiles = CellPresence.staticContentFiles
  for i = 1, numObjects do
    local obj = objects[i]
    local id, objType, recordId, contentFile = obj.id, obj.type, obj.recordId, obj.contentFile
    local typeName = TypesToNames[objType]

    if cellKey then
      local idx = #objIds + 1
      objIds[idx] = id
      objRecordIds[idx] = recordId
      objTypes[idx] = typeName
      objContentFiles[idx] = contentFile
    end

    seenIds[id] = true

    recordDeltas[recordId] = (recordDeltas[recordId] or 0) + 1
    typeDeltas[typeName] = (typeDeltas[typeName] or 0) + 1
    if contentFile then
      contentFileDeltas[contentFile] = (contentFileDeltas[contentFile] or 0) + 1
    end

    -- Static list population — interiors only.
    -- Exterior staticContentFiles is rebuilt from cellObjectIds by rebuildStaticListFromCellObjectIds.
    if not cellKey and objType == StaticType then
      if contentFile and not seenContentFiles[contentFile] then
        outContentFiles[#outContentFiles + 1] = contentFile
        seenContentFiles[contentFile] = true
      end
    end

    -- Combat check: does this cell contain any aggressive living actor (excluding the player)?
    if not cellHasHostile then
      if (objType == NPCType or objType == CreatureType) and id ~= TransitioningPlayer.id then
        local fightValue = AIFight(obj).modified
        local threshold = objType == NPCType and NPC_FIGHT_THRESHOLD or CREATURE_FIGHT_THRESHOLD
        if fightValue >= threshold and not IsDeadFn(obj) then cellHasHostile = true end
      end
    end

    -- Door tracking for interior cells without an own region
    if not cellKey and not cell.region then nearestDoor = checkForRegion(obj, nearestDoor) end

    untilYield = untilYield - 1
    if untilYield == 0 then
      untilYield = batchSize
      CoYield()
    end
  end

  -- Commit the full cell atomically — if the coroutine was aborted mid-loop,
  -- the entries were never written to CellPresence and get garbage collected.
  local byContentFile, byRecord, byType =
    CellPresence.byContentFile, CellPresence.byRecord, CellPresence.byType
  for recordId, delta in Next, recordDeltas do
    byRecord[recordId] = (byRecord[recordId] or 0) + delta
  end

  for typeName, delta in Next, typeDeltas do
    byType[typeName] = (byType[typeName] or 0) + delta
  end

  for contentFile, delta in Next, contentFileDeltas do
    byContentFile[contentFile] = (byContentFile[contentFile] or 0) + delta
  end

  if cellKey then
    cellObjectIds[cellKey] = {
      ids = objIds,
      recordIds = objRecordIds,
      objectTypes = objTypes,
      contentFiles = objContentFiles,
    }
  else
    local region = cell.region
    if not region and nearestDoor then region = DoorDestination(nearestDoor).region end
    if region then CellPresence.nearestRegion = region end
  end

  return cellHasHostile
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

    -- Track in cellObjectIds so the diff/removeFromPresence path can account for it
    local objCell = obj.cell
    if objCell.isExterior then
      local cellKey = szudzik.getIndex(objCell.gridX, objCell.gridY)
      local cellData = cellObjectIds[cellKey]
      if cellData then
        local idx = #cellData.ids + 1
        cellData.ids[idx] = obj.id
        cellData.recordIds[idx] = recordId
        cellData.objectTypes[idx] = typeName
        cellData.contentFiles[idx] = contentFile
      end
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

      local areaHostile, centerKey = false, szudzik.getIndex(gridX, gridY)

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
          ) and not cellObjectIds[cellKey]
          if isNew then
            CoYield() -- Breathe before GetAll

            local exteriorCell = GetExteriorCell(cellX, cellY)
            if exteriorCell then
              local cellHostile = collectPresenceAndStatics(exteriorCell, cellKey)
              if cellKey == centerKey then CellPresence.cellHasHostileActors = cellHostile end
              if cellHostile then areaHostile = true end
            end

            CoYield() -- Between cells
          end
        end
      end

      -- Remove all cellObjectIds entries outside the new 3×3
      -- (covers both normal leaving-cells and orphans from aborted coroutines)
      for cellKey, cellData in Next, cellObjectIds do
        local cellX, cellY = szudzik.unpair(cellKey)
        if cellX < gridX - 1 or cellX > gridX + 1 or cellY < gridY - 1 or cellY > gridY + 1 then
          local numEntries = #cellData.ids
          for j = 1, numEntries do
            removeFromPresence(
              cellData.recordIds[j],
              cellData.objectTypes[j],
              cellData.contentFiles[j]
            )
          end
          cellObjectIds[cellKey] = nil
        end
      end

      -- Fill in any cells the previous coroutine never committed (abort survivability)
      for offsetX = -1, 1 do
        for offsetY = -1, 1 do
          local cellKey = szudzik.getIndex(gridX + offsetX, gridY + offsetY)
          if not cellObjectIds[cellKey] then
            CoYield() -- Breathe before GetAll
            local cell = GetExteriorCell(gridX + offsetX, gridY + offsetY)
            if cell then
              local cellHostile = collectPresenceAndStatics(cell, cellKey)
              if cellKey == centerKey then CellPresence.cellHasHostileActors = cellHostile end
              if cellHostile then areaHostile = true end
            end
          end
        end
      end
      CellPresence.areaHasHostileActors = areaHostile

      -- Rebuild staticContentFiles from the authoritative cellObjectIds
      -- This captures statics from ALL cells in the current 3×3, including kept cells
      -- that the diff loop skipped (they're already in cellObjectIds)
      rebuildStaticListFromCellObjectIds()
    end
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
  end

  -- Stamp the source cell so the player-side subscriber can reject stale writes
  CellPresence.cellId = TransitionCell.id

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
    Error(err)
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
  local player, oldCell = transitionInfo[1], transitionInfo[2]
  PreviousPlayerCells[player.id] = oldCell

  TransitioningPlayer, TransitionCell = player, player.cell
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
  },
  eventHandlers = {
    S3maphoreUpdatePresence = updatePresenceInfo,

    S3maphoreInitializationComplete = function(pid)
      PlayersInitialized[pid] = true
      if not SendEvent then SendEvent = Players[1].sendEvent end
      if not GetAll then GetAll = Cells[1].getAll end
    end,
  },
}
