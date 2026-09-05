---@type CellMatchPatterns
local mgMatches = {
  allowed = {
    'guild of mages',
    'mage\'s guild',
  },

  disallowed = {},
}

---@type ValidPlaylistCallback
local function mgOrCellRule(playback)
  return not Playback.state.isInCombat
    and not Playback.state.cellIsExterior
    and (Playback.rules.cellNameMatch(mgMatches))
end

---@type S3maphorePlaylist[]
return {
  {
    id = 'Daggerfall Guild Themes MG',

    tracks = {
      'Music/em_dynamicMusic/mage_2.mp3',
      'Music/em_dynamicMusic/mage_3.mp3',
    },

    -- Uses faction priority to override TR playlists
    priority = PlaylistPriority.Faction - 2,
    randomize = true,

    isValidCallback = mgOrCellRule,
  },
}
