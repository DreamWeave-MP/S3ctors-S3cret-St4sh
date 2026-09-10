---@module 'doc.playlistEnv'

---@type CellMatchPatterns
local AnvilPatterns = {
  allowed = {
    'anvil',
    'marav',
    'hal sadek',
    'archad',
    'brina cross',
    'goldstone',
    'charach',
  },

  disallowed = {
    'sewer',
    'underworks',
    'crypt',
  },
}

---@type IDPresenceMap
local StirkRegions = {
  ['stirk isle region'] = true,
  ['abecean sea region'] = true,
}

local goldCoastRegions = {
  ['dasek marsh region'] = true,
  ['gold coast region'] = true,
}

---@type CellMatchPatterns
local SutchPatterns = {
  allowed = {
    'sutch',
    'thyra',
    'isvorhal',
    'seppaki',
    'salthearth',
  },

  disallowed = {
    'sewer',
    'underworks',
    'crypt',
  },
}

---@type CellMatchPatterns
local TemplePatterns = {
  allowed = {
    'anvil, chapel',
    'anvil, temple',
    'brina cross, chapel',
    'charach, chapel',
    'fort heath, chapel',
    'goldstone, chapel',
    'thresvy, chapel',
  },

  disallowed = {},
}

---@type IDPresenceMap
local CyrContentFiles = {
  ['cyr_main.esm'] = true,
}

---@type S3maphorePlaylist[]
return {
  {
    -- 'Project Cyrodiil - Abecean Shores/Imperial Crypts',
    id = 'ms/interior/cyrodiil tombs imperial',
    priority = PlaylistPriority.Tileset,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/interior/cyrodiil tombs imperial/silence %(10s%).mp3',
        'ms/interior/cyrodiil tombs imperial/silence %(15s%).mp3',
        'ms/interior/cyrodiil tombs imperial/silence %(5s%).mp3',
      },
    },

    isValidCallback = function()
      return not Playback.state.cellIsExterior
        and Playback.rules.staticContentFile(CyrContentFiles)
        and Playback.rules.objectExact(Tilesets.Crypt)
    end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Brennan Bluffs',
    id = 'ms/region/cyrodiil brennan bluffs',
    priority = PlaylistPriority.Region,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/region/cyrodiil brennan bluffs/silence %(10s%).mp3',
        'ms/region/cyrodiil brennan bluffs/silence %(15s%).mp3',
        'ms/region/cyrodiil brennan bluffs/silence %(5s%).mp3',
      },
    },

    isValidCallback = function() return Playback.state.nearestRegion == 'gilded hills region' end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Colovian Barrows',
    id = 'ms/interior/cyrodiil tombs colovian',
    priority = PlaylistPriority.Tileset,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/interior/cyrodiil tombs colovian/silence %(10s%).mp3',
        'ms/interior/cyrodiil tombs colovian/silence %(15s%).mp3',
        'ms/interior/cyrodiil tombs colovian/silence %(5s%).mp3',
      },
    },

    isValidCallback = function()
      return not Playback.state.cellIsExterior
        and Playback.rules.staticContentFile(CyrContentFiles)
        and Playback.rules.objectExact(Tilesets.Barrows)
    end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Caves',
    id = 'ms/interior/cyrodiil caves',
    priority = PlaylistPriority.Tileset,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/interior/cyrodiil caves/silence %(10s%).mp3',
        'ms/interior/cyrodiil caves/silence %(15s%).mp3',
        'ms/interior/cyrodiil caves/silence %(5s%).mp3',
      },
    },

    isValidCallback = function()
      return not Playback.state.cellIsExterior
        and Playback.rules.staticContentFile(CyrContentFiles)
        and Playback.rules.objectExact(Tilesets.Cave)
    end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Ayleid',
    id = 'ms/interior/cyrodiil ayleid',
    priority = PlaylistPriority.Tileset,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/interior/cyrodiil ayleid/silence %(10s%).mp3',
        'ms/interior/cyrodiil ayleid/silence %(15s%).mp3',
        'ms/interior/cyrodiil ayleid/silence %(5s%).mp3',
      },
    },

    isValidCallback = function()
      return not Playback.state.cellIsExterior
        and Playback.rules.staticContentFile(CyrContentFiles)
        and Playback.rules.objectExact(Tilesets.Ayleid)
    end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Divine Temples',
    id = 'ms/cell/nine divine temples',
    priority = PlaylistPriority.CellMatch,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/cell/nine divine temples/silence %(10s%).mp3',
        'ms/cell/nine divine temples/silence %(15s%).mp3',
        'ms/cell/nine divine temples/silence %(5s%).mp3',
      },
    },

    isValidCallback = function()
      return not Playback.state.cellIsExterior and Playback.rules.cellNameMatch(TemplePatterns)
    end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Kingdom of Sutch',
    id = 'ms/cell/cyrodiil sutch',
    priority = PlaylistPriority.CellMatch,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/cell/cyrodiil sutch/silence %(10s%).mp3',
        'ms/cell/cyrodiil sutch/silence %(15s%).mp3',
        'ms/cell/cyrodiil sutch/silence %(5s%).mp3',
      },
    },

    isValidCallback = function() return Playback.rules.cellNameMatch(SutchPatterns) end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Kingdom of Anvil',
    id = 'ms/cell/cyrodiil anvil',
    priority = PlaylistPriority.CellMatch,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/cell/cyrodiil anvil/silence %(10s%).mp3',
        'ms/cell/cyrodiil anvil/silence %(15s%).mp3',
        'ms/cell/cyrodiil anvil/silence %(5s%).mp3',
      },
    },

    isValidCallback = function() return Playback.rules.cellNameMatch(AnvilPatterns) end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Strident Coast',
    id = 'ms/region/cyrodiil strident coast',
    priority = PlaylistPriority.Region,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/region/cyrodiil strident coast/silence %(10s%).mp3',
        'ms/region/cyrodiil strident coast/silence %(15s%).mp3',
        'ms/region/cyrodiil strident coast/silence %(5s%).mp3',
      },
    },

    isValidCallback = function() return Playback.rules.region(goldCoastRegions) end,
  },
  {
    -- 'Project Cyrodiil - Abecean Shores/Stirk Isle',
    id = 'ms/region/cyrodiil stirk isle',
    priority = PlaylistPriority.Region,
    randomize = true,
    exclusions = {
      tracks = {
        'ms/region/cyrodiil stirk isle/silence %(10s%).mp3',
        'ms/region/cyrodiil stirk isle/silence %(15s%).mp3',
        'ms/region/cyrodiil stirk isle/silence %(5s%).mp3',
      },
    },

    isValidCallback = function() return Playback.rules.region(StirkRegions) end,
  },
}
