---@type IDPresenceMap
local VivecCells = {
  ['vivec, palace of vivec'] = true,
}

---@type IDPresenceMap
local VivecCombatTargets = {
  ['vivec'] = true,
}

---@type ValidPlaylistCallback
local function vivecCellRule(playback)
  return not playback.state.cellIsExterior and playback.rules.cellNameExact(VivecCells)
end

---@type ValidPlaylistCallback
local function vivecCombatRule(playback)
  return playback.state.isInCombat and playback.rules.combatTargetExact(VivecCombatTargets)
end

---@type S3maphorePlaylist[]
return {
  {
    id = 'ms/cell/vivec/vivecpalace',
    priority = PlaylistPriority.Faction - 1,
    tracks = {
      'music/ms/cell/vivec/vivecpalace.mp3',
    },
    randomize = true,

    isValidCallback = vivecCellRule,
  },
  {
    id = 'ms/combat/vivec',
    priority = PlaylistPriority.BattleMod - 1,
    randomize = true,

    isValidCallback = vivecCombatRule,
  },
}
