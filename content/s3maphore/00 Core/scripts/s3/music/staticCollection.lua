local types = require 'openmw.types'
local world = require 'openmw.world'

local StaticCellChangeData = {
    staticList = {
        contentFiles = {},
        recordIds = {},
    },
    hasCombatTargets = false,
    nearestRegion = '',
}

local NPCFightThreshold = 90
local CreatureFightThreshold = 83

local FieldNames = { 'recordIds', 'contentFiles', }

--- Given a cell object, check the hostility ratings of all actors inside of it
---@param senderCell GameCell
local function updateCellInfo(senderCell)
    for _, fieldName in ipairs(FieldNames) do
        for k in pairs(StaticCellChangeData.staticList[fieldName]) do
            StaticCellChangeData.staticList[fieldName][k] = nil
        end
    end

    local uniqueStaticIds, uniqueContentFiles = {}, {}

    local addedStatics, addedContentFiles = StaticCellChangeData.staticList.recordIds,
        StaticCellChangeData.staticList.contentFiles

    local foundLiveHostiles = 0

    local nearestRegion = senderCell.region

    for _, object in ipairs(senderCell:getAll()) do
        local isNPC = types.NPC.objectIsInstance(object)
        local isCreature = types.Creature.objectIsInstance(object)

        if isNPC or isCreature then
            local fightStat = object.type.stats.ai.fight(object)
            local fightLimit = isNPC and NPCFightThreshold or CreatureFightThreshold

            if fightStat.modified >= fightLimit and not object.type.isDead(object) then
                foundLiveHostiles = foundLiveHostiles + 1
            end
        elseif types.Static.objectIsInstance(object) then
            if not uniqueStaticIds[object.recordId] then
                addedStatics[#addedStatics + 1] = object.recordId
                uniqueStaticIds[object.recordId] = true
            end

            if not uniqueContentFiles[object.contentFile] then
                if object.contentFile and object.contentFile ~= '' then
                    addedContentFiles[#addedContentFiles + 1] = object.contentFile:lower()
                    uniqueContentFiles[object.contentFile] = true
                end
            end
        elseif not nearestRegion and types.Door.objectIsInstance(object) and object.type.isTeleport(object) then
            local targetCell = object.type.destCell(object)
            if targetCell.region then
                nearestRegion = targetCell.region
            end
        end
    end

    if nearestRegion then
        StaticCellChangeData.nearestRegion = nearestRegion
    end

    StaticCellChangeData.hasCombatTargets = foundLiveHostiles > 0
end

local Globals = world.mwscript.getGlobalVariables()

---@enum WeatherType
local WeatherType = {
    [0] = 'clear',
    [1] = 'cloudy',
    [2] = 'foggy',
    [3] = 'overcast',
    [4] = 'rain',
    [5] = 'thunder',
    [6] = 'ash',
    [7] = 'blight',
    [8] = 'snow',
    [9] = 'blizzard',
}

---@type table<string, string>
local PreviousPlayerCells = {}

return {
    interfaceName = 'S3maphoreG',
    interface = {
        findCellMatches = function(pattern)
            local cellStr = ''

            for _, cell in ipairs(world.cells) do
                if cell.name
                    and cell.name ~= ''
                    and cell.name:lower():find(pattern)
                then
                    cellStr = ("%s['%s'] = true,\n"):format(cellStr, cell.name:lower():gsub("'", "\\'"))
                end
            end

            return cellStr
        end,
    },

    engineHandlers = {

        onUpdate = function()
            if Globals.S3maphoreWeatherTracker ~= -1 then
                local weatherName = WeatherType[Globals.S3maphoreWeatherTracker]

                for _, player in ipairs(world.players) do
                    player:sendEvent('S3maphoreWeatherChanged', weatherName)
                end

                Globals.S3maphoreWeatherTracker = -1
            end

            for _, player in ipairs(world.players) do
                local playerCell = player.cell
                local playerId, currentCell = player.id, playerCell.id
                local prevCell = PreviousPlayerCells[playerId]

                if not prevCell or prevCell ~= currentCell then
                    updateCellInfo(playerCell)
                    player:sendEvent('S3maphoreCellChanged', StaticCellChangeData)
                    PreviousPlayerCells[playerId] = currentCell
                end
            end
        end,

    },

    eventHandlers = {
        -- This function seems like it could have some issues.
        -- It only determines if there are actors in the cell which are *likely* to engage the player, and doesn't take into account whether or not
        -- any are actively fighting the player. But it's a useful heauristic to determine whether or not the player is *in* a dungeon or not.
        S3maphoreUpdateCellHasCombatTargets = function(sender)
            sender:sendEvent('S3maphoreCombatTargetsUpdated', updateCellHasCombatTargets(sender.cell))
        end,
    },
}
