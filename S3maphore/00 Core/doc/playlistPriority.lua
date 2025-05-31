---@meta

--- Playlist Priority Guide
---
--- Lower numbers mean higher priority, and will potentially override earlier ones in the list.
--- Playlists with equivalent priority will be used according to the order in which they were registered, which occurs in the alphabetical order of the contents of the VFS directory playlists/ and then according to the exact sequence in each playlist file.
--- Please do NOT actually `require` this file and use the values in your playlists. It is simply meant to be a guide to known playlist priorities.
--- Please *do* feel free to let me know if I should add your playlists to this doc file :)
---
--- Some general suggestions for setting priority:
--- 1. Priority numbers should generally go from less to more specific. A playlist with 1 region should have a lower priority number than one with 10.
--- Builtin modules populate around the edges to give space for everyone in the middle.
--- 2. Where possible, slot vanilla playlists above DLC or other modded regional/etc playlists in the priority chain
--- 3. Remember to take advantage of the rules set forth by other playlists. Your position in the chain also implies what conditions have already been checked - for example, priority numbers below 200 can generally assume the player is in combat already.

---@class PlaylistPriority
--- Battle music. Below this tier, the player can generally be assumed to be in combat.
---@field Battle integer
--- Exploration music, default for most situations. The exploration playlist's priority should generally be considered the upper limit of playlist priorities.
---@field Explore integer
--- City music
---@field City integer
--- Fuzzy-matched cells
---@field CellMatch integer
--- Faction-based rules such as great houses or guilds
---@field Factional integer
--- Rules based on time of day
---@field TimeOfDay integer
--- Exact cell names
---@field CellExact integer
--- Rules based on static sets/names
---@field Tileset integer
--- Regional music
---@field Region integer
--- Special event or reserved slots, for unique scripted elements.
---@field Special integer

