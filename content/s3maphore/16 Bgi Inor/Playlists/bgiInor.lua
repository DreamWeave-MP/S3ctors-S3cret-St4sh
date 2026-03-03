---@module 'doc.playlistEnv'

return {
    {
        id = "Battle",
        priority = PlaylistPriority.Special,
        tracks = {
            "bigIronAlphabetical.opus",
        },

        isValidCallback = function()
            return Playback.state.isInCombat
        end,
    },
}
