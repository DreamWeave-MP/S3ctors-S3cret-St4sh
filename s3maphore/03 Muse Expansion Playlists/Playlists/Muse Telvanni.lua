local PlaylistPriority = require 'doc.playlistPriority'

---@type CellMatchPatterns
local TelvanniMatches = {
    allowed = {
        'sadrith mora',
        'tel mora',
        'tel vos',
        'tel aruhn',
        'tel branora',
        'tel fyr',
        'tel uvirith',
    },

    disallowed = {
        'sewers',
    },
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/cell/telvanni',
        priority = PlaylistPriority.Faction,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and playback.rules.cellNameMatch(TelvanniMatches)
        end
    },
}
