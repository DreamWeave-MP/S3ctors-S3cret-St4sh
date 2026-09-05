---@type CellMatchPatterns
local VivecMatches = {
  allowed = {
    'vivec',
  },

  disallowed = {
    'sewers',
    'underworks',
  },
}

---@type S3maphorePlaylist[]
return {
  {
    id = 'ms/cell/vivec',
    priority = PlaylistPriority.CellMatch,
    randomize = true,

    exclusions = {
      tracks = {
        'ms/cell/vivec/vivecpalace',
      },
    },

    isValidCallback = function()
      return not Playback.state.isInCombat and Playback.rules.cellNameMatch(VivecMatches)
    end,
  },
}
