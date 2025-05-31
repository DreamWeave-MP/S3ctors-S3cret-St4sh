---@type IDPresenceMap
local RedoranEnemyNames = {
    ['redoran guard'] = true,
    ['bolvyn venim'] = true,
    ['minor arobar'] = true,
    ['garisa llethri'] = true,
    ['mistress brara morvayn'] = true,
    ['hlaren ramoran'] = true,
    ['athyn sarethi'] = true,
    ['banden indarys'] = true,
}

---@type ValidPlaylistCallback
local function redoranEnemyRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(RedoranEnemyNames)
end

---@type CellMatchPatterns
local RedoranCellNames = {
    allowed = {
        'ald-ruhn',
        'maar gan',
        'ald velothi',
        'khuul',
        'indarys manor',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function redoranCellRule(playback)
    return not playback.state.isInCombat
        and playback.rules.cellNameMatch(RedoranCellNames)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'MUSE - Redoran Settlement',
        priority = 397,
        randomize = true,

        tracks = {
            'Music/MS/cell/Redoran/exploration1.mp3',
            'Music/MS/cell/Redoran/exploration2.mp3',
            'Music/MS/cell/Redoran/exploration3.mp3',
            'Music/MS/cell/Redoran/exploration4.mp3',
            'Music/MS/cell/Redoran/exploration5.mp3',
        },

        isValidCallback = redoranCellRule,

    },
    {
        id = 'MUSE - Redoran Enemies',
        priority = 192,

        tracks = {
            'Music/MS/combat/Redoran/combat1.mp3',
            'Music/MS/combat/Redoran/combat2.mp3',
            'Music/MS/combat/Redoran/combat3.mp3',
        },

        isValidCallback = redoranEnemyRule,
    }
}
