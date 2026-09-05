---@module 'doc.playlistEnv'

---@type IDPresenceMap
local VampireBossNames = {
  ['raxle berne'] = true,
  ['volrina quarra'] = true,
  ['dhaunayne aundae'] = true,
  ['akavorioc'] = true,
  ['zargoryn thalen'] = true,
  ['ancasarion'] = true,
  ['alnemthirh'] = true,
  ['njelfa'] = true,
  ['armennu'] = true,
}

---@type ValidPlaylistCallback
local function vampireBossRule(playback)
  return Playback.state.isInCombat and Playback.rules.combatTargetExact(VampireBossNames)
end

---@type S3maphorePlaylist[]
return {
  {
    id = 'ms/combat/vampire',
    priority = PlaylistPriority.BattleMod - 1,
    randomize = true,
    fadeOut = 0,

    isValidCallback = vampireBossRule,
  },
}
