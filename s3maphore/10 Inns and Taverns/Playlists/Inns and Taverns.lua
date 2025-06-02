---@type IDPresenceMap
local TavernNamesVanilla = {
    ['ald skar inn'] = true,
    ['gateway inn'] = true,
    ['tradehouse'] = true,
    ['the rat in the pot'] = true,
    ['eight plates'] = true,
    ['lucky lockup'] = true,
    ['shenk\'s shovel'] = true,
    ['end of the world'] = true,
    ['six fishes'] = true,
    ['tower of dusk lower level'] = true,
    ['the pilgrim\'s rest'] = true,
    ['fara\'s hole in the wall'] = true,
    ['desele\'s house of earthly delights'] = true,
    ['plot and plaster'] = true,
    ['the covenant'] = true,
    ['no name club'] = true,
    ['the flowers of gold'] = true,
    ['the lizard\'s head'] = true,
    ['the winged guar'] = true,
    ['solstheim, thirsk'] = true,
    ['raven rock, bar'] = true,
}

---@type CellMatchPatterns
local VanillaTavernMatches = {
    allowed = {
        'tradehouse',
        'cornerclub',
        'tavern',
        'council club',
    },

    disallowed = {},
}

---@type IDPresenceMap
local TRTavernCells = {
    ['hunted hound inn'] = true,
    ['the inn between'] = true,
    ['the sailor\'s inn'] = true,
    ['the starlight inn'] = true,
    ['the emerald haven inn'] = true,
    ['hound\'s rest inn'] = true,
    ['the grey lodge'] = true,
    ['the laughing goblin'] = true,
    ['underground bazaar'] = true,
    ['hostel of the crossing'] = true,
    ['limping scrib'] = true,
    ['the pious pirate'] = true,
    ['the dancing cup'] = true,
    ['golden moons club'] = true,
    ['the guar with no name'] = true,
    ['lucky shalaasa\'s caravanserai'] = true,
    ['the nest'] = true,
    ['the gentle velk'] = true,
    ['the howling noose'] = true,
    ['the queen\'s cutlass'] = true,
    ['silver serpent'] = true,
    ['unnamed legion bar'] = true,
    ['mjornir\'s meadhouse'] = true,
    ['the red drake'] = true,
    ['the leaking spore'] = true,
    ['the swallow\'s nest'] = true,
    ['the golden glade'] = true,
    ['pilgrim\'s respite'] = true,
    ['the empress katariah'] = true,
    ['legion boarding house'] = true,
    ['the moth and tiger'] = true,
    ['the salty futtocks'] = true,
    ['the avenue'] = true,
    ['the dancing jug'] = true,
    ['the strider\'s wake'] = true,
    ['the toiling guar'] = true,
    ['the cliff racer\'s rest'] = true,
    ['the glass goblet'] = true,
    ['the note in your eye'] = true,
    ['the magic mudcrab'] = true,
    ['twisted root'] = true,
    ['the howling hound'] = true,
    --shotn--
    ['the dancing saber'] = true,
    ['ruby drake inn'] = true,
    ['the droopy mare'] = true,
    ['dragon fountain inn'] = true,
    --cyrodiil--
    ['plaza taverna'] = true,
    ['sunset hotel'] = true,
    ['old seawater inn'] = true,
    ['the anchor\'s rest'] = true,
    ['all flags inn'] = true,
    ['caravan stop'] = true,
    ['saint amiel officers\' club'] = true,
    ['the abecette'] = true,
    ['crossing inn'] = true,
    ['spearmouth inn'] = true,
    ['the blind watchtower'] = true,
}

---@type CellMatchPatterns
local TRTavernMatches = {
    allowed = {
        'hostel',
        'alehouse',
    },

    disallowed = {},
}

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        -- 'Inns and Taverns - Vanilla',
        id = 'music/ms/cell/tavern',
        -- Uses faction priority to override TR playlists
        priority = PlaylistPriority.Faction - 1,
        randomize = true,

        isValidCallback = function(playback)
            return not playback.state.isInCombat
                and not playback.state.cellIsExterior
                and (
                    (
                        playback.rules.cellNameExact(TavernNamesVanilla) or playback.rules.cellNameExact(TRTavernCells)
                    )
                    or
                    (
                        playback.rules.cellNameMatch(TRTavernMatches) or playback.rules.cellNameMatch(VanillaTavernMatches)
                    )
                )
        end,
    }
}
