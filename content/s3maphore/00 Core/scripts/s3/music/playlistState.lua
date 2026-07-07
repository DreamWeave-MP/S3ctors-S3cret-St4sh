---@omw-context player

---@class PlaylistState
---@field cellHasWater boolean whether the current cell has water or not
---@field cellIsExterior boolean whether the player is in an exterior cell or not (includes fake exteriors such as starwind)
---@field cellName string lowercased name of the cell the player is in
---@field cellId string engine-level identifier for cells. Should generally not be used in favor of cellNames as the only way to determine cell ids is to check in-engine using `cell.id`. It is made available in PlaylistState mostly for caching purposes, but may be used regardless.
---@field cellWaterLevel number? If the current cell has water, then, it is copied here
---@field cellPresence CellPresence Object counts for the currently loaded cell (or active grid) — byRecord, byType, byContentFile, plus staticContentFiles, nearestRegion, cellHasHostileActors, and areaHasHostileActors
---@field objectCount number Total objects in the current cell, computed from cellPresence.byType
---@field combatTargets openmw.LObject[] combat targets in insertion order
---@field currentGrid ExteriorGrid? The current exterior cell grid. Nil if not in an actual exterior.
---@field isExploring boolean whether the player is currently exploring or not. Distinct from isInCombat as settings may control it.
---@field isInCombat boolean whether the player is in combat or not
---@field isUnderwater boolean
---@field nearestRegion string? The current region the player is in. This is determined by either checking the current region of the player's current cell, OR, reading all load door's target cell's regions in the current cell. The first cell which is found to have a region will match and be assigned to the PlaylistState.
---@field playlistTimeOfDay TimeOfDay the time of day for the current playlist
---@field weather string
local PlaylistState = {
  cellHasWater = false,
  cellIsExterior = false,
  cellName = '',
  cellPresence = {
    areaHasHostileActors = false,
    cellHasHostileActors = false,
    byContentFile = {},
    byRecord = {},
    byType = {},
    nearestRegion = '',
    staticContentFiles = {},
  },
  objectCount = 0,
  cellId = '',
  cellWaterLevel = nil,
  combatTargets = {},
  currentGrid = nil,
  isExploring = true,
  isInCombat = false,
  isUnderwater = false,
}

do
  local async = require 'openmw.async'
  local self = require 'openmw.self'
  local SendEvent = self.sendEvent
  local presenceSection = require('openmw.storage').globalSection 'S3maphoreCellPresence'

  presenceSection:subscribe(async:callback(function(_, key)
    if key ~= self.id then return end

    local presence = presenceSection:get(self.id)

    local thisCell = self.cell
    ---@cast thisCell openmw.core.LCell

    -- Only accept presence data written for the cell the player is actually in
    -- This prevents stale writes from a previous cell from corrupting PlaylistState
    if not presence or presence.cellId ~= thisCell.id then return end

    PlaylistState.nearestRegion = presence.nearestRegion or thisCell.region

    PlaylistState.cellPresence = presence

    -- Compute total object count from byType so playlists can read PlaylistState.objectCount directly
    local total = 0
    for _, count in pairs(presence.byType) do
      total = total + count
    end
    PlaylistState.objectCount = total

    SendEvent(self, 'S3maphoreCellPresenceUpdated')
  end))
end

return PlaylistState
