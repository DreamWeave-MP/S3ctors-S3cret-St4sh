---@type CellMatchPatterns
local DwemerPatterns = {
    allowed = {
        'rthzuncheft',
        'rthungzark',
    },
    disallowed = {
        'sewer',
        'dungeon',
    },
}

---@type CellMatchPatterns
local ImperialPatterns = {
    disallowed = {
        "sewer",
        "dungeon",
        "fields",
    },
    allowed = {
        'firewatch',
        'helnim',
    },
}

---@type CellMatchPatterns
local IndorilPatterns = {
    allowed = {
        'ammar',
        'akamora',
        'bisandryon',
        'bosmora',
        'enamor dayn',
        'sailen',
        'dreynim',
        'gorne',
        'roa dyr',
        'meralag',

    },
    disallowed = {
        'sewer',
        'dungeon',
    }
}

---@type CellMatchPatterns
local TelvanniSettlementMatches = {
    allowed = {
        'alt bosara',
        'gah sadrith',
        'llothanis',
        'marog',
        'tel aranyon',
        'tel mothrivra',
        'tel muthada',
        'tel oren',
        'tel ouada',
        'telvanni library',
        'verulas pass',
    },
    disallowed = {
        'dungeon',
        'sewer',
    }
}

---@type CellMatchPatterns
local PortTelvannisPatterns = {
    allowed = {
        'port telvannis'
    },

    disallowed = {},
}

---@type IDPresenceMap
local AanthirinRegions = {
    ['aanthirin region'] = true,
    ['thirr valley region'] = true,
    ['othreleth woods region'] = true,
}

---@type IDPresenceMap
local LanOrethanRegions = {
    ['lan orethan region'] = true,
    ['nedothril region'] = true,
}

---@type IDPresenceMap
local MournholdRegions = {
    ['helnim fields region'] = true,
    ['mephalan vales region'] = true,
    ['molag ruhn region'] = true,
}

---@type IDPresenceMap
local SeaRegions = {
    ['padomaic ocean region'] = true,
    ['sea of ghosts region'] = true,
}

---@type IDPresenceMap
local TelvannisRegions = {
    ['molagreahd region'] = true,
    ['sunad mora region'] = true,
    ['boethiah\'s spine region'] = true,
    ['aranyon pass region'] = true,
    ['telvanni isles region'] = true,
}

---@type IDPresenceMap
local UpperVelothisRegions = {
    ['velothi mountains region'] = true,
    ['uld vraech region'] = true,
}

---@type S3maphorePlaylist[]
return {
    {
        id = 'Tamriel Rebuilt - Aanthirin',
        priority = 948,
        randomize = true,

        tracks = {
            'Music/TR/region/Aanthirin/Aanthirin 1.mp3',
            'Music/TR/region/Aanthirin/Aanthirin 2.mp3',
            'Music/TR/region/Aanthirin/Thirr.mp3',
            'Music/TR/region/Aanthirin/Thirr 1.mp3',
            'Music/TR/region/Aanthirin/Thirr 2.mp3'
        },

        isValidCallback = function(playback)
            return playback.rules.region(AanthirinRegions)
        end,

    },
    {
        id = 'Tamriel Rebuilt - Armun Ashlands',
        priority = 942,
        randomize = true,

        tracks = {
            'Music/MS/region/Armun Ashlands Region/Ashlands.mp3',
            'Music/MS/region/Grey Meadows Region/Grey Meadows 1.mp3',
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'armun ashlands region'
        end,
    },
    {
        id = 'tamriel rebuilt/lan orethan',
        priority = 947,
        randomize = true,

        tracks = {
            'Music/MS/region/Lan Orethan/Lan Orethan.mp3',
            'Music/MS/region/Lan Orethan/Mournhold explore.mp3',
            'Music/MS/region/Lan Orethan/Road To Mournhold.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(LanOrethanRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Dwemer Ruins',
        priority = 698,
        randomize = true,
        tracks = {
            'Music/TR/interior/Dwemer ruins/Dwemer ruins.mp3',
            'Music/TR/interior/Dwemer ruins/Resonance.mp3',
        },
        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(DwemerPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Mournhold',
        priority = 946,
        randomize = true,

        tracks = {
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 1.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 2.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 3.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 4.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(MournholdRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Imperial',
        priority = 699,

        tracks = {
            'Music/MS/cell/ImperialCity/Beacon of Cyrodiil.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(ImperialPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Indoril Setlement',
        priority = 798,

        tracks = {
            'Music/MS/cell/MournCity/Indoril Settlement.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(IndorilPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Port Telvannis',
        priority = 697,
        randomize = true,

        tracks = {
            'Music/MS/region/Telvannis/Tellvannis 1.mp3',
            'Music/MS/region/Telvanni Isles/Port Telvannis.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(PortTelvannisPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Telvanni Settlement',
        priority = 799,
        randomize = true,

        tracks = {
            'Music/MS/cell/TelCity/Telvanni settlement.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(TelvanniSettlementMatches)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Sacred Lands',
        priority = 941,
        randomize = true,

        tracks = {
            'Music/MS/region/Sacred Lands Region/sacred lands 1.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 3.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 4.mp3',
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'sacred lands region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Seas',
        priority = 944,
        randomize = true,

        tracks = {
            'Music/MS/region/Seas/Dreamy athmospheres 1.mp3',
            'Music/MS/region/Seas/Dreamy athmospheres 2.mp3',
        },
        isValidCallback = function(playback)
            return playback.rules.region(SeaRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Sundered Scar',
        priority = 940,
        randomize = true,

        tracks = {
            'Music/MS/region/Sundered Scar Region/Mournhold Athmospheres 1.mp3',
            'Music/MS/region/Sundered Scar Region/Mournhold Athmospheres 2.mp3',
            'Music/MS/region/Sundered Scar Region/Mournhold fields.mp3',
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'sundered scar region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Telvannis Regions',
        priority = 949,
        randomize = true,

        tracks = {
            'Music/MS/region/Telvannis/Tellvannis 1.mp3',
            'Music/MS/region/Telvannis/Tellvannis 2.mp3',
            'Music/MS/region/Telvannis/Telvannis fields.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(TelvannisRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Upper Velothis',
        priority = 945,

        tracks = {
            'Music/MS/region/Velothis Upper/Through The Mountains.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(UpperVelothisRegions)
        end
    }
}
