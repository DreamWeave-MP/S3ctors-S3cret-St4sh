---@omw-context player

---@type CellMatchPatterns
local NordTownPatterns = {
  allowed = {
    --Vanilla--
    'dagon fel',
    'skaal village',
    --SHOTN--
    'karthwasten',
    'dragonstar',
    'karthgad',
    'markarth',
    'merduibh',
    'bailcnoss',
    'haimtir',
    'mairager',
    'criaglorc',
  },

  disallowed = {},
}

---@type IDPresenceMap
local NLSkyrimRegionNames = {
  ['skyrim'] = true,
  ['druadach highlands region'] = true,
  ['falkheim region'] = true,
  ['kilkreath mountains region'] = true,
  ['lorchwuir heath region'] = true,
  ['midkarth region'] = true,
  ['valstaag highlands region'] = true,
  ['vorndgad forest region'] = true,
  ['solitude forest region'] = true,
  ['sundered hills region'] = true,
}

---@type IDPresenceMap
local NLSolstheimRegionNames = {
  ['solstheim'] = true,
  ['felsaad coast region'] = true,
  ['hirstaang forest region'] = true,
  ['isinfier plains region'] = true,
  ['moesring mountains region'] = true,
  ['thirsk region'] = true,
}

---@type S3maphorePlaylist[]
return {
  {
    id = 'Nordic Lands - Towns',
    priority = PlaylistPriority.CellMatch - 1,
    randomize = true,

    tracks = {
      'music/ms/cell/nordtown/secity2.mp3',
      'music/ms/cell/nordtown/secity4.mp3',
    },

    isValidCallback = function()
      return not Playback.state.isInCombat and Playback.rules.cellNameMatch(NordTownPatterns)
    end,
  },
  {
    id = 'Nordic Lands - Skyrim Regions',
    priority = PlaylistPriority.Region - 1,
    randomize = true,

    tracks = {
      'music/ms/region/nd1_njol.mp3',
      'music/ms/region/nd2_utanlands.mp3',
      'music/ms/region/nd3_draumr.mp3',
      'music/ms/region/nd4_jata.mp3',
      'music/ms/region/nd5_ginnung01.mp3',
      'music/ms/region/nd6_ginnung02.mp3',
      'music/ms/region/nd7_jafnan.mp3',
      'music/ms/region/nd9_ek_elska_thik.mp3',
      'music/ms/region/nd10_himinbjörg.mp3',
    },

    isValidCallback = function()
      return not Playback.state.isInCombat and Playback.rules.region(NLSkyrimRegionNames)
    end,
  },
  {
    id = 'Nordic Lands - Solstheim Regions',
    priority = PlaylistPriority.Region - 1,
    randomize = true,

    tracks = {
      'music/ms/region/nd1_njol.mp3',
      'music/ms/region/nd2_utanlands.mp3',
      'music/ms/region/nd3_draumr.mp3',
      'music/ms/region/nd4_jata.mp3',
      'music/ms/region/nd5_ginnung01.mp3',
      'music/ms/region/nd6_ginnung02.mp3',
      'music/ms/region/nd7_jafnan.mp3',
      'music/ms/region/nd9_ek_elska_thik.mp3',
      'music/ms/region/nd10_himinbjörg.mp3',
    },

    isValidCallback = function()
      return not Playback.state.isInCombat and Playback.rules.region(NLSolstheimRegionNames)
    end,
  },
}
