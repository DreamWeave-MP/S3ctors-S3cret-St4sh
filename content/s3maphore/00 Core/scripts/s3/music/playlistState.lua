---@omw-context player

local StrLower = string.lower

local gameSelf = require 'openmw.self'

---@class PlaylistState
---@field cellHasWater boolean whether the current cell has water or not
---@field cellIsExterior boolean whether the player is in an exterior cell or not (includes fake exteriors such as starwind)
---@field cellName string lowercased name of the cell the player is in
---@field cellId string engine-level identifier for cells. Should generally not be used in favor of cellNames as the only way to determine cell ids is to check in-engine using `cell.id`. It is made available in PlaylistState mostly for caching purposes, but may be used regardless.
---@field cellWaterLevel number? If the current cell has water, then, it is copied here
---@field objectsByRecord table<string, integer> Map of recordId → instance count for the current cell/grid
---@field objectsByType table<string, integer> Map of typeName → instance count for the current cell/grid
---@field objectsByContentFile table<string, integer> Map of contentFile → instance count for the current cell/grid
---@field staticObjectContentFiles string[] List of content files with statics in the current cell/grid
---@field cellHasHostileActors boolean True if the player's current cell contains hostile actors
---@field areaHasHostileActors boolean True if any cell in the current 3×3 grid contains hostile actors
---@field killCounts table<string, number> Record of all actors killed during this playthrough. The `TotalKills` field indicates the overall number of killed actors. Does not necessarily mean those actors were killed by the player, they're just dead.
---@field objectCount number Total objects in the current cell, computed from objectsByType
---@field combatTargets openmw.LObject[] combat targets in insertion order
---@field currentGrid ExteriorGrid? The current exterior cell grid. Nil if not in an actual exterior.
---@field isExploring boolean whether the player is currently exploring or not. Distinct from isInCombat as settings may control it.
---@field isInCombat boolean whether the player is in combat or not
---@field nearestRegion string? The current region the player is in. This is determined by either checking the current region of the player's current cell, OR, reading all load door's target cell's regions in the current cell. The first cell which is found to have a region will match and be assigned to the PlaylistState.
---@field playlistTimeOfDay TimeOfDay the time of day for the current playlist
---@field normalizedHealth number current / base, updated per frame, rounded to two decimals
---@field normalizedMagicka number current / base, updated per frame, rounded to two decimals
---@field normalizedFatigue number current / base, updated per frame, rounded to two decimals
---@field movementMode S3maphoreMovementMode current player movement mode
---@field weather string
---@field selectedSpellSchool string? the magic school of the currently selected spell, e.g. "destruction". nil when no spell is selected.
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

  presenceSection:subscribe(async:callback(function(_, key)
    if key == gameSelf.id then
      local presence = StorageGet(presenceSection, key)

      local thisCell = gameSelf.cell
      ---@cast thisCell openmw.core.LCell

      -- Only accept presence data written for the cell the player is actually in
      -- This prevents stale writes from a previous cell from corrupting PlaylistState
      if not presence or presence.cellId ~= thisCell.id then return end

      PlaylistState.nearestRegion = presence.nearestRegion or thisCell.region

      PlaylistState.objectsByRecord = presence.byRecord
      PlaylistState.objectsByType = presence.byType
      PlaylistState.objectsByContentFile = presence.byContentFile
      PlaylistState.staticObjectContentFiles = presence.staticContentFiles
      PlaylistState.cellHasHostileActors = presence.cellHasHostileActors
      PlaylistState.areaHasHostileActors = presence.areaHasHostileActors

      -- Compute total object count from byType so playlists can read PlaylistState.objectCount directly
      local total = 0
      for _, count in pairs(presence.byType) do
        total = total + count
      end

      PlaylistState.objectCount = total

      SendEvent(gameSelf, 'S3maphoreCellPresenceUpdated', presence.cellId)
    elseif key == 'GlobalKillCounts' then
      PlaylistState.killCounts = StorageGet(presenceSection, key)
    end
  end))
end

return PlaylistState
