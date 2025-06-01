local HlaaluEnemyNames = {
    ['hlaalu guard'] = true,
    ['duke vedam dren'] = true,
    ['nevena ules'] = true,
    ['crassius curio'] = true,
    ['dram bero'] = true,
    ['yngling half-troll'] = true,
    ['ranes ienith'] = true,
    ['navil ienith'] = true,
    ['orvas dren'] = true,
    ['madrale thirith'] = true,
    ['marasa aren'] = true,
    ['sovor trandel'] = true,
    ['thanelen velas'] = true,
    ['vadusa sathryon'] = true,
}

---@type ValidPlaylistCallback
local function hlaaluEnemyRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(HlaaluEnemyNames)
end

local HlaaluCellNames = {
    allowed = {
        'balmora',
        'suran',
        'gnaar mok',
        'hla oad',
        'rethan manor',
        'arvel plantation',
        'arano plantation',
        'dren plantation',
        'omani manor',
        'ules manor',
        'gro-bagrat plantation',
    },
    disallowed = {},
}

---@type ValidPlaylistCallback
local function hlaaluCellRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameMatch(HlaaluCellNames)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'MUSE - Hlaalu Settlement',
        priority = PlaylistPriority.Faction,
        randomize = true,

        tracks = {
            'Music/MS/cell/Hlaalu/exploration1.mp3',
            'Music/MS/cell/Hlaalu/exploration2.mp3',
            'Music/MS/cell/Hlaalu/exploration3.mp3',
            'Music/MS/cell/Hlaalu/exploration4.mp3',
            'Music/MS/cell/Hlaalu/exploration5.mp3',
        },

        isValidCallback = hlaaluCellRule,
    },
    {
        id = 'MUSE - Hlaalu Enemies',
        priority = PlaylistPriority.BattleMod,

        tracks = {
            'Music/MS/combat/Hlaalu/combat1.mp3',
            'Music/MS/combat/Hlaalu/combat2.mp3',
            'Music/MS/combat/Hlaalu/combat3.mp3',
        },

        isValidCallback = hlaaluEnemyRule,
    }
}
