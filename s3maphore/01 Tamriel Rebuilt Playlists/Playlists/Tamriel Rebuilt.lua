---@type S3maphorePlaylistEnv
_ENV = _ENV

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
        'old ebonheart',
        'teyn',
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
        'vhul',
        'dondril',
        'aimrah',
        'felms ithul',
        'saveri',
        'eravan',
        'selyn',
        'velonith',
        'rilsoan',
        'darvonis',
        'othrenis',
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
        'verulas pass',
    },
    disallowed = {
        'dungeon',
        'sewer',
    }
}

---@type CellMatchPatterns
local TempleSettlementMatches = {
    allowed = {
        'necrom',
        'almas thirr',
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
local OrethanRegions = {
    ['alt orethan region'] = true,
    ['lan orethan region'] = true,
}

---@type IDPresenceMap
local MournholdRegions = {
    ['mephalan vales region'] = true,
    ['sundered scar region'] = true,
    ['nedothril region'] = true,
}

---@type IDPresenceMap
local SeaRegions = {
    ['padomaic ocean region'] = true,
    ['sea of ghosts region'] = true,
}

---@type IDPresenceMap
local TelvannisRegions = {
    ['aranyon pass region'] = true,
    ['boethiah\'s spine region'] = true,
    ['dagon urul region'] = true,
    ['molagreahd region'] = true,
    ['sunad mora region'] = true,
    ['telvanni isles region'] = true,
}

---@type IDPresenceMap
local ThirrRegions = {
    ['roth roryn region'] = true,
    ['thirr valley region'] = true,
    ['othreleth woods region'] = true,
}

---@type IDPresenceMap
local UpperVelothisRegions = {
    ['clambering moor region'] = true,
    ['velothi mountains region'] = true,
    ['uld vraech region'] = true,
}

---@type IDPresenceMap
local TContentFiles = {
    ['tr_mainland.esm'] = true,
}

---@type CellMatchPatterns
local TombCellMatches = {
    allowed = {
        'ancestral tomb',
        'barrow',
        'burial',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function caveTRRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.staticContentFile(TContentFiles)
        and playback.rules.staticExact(Tilesets.Cave)
end

---@type ValidPlaylistCallback
local function tombTRRule(playback)
    return not playback.state.cellIsExterior
        and playback.rules.staticContentFile(TContentFiles)
        and playback.rules.cellNameMatch(TombCellMatches)
end

---@type S3maphorePlaylist[]
return {
    {
        id = 'Tamriel Rebuilt - Aanthirin',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Aanthirin/Aanthirin 1.mp3',
            'Music/MS/region/Aanthirin/Aanthirin 2.mp3',
            'Music/MS/region/Aanthirin/Thirr.mp3',
            'Music/MS/region/Aanthirin/Thirr 1.mp3',
            'Music/MS/region/Aanthirin/Thirr 2.mp3'
        },

        isValidCallback = function()
            return Playback.state.self.cell.region == 'aanthirin region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Thirr',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Aanthirin/Thirr.mp3',
            'Music/MS/region/Aanthirin/Thirr 1.mp3',
            'Music/MS/region/Aanthirin/Thirr 2.mp3'
        },

        isValidCallback = function()
            return Playback.rules.region(ThirrRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Armun Ashlands',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Armun Ashlands Region/Ashlands.mp3',

        },

        isValidCallback = function()
            return Playback.state.self.cell.region == 'armun ashlands region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Grey Meadows',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Grey Meadows Region/Grey Meadows 1.mp3',
            'Music/MS/region/Grey Meadows Region/Grey Meadows 2.mp3',
        },
        isValidCallback = function()
            return Playback.state.self.cell.region == 'grey meadows region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Orethan',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Alt Orethan Region/Mournhold fields.mp3',
            'Music/MS/region/Lan Orethan/Lan Orethan.mp3',
            'Music/MS/region/Lan Orethan/Mournhold explore.mp3',
            'Music/MS/region/Lan Orethan/Road To Mournhold.mp3',
        },

        isValidCallback = function()
            return Playback.rules.region(OrethanRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Dwemer Ruins',
        priority = PlaylistPriority.Tileset - 1,
        randomize = true,
        tracks = {
            'music/MS/general/TR Dungeon/Darkness.mp3',
            'Music/MS/interior/tr dwemer/Dwemer ruins.mp3',
            'Music/MS/interior/tr dwemer/Resonance.mp3',
        },
        isValidCallback = function()
            return not Playback.state.cellIsExterior
                and Playback.rules.staticContentFile(TContentFiles)
                and Playback.rules.staticExact(Tilesets.Dwemer)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Caves',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/general/TR Dungeon/Darkness.mp3',
            'Music/MS/interior/TR cave/Cave 1.mp3',
            'Music/MS/interior/TR cave/Cave 2.mp3',
        },

        isValidCallback = caveTRRule,
    },
    {
        id = 'Tamriel Rebuilt - Tombs',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/general/TR Dungeon/Darkness.mp3',
            'Music/MS/interior/TR tomb/Tombs.mp3',
        },

        isValidCallback = tombTRRule,
    },
    {
        id = 'Tamriel Rebuilt - Indoril Regions',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 1.mp3',
            'Music/MS/region/Mournhold hills/Mournhold Athmospheres 2.mp3',
            'Music/MS/region/Mournhold hills/Mournhold explore.mp3',
            'Music/MS/region/Mournhold hills/Mournhold fields.mp3',
        },

        isValidCallback = function()
            return Playback.rules.region(MournholdRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Imperial',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/cell/ImperialCity/Beacon of Cyrodiil.mp3',
        },

        isValidCallback = function()
            return Playback.rules.cellNameMatch(ImperialPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Indoril Setlement',
        priority = PlaylistPriority.City,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/cell/MournCity/Indoril Settlement.mp3',
        },

        isValidCallback = function()
            return Playback.rules.cellNameMatch(IndorilPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Port Telvannis',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/region/Telvanni Isles/Port Telvannis.mp3',
        },

        isValidCallback = function()
            return Playback.rules.cellNameMatch(PortTelvannisPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Telvanni Settlement',
        priority = PlaylistPriority.City,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/cell/TelCity/Telvanni settlement.mp3',

        },

        isValidCallback = function()
            return Playback.rules.cellNameMatch(TelvanniSettlementMatches)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Temple Settlement',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 1.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 3.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 4.mp3',
        },

        isValidCallback = function()
            return Playback.rules.cellNameMatch(TempleSettlementMatches)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Sacred Lands',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 1.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 2.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 3.mp3',
            'Music/MS/region/Sacred Lands Region/sacred lands 4.mp3',
        },

        isValidCallback = function()
            return Playback.state.self.cell.region == 'sacred lands region'
        end,
    },
    {
        id = 'Tamriel Rebuilt - Seas',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/region/Seas/Dreamy athmospheres 1.mp3',
            'Music/MS/region/Seas/Dreamy athmospheres 2.mp3',
        },
        isValidCallback = function()
            return Playback.rules.region(SeaRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Telvannis Regions',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Telvannis/Tellvannis 1.mp3',
            'Music/MS/region/Telvannis/Tellvannis 2.mp3',
            'Music/MS/region/Telvannis/Telvannis fields.mp3',
        },

        isValidCallback = function()
            return Playback.rules.region(TelvannisRegions)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Upper Velothis',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'Music/MS/general/TRairdepths/Dreamy athmospheres 1.mp3',
            'Music/MS/general/TRairdepths/Dreamy athmospheres 2.mp3',
            'Music/MS/region/Velothis Upper/Through The Mountains.mp3',
        },

        isValidCallback = function()
            return Playback.rules.region(UpperVelothisRegions)
        end
    }
}
