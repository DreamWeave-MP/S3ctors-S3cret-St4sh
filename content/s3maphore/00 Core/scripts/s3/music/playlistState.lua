---@omw-context player

local Pairs, StrLower = pairs, string.lower

local MusicSettings = require 'scripts.s3.music.musicSettings'
local gameSelf = require 'openmw.self'

local PlaylistState = {
  cellHasWater = false,
  cellIsExterior = false,
  cellName = '',
  normalizedHealth = 1.0,
  normalizedMagicka = 1.0,
  normalizedFatigue = 1.0,
  movementMode = 'standing',
  objectsByRecord = {},
  objectsByType = {},
  objectsByContentFile = {},
  staticObjectContentFiles = {},
  cellHasHostileActors = false,
  areaHasHostileActors = false,
  killCounts = {},
  objectCount = 0,
  cellId = '',
  cellWaterLevel = nil,
  combatTargets = {},
  currentGrid = nil,
  isExploring = true,
  isInCombat = false,
  selectedSpellSchool = nil,
}

-- Cached cell grid for updateCellMetadata, avoids creating new table objects each call
local CachedCellGrid = { x = 0, y = 0 }
local HasTag
local CurrentPresence

---@private
---@param scanAdjacentExteriorCells boolean
function PlaylistState.refreshObjectPresenceScope(scanAdjacentExteriorCells)
  if not CurrentPresence then return end

  local source = CurrentPresence
  if gameSelf.cell.isExterior and not scanAdjacentExteriorCells then
    source = CurrentPresence.currentExteriorCellObjects
  end

  PlaylistState.objectsByRecord = source.byRecord
  PlaylistState.objectsByType = source.byType
  PlaylistState.objectsByContentFile = source.byContentFile
  PlaylistState.staticObjectContentFiles = source.staticContentFiles

  local total = 0
  for _, count in Pairs(source.byType) do
    total = total + count
  end
  PlaylistState.objectCount = total
end

local refreshObjectPresenceScope = PlaylistState.refreshObjectPresenceScope

--- Updates PlaylistState cell metadata from self.cell.
--- Called from both S3LFCellChanged and the init handler.
---@private
function PlaylistState.updateCellMetadata()
  local thisCell = gameSelf.cell
  ---@cast thisCell openmw.core.LCell

  if not HasTag then HasTag = thisCell.hasTag end

  local shouldUseName = thisCell.name ~= ''

  PlaylistState.cellHasWater = thisCell.hasWater
  PlaylistState.cellWaterLevel = thisCell.waterLevel
  PlaylistState.cellIsExterior = thisCell.isExterior or HasTag(thisCell, 'QuasiExterior')
  PlaylistState.cellName = StrLower(shouldUseName and thisCell.name or thisCell.id)
  PlaylistState.cellId = thisCell.id

  if thisCell.region then PlaylistState.nearestRegion = thisCell.region end

  if thisCell.isExterior then
    CachedCellGrid.x, CachedCellGrid.y = thisCell.gridX, thisCell.gridY
    PlaylistState.currentGrid = CachedCellGrid
  else
    PlaylistState.currentGrid = nil
  end
end

do
  local async = require 'openmw.async'
  local presenceSection = require('openmw.storage').globalSection 'S3maphoreCellPresence'

  local pairs = pairs
  local SendEvent, StorageGet = gameSelf.sendEvent, presenceSection.get
  local PresenceUpdatedData = { cellId = '', generation = 0 }

  presenceSection:subscribe(async:callback(function(_, key)
    if key == gameSelf.id then
      local presence = StorageGet(presenceSection, key)

      local thisCell = gameSelf.cell
      ---@cast thisCell openmw.core.LCell

      -- Only accept presence data written for the cell the player is actually in
      -- This prevents stale writes from a previous cell from corrupting PlaylistState
      if not presence or presence.cellId ~= thisCell.id then return end

      PlaylistState.nearestRegion = presence.nearestRegion or thisCell.region

      CurrentPresence = presence
      refreshObjectPresenceScope(MusicSettings.ScanAdjacentExteriorCells ~= false)
      PlaylistState.cellHasHostileActors = presence.cellHasHostileActors
      PlaylistState.areaHasHostileActors = presence.areaHasHostileActors

      PresenceUpdatedData.cellId = presence.cellId
      PresenceUpdatedData.generation = presence.generation
      SendEvent(gameSelf, 'S3maphoreCellPresenceUpdated', PresenceUpdatedData)
    elseif key == 'GlobalKillCounts' then
      PlaylistState.killCounts = StorageGet(presenceSection, key)
    end
  end))
end

return PlaylistState
