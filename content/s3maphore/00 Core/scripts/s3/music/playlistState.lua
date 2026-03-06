---@class PlaylistState
---@field cellHasWater boolean whether the current cell has water or not
---@field cellIsExterior boolean whether the player is in an exterior cell or not (includes fake exteriors such as starwind)
---@field cellName string lowercased name of the cell the player is in
---@field cellId string engine-level identifier for cells. Should generally not be used in favor of cellNames as the only way to determine cell ids is to check in-engine using `cell.id`. It is made available in PlaylistState mostly for caching purposes, but may be used regardless.
---@field cellHasCombatTargets boolean
---@field cellWaterLevel number? If the current cell has water, then, it is copied here
---@field combatTargets table<string, GameObject> a read-only table of combat targets, where keys are actor IDs and values are the actors themselves
---@field currentGrid ExteriorGrid? The current exterior cell grid. Nil if not in an actual exterior.
---@field isInCombat boolean whether the player is in combat or not
---@field isUnderwater boolean
---@field nearestRegion string? The current region the player is in. This is determined by either checking the current region of the player's current cell, OR, reading all load door's target cell's regions in the current cell. The first cell which is found to have a region will match and be assigned to the PlaylistState.
---@field playlistTimeOfDay TimeOfDay the time of day for the current playlist
---@field staticList StaticList
---@field weather WeatherType
local PlaylistState = {
  cellHasWater = false,
  cellIsExterior = false,
  cellName = '',
  cellId = '',
  cellHasCombatTargets = false,
  cellWaterLevel = nil,
  combatTargets = {},
  currentGrid = nil,
  isUnderwater = false,
  staticList = {
    recordIds = {},
    contentFiles = {},
  },
}

return PlaylistState
