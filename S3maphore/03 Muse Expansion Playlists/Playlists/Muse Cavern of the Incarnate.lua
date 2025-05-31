---@type IDPresenceMap
local IncarnateCells = {
    ['cavern of the incarnate'] = true,
}

---@type ValidPlaylistCallback
local function incarnateCellRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.cellNameExact(IncarnateCells)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'MUSE - Cavern of the Incarnate',
        priority = 50,
        noInterrupt = true,

        tracks = {
            'Music/MS/cell/Incarnate/incarnate.mp3',
        },

        isValidCallback = incarnateCellRule,
    },
}
