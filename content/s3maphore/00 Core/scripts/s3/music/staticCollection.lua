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

--- Given a cell object, check the hostility ratings of all actors inside of it
---@param senderCell GameCell
---@return boolean hasLiveTargets whether or not the cell has active combat targets
local function updateCellHasCombatTargets(senderCell)
    local objects = senderCell:getAll()
    local foundLiveHostiles = 0

    for _, object in ipairs(objects) do
        local isNPC = types.NPC.objectIsInstance(object)
        local isCreature = types.Creature.objectIsInstance(object)

        if not isNPC and not isCreature then goto continue end

        local fightStat = object.type.stats.ai.fight(object)
        local fightLimit = isNPC and NPCFightThreshold or CreatureFightThreshold

        if fightStat.modified >= fightLimit and not object.type.isDead(object) then
            foundLiveHostiles = foundLiveHostiles + 1
        end

        ::continue::
    end

    StaticCellChangeData.hasCombatTargets = foundLiveHostiles > 0

    return StaticCellChangeData.hasCombatTargets
end

local FieldNames = { 'recordIds', 'contentFiles', }

--- Given a cell object, find all unique static Ids and content files which placed statics in the cell
---@param cell GameCell
local function updateStaticsInActorCell(cell)
    for _, fieldName in ipairs(FieldNames) do
        for k in pairs(StaticCellChangeData.staticList[fieldName]) do
            StaticCellChangeData.staticList[fieldName][k] = nil
        end
    end

    local uniqueStaticIds, uniqueContentFiles = {}, {}

    local addedStatics, addedContentFiles = StaticCellChangeData.staticList.recordIds,
        StaticCellChangeData.staticList.contentFiles

    local staticsInCell = cell:getAll(types.Static)

    for _, static in ipairs(staticsInCell) do
        if not uniqueStaticIds[static.recordId] then
            addedStatics[#addedStatics + 1] = static.recordId
            uniqueStaticIds[static.recordId] = true
        end

        if not uniqueContentFiles[static.contentFile] then
            if static.contentFile and static.contentFile ~= '' then
                addedContentFiles[#addedContentFiles + 1] = static.contentFile:lower()
                uniqueContentFiles[static.contentFile] = true
            end
        end
    end

    return addedStatics, addedContentFiles
end

--- Finds the nearest associated region to a cell, returning it if one is found.
---@param cell GameCell
local function updateNearestRegionForCell(cell)
    local nearestRegion = cell.region

    if not nearestRegion then
        local allDoors = cell:getAll(types.Door)

        for _, door in ipairs(allDoors) do
            if not door.type.isTeleport(door) then goto CONTINUE end

            local targetCell = door.type.destCell(door)
            if targetCell.region then
                nearestRegion = targetCell.region
                break
            end
            ::CONTINUE::
        end
    end

    if nearestRegion then
        StaticCellChangeData.nearestRegion = nearestRegion
    end
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
                    updateStaticsInActorCell(playerCell)
                    updateNearestRegionForCell(playerCell)
                    updateCellHasCombatTargets(playerCell)

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
