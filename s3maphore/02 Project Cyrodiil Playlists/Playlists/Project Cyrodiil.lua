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
---@type CellMatchPatterns
local AyleidPatterns = {
    allowed = {
        "beldaburo",
        "garlas malatar",
        "garlas agea",
        "gulaida",
        "lindasael",
        "nagaiarelle",
        "nefa",
        "salinen",
        "vabriasel",
        "valsar",
        "wormusoel",
    },

    disallowed = {},
}

---@type CellMatchPatterns
local BarrowsPatterns = {
    allowed = {
        "beccha barrow",
        "chaerraich barrow",
        "darach barrow",
        "fortyd barrow",
        "harkisius barrow",
        "jaskav barrow",
        "kar toronr barrow",
        "karskaer barrow",
        "kicsiver barrow",
        "meginhard barrow",
        "miskar barrow",
        "rilsyl barrow",
        "val ansvech barrow",
        "vinka barrow",
        "vitta barrow",
    },

    disallowed = {},
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

local ImpCryptPatterns = {
    allowed = {
        "brina cross, crypts",
        "conomorus crypt",
        "hadrach crypt",
        "ivrol crypt",
        "lacorius crypt",
        "benirus crypt",
        "pelelius crypt",
        "siralius crypt",
        "talgiana crypt",
        "telvor crypt",
        "thimistrel crypt",
        "carthalo",
        "eumaeus",
        "mischarstette",
        "old thraswatch",
        "olomachus",
        "strand",
    },

    disallowed = {},
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

---@type S3maphorePlaylist[]
return {
    {
        id = 'Project Cyrodiil - Abecean Shores/Imperial Crypts',
        priority = 924,
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
            return not playback.state.cellIsExterior and playback.rules.cellNameMatch(ImpCryptPatterns)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Brennan Bluffs',
        priority = 923,
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
        priority = 922,
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
        priority = 921,
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
            return not playback.state.cellIsExterior and playback.rules.cellNameMatch(BarrowsPatterns)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Caves',
        priority = 920,
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
        priority = 919,
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
            return not playback.state.cellIsExterior and playback.rules.cellNameMatch(AyleidPatterns)
        end,
    },
    {
        id = 'Project Cyrodiil - Abecean Shores/Kingdom of Sutch',
        priority = 918,
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
        priority = 917,
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
        priority = 916,
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
        priority = 915,
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
