---@omw-context player

---@type CellMatchPatterns
local MournholdMatches = {
  allowed = { 'mournhold' },
  disallowed = { 'old mournhold' },
}

---@type S3maphorePlaylist[]
return {
  {
    id = 'ms/cell/mournhold',
    priority = PlaylistPriority.City,
    randomize = true,
    isValidCallback = function()
      return not Playback.state.isInCombat and Playback.rules.cellNameMatch(MournholdMatches)
    end,
  },
}
