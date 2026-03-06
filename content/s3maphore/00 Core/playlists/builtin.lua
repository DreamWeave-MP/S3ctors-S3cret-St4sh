---@module 'doc.playlistEnv'

---@type S3maphorePlaylist[]
return {
    {
        id = "Explore",
        priority = PlaylistPriority.Explore,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isExploring
        end,
    },
    {
        id = "Battle",
        priority = PlaylistPriority.BattleVanilla,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isInCombat
        end,
    },
}
