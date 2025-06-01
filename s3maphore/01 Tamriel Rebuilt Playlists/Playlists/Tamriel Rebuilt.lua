---@type IDPresenceMap
local DwemerStaticIds = {
    ['in_dwe_archway00_end'] = true,
    ['in_dwe_archway00_exp'] = true,
    ['in_dwe_corr2_00_exp'] = true,
    ['in_dwe_corr4_exp'] = true,
    ['in_dwe_end00_exp'] = true,
    ['in_dwe_hall00_exp'] = true,
    ['in_dwe_hall_enter_00'] = true,
    ['in_dwe_hall_wall00_bk'] = true,
    ['in_dwe_hall_wall00_exp'] = true,
    ['in_dwe_pillar00_exp'] = true,
    ['in_dwe_pill_bk00'] = true,
    ['in_dwe_pill_bk01'] = true,
    ['in_dwe_pill_bk02'] = true,
    ['in_dwe_pill_bk03'] = true,
    ['in_dwe_pipe00_exp'] = true,
    ['in_dwe_ramp00_exp'] = true,
    ['in_dwe_rod00_exp'] = true,
    ['in_dwe_rod01_exp'] = true,
    ['in_dwe_rubble00'] = true,
    ['in_dwe_rubble01'] = true,
    ['in_dwe_rubble02'] = true,
    ['in_dwe_slate00'] = true,
    ['in_dwe_slate01'] = true,
    ['in_dwe_slate02'] = true,
    ['in_dwe_slate03'] = true,
    ['in_dwe_slate04'] = true,
    ['in_dwe_slate05'] = true,
    ['in_dwe_slate06'] = true,
    ['in_dwe_slate07'] = true,
    ['in_dwe_slate08'] = true,
    ['in_dwe_slate09'] = true,
    ['in_dwe_slate10'] = true,
    ['in_dwe_slate11'] = true,
    ['in_dwe_turbine00_exp'] = true,
    ['in_dwe_utilcorr00_exp'] = true,
    ['in_dwe_utilcorr01_exp'] = true,
    ['in_dwe_weathmach00_exp'] = true,
    ['in_dwr_tower_int00'] = true,
    ['in_dwr_tower_int000'] = true,
    ['in_dwr_tower_int001'] = true,
    ['in_dwrv_corr1_00'] = true,
    ['in_dwrv_corr2_00'] = true,
    ['in_dwrv_corr2_01'] = true,
    ['in_dwrv_corr2_02'] = true,
    ['in_dwrv_corr2_03'] = true,
    ['in_dwrv_corr2_04'] = true,
    ['in_dwrv_corr3_00'] = true,
    ['in_dwrv_corr3_01'] = true,
    ['in_dwrv_corr3_02'] = true,
    ['in_dwrv_corr4_00'] = true,
    ['in_dwrv_corr4_01'] = true,
    ['in_dwrv_corr4_02'] = true,
    ['in_dwrv_corr4_03'] = true,
    ['in_dwrv_corr4_04'] = true,
    ['in_dwrv_corr4_05'] = true,
    ['in_dwrv_doorjam00'] = true,
    ['in_dwrv_door_static00'] = true,
    ['in_dwrv_enter00_dn'] = true,
    ['in_dwrv_gear00'] = true,
    ['in_dwrv_gear10'] = true,
    ['in_dwrv_gear20'] = true,
    ['in_dwrv_hall2_00'] = true,
    ['in_dwrv_hall3_00'] = true,
    ['in_dwrv_hall4_00'] = true,
    ['in_dwrv_hall4_01'] = true,
    ['in_dwrv_hall4_02'] = true,
    ['in_dwrv_hall4_03'] = true,
    ['in_dwrv_lift00'] = true,
    ['in_dwrv_obsrv00'] = true,
    ['in_dwrv_oilslick00'] = true,
    ['in_dwrv_scope00'] = true,
    ['in_dwrv_scope10'] = true,
    ['in_dwrv_scope20'] = true,
    ['in_dwrv_scope30'] = true,
    ['in_dwrv_scope40'] = true,
    ['in_dwrv_scope50'] = true,
    ['in_dwrv_shaft00'] = true,
    ['in_dwrv_shaft10'] = true,
    ['in_dwrv_wall00'] = true,
    ['in_dwrv_wall10'] = true,
    ['in_dwrv_wall_nchuleftingth1'] = true,
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

---@type IDPresenceMap
local TContentFiles = {
    ['tr_mainland.esm'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'Tamriel Rebuilt - Aanthirin',
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.Region,
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
        id = 'Tamriel Rebuilt - Lan Orethan',
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.Tileset - 1,
        randomize = true,
        tracks = {
            'Music/TR/interior/Dwemer ruins/Dwemer ruins.mp3',
            'Music/TR/interior/Dwemer ruins/Resonance.mp3',
        },
        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(TContentFiles)
                and playback.rules.staticExact(DwemerStaticIds)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Mournhold',
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.CellMatch,

        tracks = {
            'Music/MS/cell/ImperialCity/Beacon of Cyrodiil.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(ImperialPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Indoril Setlement',
        priority = PlaylistPriority.City,

        tracks = {
            'Music/MS/cell/MournCity/Indoril Settlement.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(IndorilPatterns)
        end,
    },
    {
        id = 'Tamriel Rebuilt - Port Telvannis',
        priority = PlaylistPriority.CellMatch,
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
        priority = PlaylistPriority.City,
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
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.Region,
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
        priority = PlaylistPriority.Region,

        tracks = {
            'Music/MS/region/Velothis Upper/Through The Mountains.mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(UpperVelothisRegions)
        end
    }
}
