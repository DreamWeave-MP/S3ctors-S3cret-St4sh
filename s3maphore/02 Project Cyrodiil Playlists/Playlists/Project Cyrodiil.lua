---@type CellMatchPatterns
local AnvilPatterns = {
    allowed = {
        "anvil",
        "marav",
        "hal sadek",
        "archad",
        "brina cross",
        "goldstone",
        "charach"
    },

    disallowed = {
        'sewer',
        'underworks',
        'crypt',
    },
}

---@type IDPresenceMap
local AyleidStatics = {
    ['t_ayl_dngruin_i_3wayse_02'] = true,
    ['t_ayl_dngruin_i_block_01'] = true,
    ['t_ayl_dngruin_i_block_02'] = true,
    ['t_ayl_dngruin_i_block_03'] = true,
    ['t_ayl_dngruin_i_block_04'] = true,
    ['t_ayl_dngruin_i_block_05'] = true,
    ['t_ayl_dngruin_i_block_06'] = true,
    ['t_ayl_dngruin_i_ceilingspike_01'] = true,
    ['t_ayl_dngruin_i_divider_01'] = true,
    ['t_ayl_dngruin_i_divider_02'] = true,
    ['t_ayl_dngruin_i_doorframe_01'] = true,
    ['t_ayl_dngruin_i_doorframe_02'] = true,
    ['t_ayl_dngruin_i_doorframe_03'] = true,
    ['t_ayl_dngruin_i_entrance_01'] = true,
    ['t_ayl_dngruin_i_entrance_02'] = true,
    ['t_ayl_dngruin_i_entrancesprl_01'] = true,
    ['t_ayl_dngruin_i_entrsprltwr_01'] = true,
    ['t_ayl_dngruin_i_floor_01'] = true,
    ['t_ayl_dngruin_i_floor_02'] = true,
    ['t_ayl_dngruin_i_flrrais3way_01'] = true,
    ['t_ayl_dngruin_i_flrrais4way_01'] = true,
    ['t_ayl_dngruin_i_flrraiscen_01'] = true,
    ['t_ayl_dngruin_i_flrraiscen_02'] = true,
    ['t_ayl_dngruin_i_flrraiscorn_01'] = true,
    ['t_ayl_dngruin_i_flrraisend_01'] = true,
    ['t_ayl_dngruin_i_flrraismid_01'] = true,
    ['t_ayl_dngruin_i_hall_01'] = true,
    ['t_ayl_dngruin_i_hall_02'] = true,
    ['t_ayl_dngruin_i_hall3way_01'] = true,
    ['t_ayl_dngruin_i_hall3way_02'] = true,
    ['t_ayl_dngruin_i_hall4way_01'] = true,
    ['t_ayl_dngruin_i_hall4way_02'] = true,
    ['t_ayl_dngruin_i_hallcaveic_01'] = true,
    ['t_ayl_dngruin_i_hallcavesh_01'] = true,
    ['t_ayl_dngruin_i_hallend_01'] = true,
    ['t_ayl_dngruin_i_hallend_02'] = true,
    ['t_ayl_dngruin_i_hallfitting_01'] = true,
    ['t_ayl_dngruin_i_hallramp_01'] = true,
    ['t_ayl_dngruin_i_hallramp_02'] = true,
    ['t_ayl_dngruin_i_hallstair_01'] = true,
    ['t_ayl_dngruin_i_hallstair_02'] = true,
    ['t_ayl_dngruin_i_hallturn_01'] = true,
    ['t_ayl_dngruin_i_hallturn_02'] = true,
    ['t_ayl_dngruin_i_hallturn_03'] = true,
    ['t_ayl_dngruin_i_lightfix_01'] = true,
    ['t_ayl_dngruin_i_lightfix_02'] = true,
    ['t_ayl_dngruin_i_lightfix_03'] = true,
    ['t_ayl_dngruin_i_pedestal_01'] = true,
    ['t_ayl_dngruin_i_pedestal_02'] = true,
    ['t_ayl_dngruin_i_pedestal_03'] = true,
    ['t_ayl_dngruin_i_pitbridge_01'] = true,
    ['t_ayl_dngruin_i_pitbridge3w_01'] = true,
    ['t_ayl_dngruin_i_pitbridge4w_01'] = true,
    ['t_ayl_dngruin_i_pitbridgearc_01'] = true,
    ['t_ayl_dngruin_i_pitbridgearc_02'] = true,
    ['t_ayl_dngruin_i_pitbridgebr_01'] = true,
    ['t_ayl_dngruin_i_pitbridgecap_01'] = true,
    ['t_ayl_dngruin_i_pitbridge_crn_0'] = true,
    ['t_ayl_dngruin_i_pitbridgeend_01'] = true,
    ['t_ayl_dngruin_i_pitbridgeplbr_0'] = true,
    ['t_ayl_dngruin_i_pitbridges_01'] = true,
    ['t_ayl_dngruin_i_pitbridges_02'] = true,
    ['t_ayl_dngruin_i_pitceiling_01'] = true,
    ['t_ayl_dngruin_i_pitceiling_02'] = true,
    ['t_ayl_dngruin_i_pitcolumn_01'] = true,
    ['t_ayl_dngruin_i_pitcolumncrn_01'] = true,
    ['t_ayl_dngruin_i_pitcolumnw_01'] = true,
    ['t_ayl_dngruin_i_pitcornert_01'] = true,
    ['t_ayl_dngruin_i_pitdivider_01'] = true,
    ['t_ayl_dngruin_i_pitdivider_02'] = true,
    ['t_ayl_dngruin_i_pitdivider_03'] = true,
    ['t_ayl_dngruin_i_pitfloor_01'] = true,
    ['t_ayl_dngruin_i_pitfloor_02'] = true,
    ['t_ayl_dngruin_i_pitflooredcr_01'] = true,
    ['t_ayl_dngruin_i_pitflooredst_01'] = true,
    ['t_ayl_dngruin_i_pitstairs_01'] = true,
    ['t_ayl_dngruin_i_pitwall_01'] = true,
    ['t_ayl_dngruin_i_pitwallbr_01'] = true,
    ['t_ayl_dngruin_i_pitwallc_01_'] = true,
    ['t_ayl_dngruin_i_pitwalle_01'] = true,
    ['t_ayl_dngruin_i_pitwallt_01'] = true,
    ['t_ayl_dngruin_i_pitwallt_02'] = true,
    ['t_ayl_dngruin_i_pitwalltentr_01'] = true,
    ['t_ayl_dngruin_i_pitwallttrsl_01'] = true,
    ['t_ayl_dngruin_i_pitwallttrsr_01'] = true,
    ['t_ayl_dngruin_i_ridge_01'] = true,
    ['t_ayl_dngruin_i_ridgeext_01'] = true,
    ['t_ayl_dngruin_i_ridgeext_02'] = true,
    ['t_ayl_dngruin_i_ridgeext_03'] = true,
    ['t_ayl_dngruin_i_ridgegrend_01'] = true,
    ['t_ayl_dngruin_i_ridgegrext_01'] = true,
    ['t_ayl_dngruin_i_ridgelend_01'] = true,
    ['t_ayl_dngruin_i_ridgelext_01'] = true,
    ['t_ayl_dngruin_i_roomceiling_01'] = true,
    ['t_ayl_dngruin_i_roomceiling_02'] = true,
    ['t_ayl_dngruin_i_roomceiling_03'] = true,
    ['t_ayl_dngruin_i_roomceiling_04'] = true,
    ['t_ayl_dngruin_i_roomcol_01'] = true,
    ['t_ayl_dngruin_i_roomcol_02'] = true,
    ['t_ayl_dngruin_i_roomcol_03'] = true,
    ['t_ayl_dngruin_i_roomcol_04'] = true,
    ['t_ayl_dngruin_i_roomcolbase_01'] = true,
    ['t_ayl_dngruin_i_roomcolbrk_01'] = true,
    ['t_ayl_dngruin_i_roomcolbrk_02'] = true,
    ['t_ayl_dngruin_i_roomcolbrk_03'] = true,
    ['t_ayl_dngruin_i_roomcolfloor_01'] = true,
    ['t_ayl_dngruin_i_roomcolsml_01'] = true,
    ['t_ayl_dngruin_i_roomcolsml_02'] = true,
    ['t_ayl_dngruin_i_roomcolsmlbrk_0'] = true,
    ['t_ayl_dngruin_i_roomcrn_01'] = true,
    ['t_ayl_dngruin_i_roomcrn2_01'] = true,
    ['t_ayl_dngruin_i_roomcrn3_01'] = true,
    ['t_ayl_dngruin_i_roomcrnc_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextb_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextl_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextlc_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextr_01'] = true,
    ['t_ayl_dngruin_i_roomcrnextrc_01'] = true,
    ['t_ayl_dngruin_i_roomcrno_01'] = true,
    ['t_ayl_dngruin_i_roomcrno_02'] = true,
    ['t_ayl_dngruin_i_roomcrnsecrb_01'] = true,
    ['t_ayl_dngruin_i_roomcrnsecrl_01'] = true,
    ['t_ayl_dngruin_i_roomcrnsecrr_01'] = true,
    ['t_ayl_dngruin_i_roomflr_01'] = true,
    ['t_ayl_dngruin_i_roomflredcrn_01'] = true,
    ['t_ayl_dngruin_i_roomflredstr_01'] = true,
    ['t_ayl_dngruin_i_roomwall_01'] = true,
    ['t_ayl_dngruin_i_roomwallext_01'] = true,
    ['t_ayl_dngruin_i_roomwallextw_01'] = true,
    ['t_ayl_dngruin_i_roomwallextw_02'] = true,
    ['t_ayl_dngruin_i_roomwallextw_03'] = true,
    ['t_ayl_dngruin_i_roomwallextw_04'] = true,
    ['t_ayl_dngruin_i_roomwallsecr_01'] = true,
    ['t_ayl_dngruin_i_roomwallshl_01'] = true,
    ['t_ayl_dngruin_i_rubble_01'] = true,
    ['t_ayl_dngruin_i_rubblepile_01'] = true,
    ['t_ayl_dngruin_i_rubblepile_02'] = true,
    ['t_ayl_dngruin_i_secrettohall_01'] = true,
    ['t_ayl_dngruin_i_secrtunnl_01'] = true,
    ['t_ayl_dngruin_i_secrtunnl3w_01'] = true,
    ['t_ayl_dngruin_i_secrtunnl4w_01'] = true,
    ['t_ayl_dngruin_i_secrtunnlcrn_01'] = true,
    ['t_ayl_dngruin_i_secrtunnlend_01'] = true,
    ['t_ayl_dngruin_i_secrtunnlrmp_01'] = true,
    ['t_ayl_dngruin_i_secrwall_01'] = true,
    ['t_ayl_dngruin_i_smlroom_cent_01'] = true,
    ['t_ayl_dngruin_i_smlroom_corn_01'] = true,
    ['t_ayl_dngruin_i_smlroom_corn_02'] = true,
    ['t_ayl_dngruin_i_smlroom_corn_03'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_01'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_02'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_03'] = true,
    ['t_ayl_dngruin_i_smlroom_entr_04'] = true,
    ['t_ayl_dngruin_i_smlroom_wall_01'] = true,
    ['t_ayl_dngruin_i_squarecolumn_01'] = true,
    ['t_ayl_dngruin_i_squarecolumn_02'] = true,
    ['t_ayl_dngruin_i_squarecolumn_03'] = true,
    ['t_ayl_dngruin_i_tower_capl_01'] = true,
    ['t_ayl_dngruin_i_tower_capr_01'] = true,
    ['t_ayl_dngruin_i_tower_ceil_01'] = true,
    ['t_ayl_dngruin_i_tower_ceilmd_01'] = true,
    ['t_ayl_dngruin_i_tower_ent_01'] = true,
    ['t_ayl_dngruin_i_tower_floor_01'] = true,
    ['t_ayl_dngruin_i_tower_flrmid_01'] = true,
    ['t_ayl_dngruin_i_tower_stairsl_0'] = true,
    ['t_ayl_dngruin_i_tower_stairsr_0'] = true,
    ['t_ayl_dngruin_i_tower_wall_01'] = true,
    ['t_ayl_dngruin_i_tower_wall_02'] = true,
    ['t_ayl_dngruin_i_tower_wall_03'] = true,
    ['t_ayl_dngruin_i_welkyndchndl_01'] = true,
    ['t_ayl_dngruin_i_welkyndclst_01'] = true,
    ['t_ayl_dngruin_i_welkyndclstg_01'] = true,
    ['t_ayl_dngruin_i_welkyndclstw_01'] = true,
    ['t_ayl_dngruin_i_welkyndholdr_01'] = true,
    ['t_ayl_dngruin_i_welkyndlump_01'] = true,
    ['t_ayl_dngruin_i_welkyndplnt_01'] = true,
    ['t_ayl_dngruin_i_welkyndplntw_01'] = true,
    ['t_ayl_dngruin_i_welkyndstn_01'] = true,
    ['t_ayl_dngruin_i_welkyndstn_02'] = true,
    ['t_ayl_dngruin_i_welkyndstn_03'] = true,
    ['t_ayl_dngruin_i_welkyndstnw_01'] = true,
    ['t_ayl_dngruin_i_welkyndstnw_02'] = true,
    ['t_ayl_dngruin_i_welkyndstnw_03'] = true,
    ['t_ayl_dngruin_i_wideh_01'] = true,
    ['t_ayl_dngruin_i_wideh3way_01'] = true,
    ['t_ayl_dngruin_i_wideh3wayse_01'] = true,
    ['t_ayl_dngruin_i_wideh3wayse_02'] = true,
    ['t_ayl_dngruin_i_wideh4crn_01'] = true,
    ['t_ayl_dngruin_i_wideh4way_01'] = true,
    ['t_ayl_dngruin_i_widehbr_01'] = true,
    ['t_ayl_dngruin_i_widehcat_01'] = true,
    ['t_ayl_dngruin_i_widehcrnse_01'] = true,
    ['t_ayl_dngruin_i_widehend_01'] = true,
    ['t_ayl_dngruin_i_widehgatef_01'] = true,
    ['t_ayl_dngruin_i_widehsecret_01'] = true,
    ['t_ayl_dngruin_i_widehstair_01'] = true,
    ['t_ayl_dngruin_i_widehstairbr_01'] = true,
    ['t_ayl_dngruin_i_widehtrans_01'] = true,
    ['t_ayl_dngruin_i_wideh_trans3_01'] = true,
    ['t_ayl_dngruin_i_wideh_trans4_01'] = true,
    ['t_ayl_dngruin_i_wideh_trans4_02'] = true,
    ['t_ayl_dngruin_i_windowleft_01'] = true,
    ['t_ayl_dngruin_i_windowmiddle_01'] = true,
    ['t_ayl_dngruin_i_windowright_01'] = true,
    ['t_ayl_dngruin_i_windowsectnl_01'] = true,
    ['t_ayl_dngruin_i_windowsectnl_02'] = true,
}

---@type IDPresenceMap
local BarrowsStatics = {
    ['t_imp_dngcolbarrow_i_block_01'] = true,
    ['t_imp_dngcolbarrow_i_block_02'] = true,
    ['t_imp_dngcolbarrow_i_ceil_01'] = true,
    ['t_imp_dngcolbarrow_i_ceil_02'] = true,
    ['t_imp_dngcolbarrow_i_ceil_03'] = true,
    ['t_imp_dngcolbarrow_i_ceil_04'] = true,
    ['t_imp_dngcolbarrow_i_ceil_05'] = true,
    ['t_imp_dngcolbarrow_i_ceil_06'] = true,
    ['t_imp_dngcolbarrow_i_column_01'] = true,
    ['t_imp_dngcolbarrow_i_column_02'] = true,
    ['t_imp_dngcolbarrow_i_column_03'] = true,
    ['t_imp_dngcolbarrow_i_column_04'] = true,
    ['t_imp_dngcolbarrow_i_column_05'] = true,
    ['t_imp_dngcolbarrow_i_column_06'] = true,
    ['t_imp_dngcolbarrow_i_corner_01'] = true,
    ['t_imp_dngcolbarrow_i_corner_02'] = true,
    ['t_imp_dngcolbarrow_i_corner_03'] = true,
    ['t_imp_dngcolbarrow_i_cover_01'] = true,
    ['t_imp_dngcolbarrow_i_dirt_01'] = true,
    ['t_imp_dngcolbarrow_i_dirt_02'] = true,
    ['t_imp_dngcolbarrow_i_dirt_03'] = true,
    ['t_imp_dngcolbarrow_i_dirt_04'] = true,
    ['t_imp_dngcolbarrow_i_exit_01'] = true,
    ['t_imp_dngcolbarrow_i_floor_01'] = true,
    ['t_imp_dngcolbarrow_i_floor_02'] = true,
    ['t_imp_dngcolbarrow_i_floor_03'] = true,
    ['t_imp_dngcolbarrow_i_floor_04'] = true,
    ['t_imp_dngcolbarrow_i_inscr_01'] = true,
    ['t_imp_dngcolbarrow_i_inscr_02'] = true,
    ['t_imp_dngcolbarrow_i_passge_01'] = true,
    ['t_imp_dngcolbarrow_i_passge_02'] = true,
    ['t_imp_dngcolbarrow_i_passge_03'] = true,
    ['t_imp_dngcolbarrow_i_passge_04'] = true,
    ['t_imp_dngcolbarrow_i_passtairs'] = true,
    ['t_imp_dngcolbarrow_i_pillar_01'] = true,
    ['t_imp_dngcolbarrow_i_pillar_02'] = true,
    ['t_imp_dngcolbarrow_i_rubble_01'] = true,
    ['t_imp_dngcolbarrow_i_stair_01'] = true,
    ['t_imp_dngcolbarrow_i_wall_01'] = true,
    ['t_imp_dngcolbarrow_i_wall_02'] = true,
    ['t_imp_dngcolbarrow_i_wall_03'] = true,
    ['t_imp_dngcolbarrow_i_wall_04'] = true,
    ['t_imp_dngcolbarrow_i_wall_05'] = true,
    ['t_imp_dngcolbarrow_i_wall_06'] = true,
    ['t_imp_dngcolbarrow_i_wall_07'] = true,
    ['t_imp_dngcolbarrow_i_wall_08'] = true,
    ['t_imp_dngcolbarrow_i_wall_09'] = true,
    ['t_imp_dngcolbarrow_i_wall_10'] = true,
    ['t_imp_dngcolbarrow_i_wall_11'] = true,
}

---@type CellMatchPatterns
local CavePatterns = {
    allowed = {
        "agi bay grotto",
        "akna mine",
        "ansedeus",
        "aschar",
        "atrene",
        "axilas grotto",
        "blackfish cave",
        "broken shrine grotto",
        "buralca",
        "crow hall cave",
        "einluk mine",
        "emperor cassynder: grotto",
        "eran grotto",
        "fort heath, mine",
        "gula cave",
        "ikan grotto",
        "joranta",
        "kingfisher cave",
        "land\'s end grotto",
        "lazur grotto",
        "lost stars hollow",
        "melestrata",
        "mirta grotto",
        "mormolycea",
        "nabor",
        "norinia",
        "ogima",
        "pale bay cave",
        "salvage mine",
        "sorhuk",
        "stonehead cave",
        "thalur grotto",
        "thesigir chasm",
        "vallanytha grotto",
        "vilenkin",
    },

    disallowed = {},
}

---@type IDPresenceMap
local CryptStatics = {
    ['t_imp_dngcrypt_i_center_01'] = true,
    ['t_imp_dngcrypt_i_column_01'] = true,
    ['t_imp_dngcrypt_i_column_02'] = true,
    ['t_imp_dngcrypt_i_corner_01'] = true,
    ['t_imp_dngcrypt_i_doorjam_01'] = true,
    ['t_imp_dngcrypt_i_end_01'] = true,
    ['t_imp_dngcrypt_i_floor_01'] = true,
    ['t_imp_dngcrypt_i_hall_01'] = true,
    ['t_imp_dngcrypt_i_r_ceiling_01'] = true,
    ['t_imp_dngcrypt_i_r_center_01'] = true,
    ['t_imp_dngcrypt_i_r_corner_01'] = true,
    ['t_imp_dngcrypt_i_r_corner_02'] = true,
    ['t_imp_dngcrypt_i_r_side_01'] = true,
    ['t_imp_dngcrypt_i_side_01'] = true,
    ['t_imp_dngcrypt_i_stairs_01'] = true,
    ['t_imp_dngcrypt_i_wall_01'] = true,
    ['t_imp_dngcrypt_i_wall_02'] = true,
    ['t_imp_dngcrypt_i_wall_03'] = true,
    ['t_imp_dngcrypt_i_wall_04'] = true,
}

---@type IDPresenceMap
local StirkRegions = {
    ['stirk isle region'] = true,
    ['dasek marsh region'] = true,
}

local SutchPatterns = {
    allowed = {
        "sutch",
        "thyra",
        "isvorhal",
        "seppaki",
        "salthearth"
    },

    disallowed = {
        'sewer',
        'underworks',
        'crypt',
    }
}

---@type CellMatchPatterns
local TemplePatterns = {
    allowed = {
        "anvil, chapel",
        "anvil, temple",
        "brina cross, chapel",
        "charach, chapel",
        "fort heath, chapel",
        "goldstone, chapel",
        "thresvy, chapel"
    },

    disallowed = {},
}

---@type IDPresenceMap
local CyrContentFiles = {
    ['cyr_main.esm'] = true,
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'Project Cyrodiil - Abecean Shores/Imperial Crypts',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 1 (19).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 2 (73).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 3 (76).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 4 (80).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 5 (93).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 6 (94).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 7 (95).mp3',
            'music/MS/interior/Cyrodiil Tombs Imperial/imperial crypt - 8 (96).mp3',
        },

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(CryptStatics)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Brennan Bluffs',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'music/MS/region/Cyrodiil Brennan Bluffs/abecean - 1 (40).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 1 (41).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 2 (33).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 3 (43).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 4 (66).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 5 (69).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 6 (71).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 7 (102).mp3',
            'music/MS/region/Cyrodiil Brennan Bluffs/gilded hills - 8 (104).mp3',
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'gilded hills region'
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Divine Temples',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'music/MS/cell/Nine Divine Temples/divines temple - 1 (4).mp3',
            'music/MS/cell/Nine Divine Temples/divines temple - 2 (22).mp3',
            'music/MS/cell/Nine Divine Temples/divines temple - 3 (31).mp3',
            'music/MS/cell/Nine Divine Temples/divines temple - 4 (39).mp3',
            'music/MS/cell/Nine Divine Temples/divines temple - 5 (50).mp3',
        },

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior and playback.rules.cellNameMatch(TemplePatterns)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Colovian Barrows',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 1 (48).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 2 (57).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 3 (87).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 4 (88).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 5 (89).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 6 (90).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 7 (91).mp3',
            'music/MS/interior/Cyrodiil Tombs Colovian/colovian barrow - 8 (92).mp3',
        },

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(BarrowsStatics)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Caves',
        priority = PlaylistPriority.CellMatch - 1,
        randomize = true,

        tracks = {
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 1 (35).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 2 (47).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 3 (63).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 4 (64).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 5 (97).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 6 (98).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 7 (99).mp3',
            'music/MS/interior/Cyrodiil Caves/cyrod caves - 8 (100).mp3',
        },

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior and playback.rules.cellNameMatch(CavePatterns)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Ayleid',
        priority = PlaylistPriority.Tileset,
        randomize = true,

        tracks = {
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 1 (52).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 2 (58).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 3 (59).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 4 (77).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 5 (84).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 6 (85).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 7 (109).mp3',
            'music/MS/interior/Cyrodiil Ayleid/ayleid - 8 (110).mp3',
        },

        isValidCallback = function(playback)
            return not playback.state.cellIsExterior
                and playback.rules.staticContentFile(CyrContentFiles)
                and playback.rules.staticExact(AyleidStatics)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Kingdom of Sutch',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'music/MS/cell/Cyrodiil Sutch/sutch - 1 (78).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 2 (79).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 3 (81).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 4 (82).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 5 (83).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 6 (103).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 7 (105).mp3',
            'music/MS/cell/Cyrodiil Sutch/sutch - 8 (106).mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(SutchPatterns)
        end
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Kingdom of Anvil',
        priority = PlaylistPriority.CellMatch,
        randomize = true,

        tracks = {
            'music/MS/cell/Cyrodiil Anvil/anvil - 1 (2).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 2 (44).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 3 (45).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 4 (53).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 5 (61).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 6 (72).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 7 (86).mp3',
            'music/MS/cell/Cyrodiil Anvil/anvil - 8 (101).mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.cellNameMatch(AnvilPatterns)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Strident Coast',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'music/MS/region/Cyrodiil Strident Coast/abecean - 1 (40).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 2 (42).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 3 (46).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 4 (49).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 5 (62).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 6 (9).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 7 (51).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 8 (56).mp3',
            'music/MS/region/Cyrodiil Strident Coast/gold coast - 9 (65).mp3',
        },

        isValidCallback = function(playback)
            return playback.state.self.cell.region == 'gold coast region'
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Stirk Isle',
        priority = PlaylistPriority.Region,
        randomize = true,

        tracks = {
            'music/MS/region/Cyrodiil Strident Coast/abecean - 1 (40).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 1 (34).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 2 (36).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 3 (37).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 4 (38).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 5 (74).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 6 (75).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 7 (107).mp3',
            'music/MS/region/Cyrodiil Stirk Isle/stirk - 8 (108).mp3',
        },

        isValidCallback = function(playback)
            return playback.rules.region(StirkRegions)
        end,
    }
}
