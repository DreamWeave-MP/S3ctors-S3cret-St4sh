---@type CellMatchPatterns
local fgMatches = {
  allowed = {
    'guild of fighters',
    'fighter\'s guild',
  },

  disallowed = {},
}

---@type ValidPlaylistCallback
local function fgOrCellRule(playback)
  return not Playback.state.isInCombat
    and not Playback.state.cellIsExterior
    and (Playback.rules.cellNameMatch(fgMatches))
end

---@type S3maphorePlaylist[]
return {
  {
    id = 'Daggerfall Guild Themes FG',

    tracks = {
      'Music/em_dynamicMusic/fighter_1.mp3',
    },

    -- Uses faction priority to override TR playlists
    priority = PlaylistPriority.Faction - 2,
    randomize = true,

    isValidCallback = fgOrCellRule,
  },
}
