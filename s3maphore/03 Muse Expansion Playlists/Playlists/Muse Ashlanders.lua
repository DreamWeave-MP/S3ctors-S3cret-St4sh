---@type CellMatchPatterns
local AshlanderCellNames = {
    allowed = {
        'ahemmusa camp',
        'erabenimsun camp',
        'urshilaku camp',
        'zainab camp',
    },

    disallowed = {},
}

---@type ValidPlaylistCallback
local function ashlanderCellRule(playback)
    return playback.rules.cellNameMatch(AshlanderCellNames)
end

---@type IDPresenceMap
local MuseAshlanderEnemyNames = {
    ['assantus hansar'] = true,
    ['tunipy shamirbasour'] = true,
    ['emul-ran'] = true,
    ['kashtes ilabael'] = true,
    ['sakin sanammasour'] = true,
    ['esar-don dunsamsi'] = true,
    ['hairan mannanalit'] = true,
    ['assallit assunbahanammu'] = true,
    ['tubilalk mirathrernenum'] = true,
    ['yan-ahhe darirnaddunumm'] = true,
    ['kammu'] = true,
    ['sen'] = true,
    ['urshamusa rapli'] = true,
    ['zallit'] = true,
    ['addammus'] = true,
    ['ulabael'] = true,
    ['assamma-idan'] = true,
    ['dutadalk'] = true,
    ['yenammu'] = true,
    ['kausi'] = true,
    ['lanabi'] = true,
    ['mabarrabael'] = true,
    ['mamaea'] = true,
    ['mausur'] = true,
    ['nummu'] = true,
    ['sinnammu mirpal'] = true,
    ['assaba-bentus'] = true,
    ['hairan'] = true,
    ['hirarend'] = true,
    ['kummu'] = true,
    ['kushishi'] = true,
    ['tinti'] = true,
    ['addut-lamanu'] = true,
    ['ainab'] = true,
    ['ahaz'] = true,
    ['ulath-pal'] = true,
    ['ashu-ahhe'] = true,
    ['assemmus'] = true,
    ['zebba'] = true,
    ['han-ammu'] = true,
    ['yantus'] = true,
    ['massarapal'] = true,
    ['ulibabi'] = true,
    ['ranabi'] = true,
    ['salattanat'] = true,
    ['manirai'] = true,
    ['hainab'] = true,
    ['shabinbael'] = true,
    ['shallath-piremus'] = true,
    ['tussurradad'] = true,
    ['ahasour'] = true,
    ['senipu'] = true,
    ['sul-matuul'] = true,
    ['kurapli'] = true,
    ['maeli'] = true,
    ['sakiran'] = true,
    ['yen'] = true,
    ['ninirrasour'] = true,
    ['shara'] = true,
    ['shimsun'] = true,
    ['nibani maesa'] = true,
    ['zabamund'] = true,
    ['zanummu'] = true,
    ['sakulerib'] = true,
    ['zaba'] = true,
    ['ababael timsar-dadisun'] = true,
    ['ashibaal'] = true,
    ['kaushad'] = true,
    ['ashur-dan'] = true,
    ['minassour'] = true,
    ['patababi'] = true,
    ['tussi'] = true,
    ['sonummu zabamat'] = true,
    ['shanat kaushminipu'] = true,
    ['tibdan shalarnetus'] = true,
    ['zallay subaddamael'] = true,
    ['abassel asserbassalit'] = true,
    ['kund assarnibani'] = true,
    ['rawia ashirbibi'] = true,
    ['kausha mantashpi'] = true,
    ['manu zainab'] = true,
    ['nummu assudiraplit'] = true,
    ['odaishah yasalmibaal'] = true,
    ['yapal esatliballit'] = true,
    ['shara atinsabia'] = true,
    ['zainat ahalkalun'] = true,
    ['adibael hainnabibi'] = true,
    ['assurdan serdimapal'] = true,
    ['ibanammu assutladainab'] = true,
    ['kanit niladon'] = true,
    ['yanit sehabani'] = true,
    ['maesat shinirbael'] = true,
    ['missun hainterari'] = true,
    ['samsi ulannanit'] = true,
    ['manabi kummimmidan'] = true,
    ['sargon santumatus'] = true,
    ['teshmus assebiriddan'] = true,
    ['yahaz ashurnasaddas'] = true,
    ['adairan lalansour'] = true,
    ['hemus zelma-alit'] = true,
    ['manat shimmabadas'] = true,
    ['rasamsi esurarnat'] = true,
    ['zalit salkatanat'] = true,
    ['seba anurnudai'] = true,
    ['tis abalkala'] = true,
    ['zelay sobbinisun'] = true,
    ['anit eramarellaku'] = true,
    ['minisun ulirbabi'] = true,
    ['zalabelk saladnius'] = true,
    ['mamaea ashun-idantus'] = true,
    ['mimanu zeba-adad'] = true,
    ['zennammu'] = true,
    ['mal mibishanit'] = true,
    ['mi-ilu massitisun'] = true,
    ['subenend urshummarnamus'] = true,
    ['kitbael assurnumanit'] = true,
    ['nind dudnebisun'] = true,
    ['patus assumanallit'] = true,
}

---@type ValidPlaylistCallback
local function ashlanderEnemyRule(playback)
    return playback.state.isInCombat
        and playback.rules.combatTargetExact(MuseAshlanderEnemyNames)
end

local PlaylistPriority = require 'doc.playlistPriority'

---@type S3maphorePlaylist[]
return {
    {
        id = 'MUSE - Ashlander Settlement',
        priority = PlaylistPriority.Faction,
        randomize = true,

        tracks = {
            'Music/MS/cell/Ashlander/exploration1.mp3',
            'Music/MS/cell/Ashlander/exploration2.mp3',
            'Music/MS/cell/Ashlander/exploration3.mp3',
            'Music/MS/cell/Ashlander/exploration4.mp3',
        },

        isValidCallback = ashlanderCellRule,

    },
    {
        id = 'MUSE - Ashlander Enemies',
        priority = PlaylistPriority.BattleMod,

        tracks = {
            'Music/MS/combat/Ashlander/combat1.mp3',
            'Music/MS/combat/Ashlander/combat2.mp3',
            'Music/MS/combat/Ashlander/combat3.mp3',
        },

        isValidCallback = ashlanderEnemyRule,
    }
}