local PlaylistPriority = {
    Explore = 1000,
    -- Reserve the upper 50 slots, so TR doesn't get all the first dibs - We need vanilla playlists, too!
    -- Regional
    Region = 950,
    ['Songbook of the North - Regions'] = 950,          -- 9 Regions
    ['Tamriel Rebuilt - Telvannis Regions'] = 949,      -- 5 Regions
    ['Tamriel Rebuilt - Aanthirin'] = 948,              -- 3 Regions
    ['Tamriel Rebuilt - Lan Orethan'] = 947,            -- 3 Regions
    ['Tamriel Rebuilt - Mournhold'] = 946,              -- 3 Regions
    ['Tamriel Rebuilt - Upper Velothis Regions'] = 945, -- 2 Regions
    ['Tamriel Rebilt - Seas'] = 944,                    -- 2 Regions
    ['Vindsvept Solstheim - Felsaad Coast'] = 943,      -- 2 Regions
    ['Tamriel Rebuilt - Armun Ashlands'] = 942,         -- 1 Region
    ['Tamriel Rebuilt - Sacred Lands'] = 941,           -- 1 Region
    ['Tamriel Rebuilt - Sundered Scar'] = 940,          -- 1 Region
    ['Vindsvept Solstheim - Moesring'] = 939,           -- 1 Region
    ['Vindsvept Solstheim - Histaang'] = 938,           -- 1 Region
    ['Vindsvept Solstheim - Isinfier Plains'] = 937,    -- 1 Region
    -- City
    City = 800,
    ['Songbook of the North - Cities'] = 800,        -- 21 allowed, 2 disallowed
    ['Tamriel Rebuilt - Telvanni Settlement'] = 799, -- 11 allowed, 2 disallowed
    ['Tamriel Rebuilt - Indoril Settlement'] = 798,  -- 10 allowed, 2 disallowed
    ['Vindsvept Solstheim - Town'] = 797,            -- 4 Allowed, 0 disallowed
    -- Cell matches
    CellMatch = 700,
    ['MUSE - Tomb Cells'] = 700,                          -- 5 allowed, 0 disallowed
    ['Tamriel Rebuilt - Imperial'] = 699,                 -- 2 allowed, 3 disallowed
    ['Tamriel Rebuilt - Dwemer Ruins'] = 698,             -- 2 Allowed matches, 2 disallowed
    ['Tamriel Rebuilt - Port Telvannis'] = 697,           -- 1 Allowed, 0 disallowed
    ['Vindsvept Solstheim - Lake'] = 696,                 -- 1 Allowed, 0 disallowed
    ['MOMW Patches - Secrets of the Crystal City'] = 695, -- 1 Allowed, 0 disallowed
    -- Tileset-based
    Tileset = 600,
    ['MUSE - Daedric Ruins'] = 600, -- 431 exact statics
    ['MUSE - Dwemer Ruins'] = 599,  -- 350 exact statics
    -- Exact cells
    CellExact = 500,
    -- Begin Starwind playlists
    ['Sounds of Starwind - Undercity'] = 500,           -- 67 Cells
    ['Sounds of Starwind - Tatooine Settlement'] = 499, -- 54 Cells
    ['Sounds of Starwind - Manaan'] = 498,              -- 51 Cells
    ['Sounds of Starwind - Dantooine'] = 497,           -- 49 Cells
    ['Sounds of Starwind - Taris'] = 496,               -- 46 Cells
    ['Sounds of Starwind - Kashyyk'] = 495,             -- 46 Cells
    ['Sounds of Starwind - Korriban'] = 494,            -- 10 Cells
    ['Sounds of Starwind - Cantina'] = 493,             -- 10 Cells
    ['Sounds of Starwind - Taris Ruined Plaza'] = 492,  -- 6 Cells
    ['Sounds of Starwind - Tatooine Desert'] = 491,     -- 6 Cells
    -- NOTE: Playlists can omit track listings and simply name themselves after the music/ subdirectory in which their tracks are located!
    ['Rickoff/The Outer Rim'] = 490,                    -- 2 Cells
    ['Rickoff/Club Arkngthand'] = 489,                  -- 1 Cell
    ['Sounds of Starwind - Nar Shaddaa Market'] = 488,  -- 1 Cell
    -- End Starwind playlists
    -- Factional
    Factional = 400,
    ['MUSE - Sixth House Dungeons'] = 400, -- 61 exact cell names
    ['MUSE - Empire Settlement'] = 399,    -- 13 Allowed, 4 disallowed
    ['MUSE - Hlaalu Settlement'] = 398,    -- 11 allowed, 0 disallowed
    ['MUSE - Redoran Settlement'] = 397,   -- 5 allowed, 0 disallowed
    ['MUSE - Ashlander Settlement'] = 396, -- 4 Allowed, 0 disallowed
    -- Times of day
    TimeOfDay = 300,
    -- Combat Playlists
    Battle = 200,
    ['MUSE - Ashlander Enemies'] = 199,   -- 118 exact combat targets
    ['MUSE - Sixth House Enemies'] = 198, -- 48 exact combat targets
    ['MUSE - Tomb Enemies'] = 197,        -- 33 Exact combat targets
    ['MUSE - Empire Enemies'] = 196,      -- 28 Exact combat targets
    ['MUSE - Daedric Enemies'] = 195,     -- 23 Exact combat targets
    ['MUSE - Hlaalu Enemies'] = 194,      -- 14 combat targets
    ['MUSE - Dwemer Enemies'] = 193,      -- 12 exact combat targets
    ['MUSE - Redoran Enemies'] = 192,     -- 8 exact combat targets
    Special = 50,
    -- Intro playlist will override any and all combat musics
    ['Sounds of Starwind - Endar Spire'] = 50, -- 1 Cell
    -- Super important narratively, override any combat states
    ['MUSE - Cavern of the Incarnate'] = 50,   -- 1 Cell
}

return PlaylistPriority
