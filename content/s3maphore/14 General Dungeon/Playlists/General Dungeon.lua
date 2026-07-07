---@module 'doc.playlistEnv'

---@type ValidPlaylistCallback
local function generalDungeonRule()
  return not Playback.state.cellIsExterior
    and Playback.state.cellPresence.cellHasHostileActors
    and not Playback.state.isInCombat
end

---@type ValidPlaylistCallback
local function combatDungeonRule()
  return not Playback.state.cellIsExterior
    and Playback.state.cellPresence.cellHasHostileActors
    and Playback.state.isInCombat
end

---@type S3maphorePlaylist[]
return {
  {
    id = 's3/dungeon',
    priority = PlaylistPriority.Tileset + 1,
    randomize = true,
    isValidCallback = generalDungeonRule,
  },
  {
    id = 's3/dungeon-combat',
    priority = PlaylistPriority.BattleMod - 2,
    randomize = true,
    isValidCallback = combatDungeonRule,
  },
}
