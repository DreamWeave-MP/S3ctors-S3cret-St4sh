---@type IDPresenceMap
local EmpireEnemyNames = {
    ['guard'] = true,
    ['imperial guard'] = true,
    ['guard captain'] = true,
    ['duke\'s guard'] = true,
    ['company guard'] = true,
    ['varus vantinius'] = true,
    ['arius rulician'] = true,
    ['oritius maro'] = true,
    ['lugrub gro-ogdum'] = true,
    ['honthjolf'] = true,
    ['furius acilius'] = true,
    ['cavortius albuttian'] = true,
    ['imsin the dreamer'] = true,
    ['frald the white'] = true,
    ['captain falx carius'] = true,
    ['darius'] = true,
    ['radd hard-heart'] = true,
    ['angoril'] = true,
    ['caius cosades'] = true,
    ['gildan'] = true,
    ['nine-toes'] = true,
    ['rithleen'] = true,
    ['tyermallin'] = true,
    ['surane leoriane'] = true,
    ['elone'] = true,
    ['sjorvar horse-mouth'] = true,
    ['carnius magius'] = true,
    ['falco galenus'] = true,
}

---@type ValidPlaylistCallback
local function empireEnemyRule(playback)
    return playback.rules.combatTargetExact(EmpireEnemyNames)
end

---@type CellMatchPatterns
local EmpireCellMatches = {
    allowed = {
        'caldera',
        'ebonheart',
        'ebon tower',
        'pelagiad',
        'seyda neen',
        'moonmoth',
        'darius',
        'firemoth',
        'frostmoth',
        'buckmoth',
        'hawkmoth',
        'wolverine hall',
        'raven rock',
    },
    disallowed = {
        'mage\'s guild',
        'fighter\'s guild',
        'guild of mages',
        'guild of fighters',
    },
}

---@type ValidPlaylistCallback
local function empireCellRule(playback)
    return playback.rules.cellNameMatch(EmpireCellMatches)
end
---@type S3maphorePlaylist[]
return {
    {
        id = 'MUSE - Empire Settlement',
        priority = 399,
        randomize = true,

        tracks = {
            "music/ms/cell/empire/exploration1.mp3",
            "music/ms/cell/empire/exploration2.mp3",
            "music/ms/cell/empire/exploration3.mp3",
            "music/ms/cell/empire/exploration4.mp3",
            "music/ms/cell/empire/exploration5.mp3",
        },

        isValidCallback = empireCellRule
    },
    {
        id = 'MUSE - Empire Enemies',
        priority = 196,
        randomize = true,

        tracks = {
            "Music/MS/combat/Empire/combat1.mp3",
            "Music/MS/combat/Empire/combat2.mp3",
            "Music/MS/combat/Empire/combat3.mp3",
        },

        isValidCallback = empireEnemyRule
    },
}
