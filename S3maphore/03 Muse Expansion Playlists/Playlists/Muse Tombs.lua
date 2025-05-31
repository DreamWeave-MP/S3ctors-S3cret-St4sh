---@type IDPresenceMap
local TombEnemyNames = {
    ['ancestor ghost'] = true,
    ['ancestor guardian'] = true,
    ['gateway haunt'] = true,
    ['ghost of galos heleran'] = true,
    ['kanit ashurnisammis'] = true,
    ['mansilamat vabdas'] = true,
    ['wraith of sul-senipul'] = true,
    ['bonelord'] = true,
    ['bonewalker'] = true,
    ['lesser bonewalker'] = true,
    ['greater bonewalker'] = true,
    ['beldoh the undying'] = true,
    ['crippled skeleton'] = true,
    ['skeleton'] = true,
    ['skeleton archer'] = true,
    ['skeleton champion'] = true,
    ['skeleton war-wizard'] = true,
    ['skeleton warrior'] = true,
    ['worm lord'] = true,
    ['lich'] = true,
    ['profane acolyte'] = true,
    ['gedna relvel'] = true,
    ['barilzar'] = true,
    ['greater ancestor ghost'] = true,
    ['variner\'s ghost'] = true,
    ['bonewolf'] = true,
    ['draugr'] = true,
    ['valbrandr draugr'] = true,
    ['draugr lord aesliip'] = true,
    ['skeleton berserker'] = true,
    ['skeleton pirate'] = true,
    ['skeleton pirate captain'] = true,
    ['greater skeleton champion'] = true,
}

---@type ValidPlaylistCallback
local function tombEnemyRule(playback)
    return playback.rules.combatTargetExact(TombEnemyNames)
end

---@type CellMatchPatterns
local TombCellMatches = {
    allowed = {
        'ancestral tomb',
        'gedna relvel\'s tomb',
        'abandoned crypt',
        'barrow',
        'burial',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function tombCellRule(playback)
    return playback.rules.cellNameMatch(TombCellMatches)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'MUSE - Tomb Cells',
        priority = 700,

        tracks = {
            'Music/MS/cell/Tomb/exploration1.mp3',
            'Music/MS/cell/Tomb/exploration2.mp3',
            'Music/MS/cell/Tomb/exploration3.mp3',
            'Music/MS/cell/Tomb/exploration4.mp3',
            'Music/MS/cell/Tomb/exploration5.mp3',
        },

        isValidCallback = tombCellRule,
    },
    {
        id = 'MUSE - Tomb Enemies',
        priority = 197,
        randomize = true,

        tracks = {
            "Music/MS/combat/Tomb/combat1.mp3",
            "Music/MS/combat/Tomb/combat2.mp3",
            "Music/MS/combat/Tomb/combat3.mp3",
            "Music/MS/combat/Tomb/combat4.mp3",
        },

        isValidCallback = tombEnemyRule,
    },
}
