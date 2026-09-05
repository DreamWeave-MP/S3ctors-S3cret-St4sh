---@type IDPresenceMap
local AlmalexiaCells = {
  ['mournhold temple: high chapel'] = true,
}

---@type IDPresenceMap
local AlmalexiaCombatTargets = {
  ['almalexia'] = true,
}

---@type ValidPlaylistCallback
local function almalexiaCellRule(playback)
  return not Playback.state.cellIsExterior and Playback.rules.cellNameExact(AlmalexiaCells)
end

---@type ValidPlaylistCallback
local function almalexiaCombatRule(playback)
  return Playback.state.isInCombat and Playback.rules.combatTargetExact(AlmalexiaCombatTargets)
end

---@type S3maphorePlaylist[]
return {
  {
    id = 'ms/cell/almalexia',
    priority = PlaylistPriority.Faction,
    randomize = true,

    isValidCallback = almalexiaCellRule,
  },
  {
    id = 'ms/combat/almalexia',
    priority = PlaylistPriority.BattleMod - 1,
    randomize = true,

    isValidCallback = almalexiaCombatRule,
  },
}
