local isOpenMW = require 'scripts.s3.isOpenMW'
local types, world

local StaticCellChangeData = {
    staticList = {
        contentFiles = {},
        recordIds = {},
    },
    nearestRegion = '',
}

local FieldNames = { 'recordIds', 'contentFiles', }
local NearestDoor = nil
local NullFunction = function() end
local liveCheckForRegion = NullFunction

local DoorType, SquaredLen

if isOpenMW then
    types = require 'openmw.types'
    world = require 'openmw.world'

    DoorType = types.Door
    SquaredLen = require 'openmw.util'.vector3(0, 0, 0).length2
end

local function checkForRegion(object, target)
    if not DoorType.objectIsInstance(object) or not DoorType.isTeleport(object) then return end

    local targetPos, objectPos = target.position, object.position
    if not NearestDoor or SquaredLen(targetPos - objectPos) < SquaredLen(targetPos - NearestDoor.position) then
        NearestDoor = object
    end
end

--- Given a cell object, check the hostility ratings of all actors inside of it
---@param senderCell GameCell|tes3cell
local function updateCellInfo(sender, senderCell)
    for _, fieldName in ipairs(FieldNames) do
        for k in pairs(StaticCellChangeData.staticList[fieldName]) do
            StaticCellChangeData.staticList[fieldName][k] = nil
        end
    end

    local uniqueStaticIds, uniqueContentFiles = {}, {}

    local addedStatics, addedContentFiles = StaticCellChangeData.staticList.recordIds,
        StaticCellChangeData.staticList.contentFiles

    local nearestRegion = senderCell.region
    if not nearestRegion then
        NearestDoor = nil
        liveCheckForRegion = isOpenMW and checkForRegion or tes3.getClosestExteriorPosition
    end

    if isOpenMW then
        for _, object in ipairs(senderCell:getAll()) do
            if types.Static.objectIsInstance(object) then
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
            end

            liveCheckForRegion(object, sender)
        end

        if NearestDoor then
            -- Teleport doors *should* always have a target cell
            local region = DoorType.destCell(NearestDoor).region

            if region then
                nearestRegion = region
            end

            NearestDoor = nil
        end
    else
        for object in senderCell:iterateReferences() do
            if object.objectType == tes3.objectType.static then
                if not uniqueStaticIds[object.baseObject.id] then
                    addedStatics[#addedStatics + 1] = object.baseObject.id
                    uniqueStaticIds[object.baseObject.id] = true
                end

                if not uniqueContentFiles[object.baseObject.sourceMod] then
                    if object.baseObject.sourceMod and object.baseObject.sourceMod ~= '' then
                        addedContentFiles[#addedContentFiles + 1] = object.baseObject.sourceMod:lower()
                        uniqueContentFiles[object.baseObject.sourceMod] = true
                    end
                end
            end

            local position = liveCheckForRegion{reference = object}
            local nearestExteriorCell = tes3.getCell{x = math.floor(position.x / 8192), y = math.floor(position.y / 8192)}
            nearestRegion = nearestExteriorCell.region
        end
    end

    liveCheckForRegion = NullFunction

    if nearestRegion then
        StaticCellChangeData.nearestRegion = nearestRegion
    end
end

local Globals = isOpenMW and world.mwscript.getGlobalVariables() or nil

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
                    updateCellInfo(player, playerCell)
                    player:sendEvent('S3maphoreCellChanged', StaticCellChangeData)
                    PreviousPlayerCells[playerId] = currentCell
                end
            end
        end,

    },

    eventHandlers = {},

    mwse = {
        weatherChanged = function(e)
            local weatherTracker = tes3.getGlobal('S3maphoreWeatherTracker')
            if weatherTracker ~= -1 then
                local weatherName = WeatherType[weatherTracker]
                event.trigger('S3maphoreWeatherChanged', {weatherName = weatherName})
                weatherTracker = -1
            end
        end,
        --- @param e cellChangedEventData
        cellChanged = function(e)
            if not e.previousCell or e.previousCell.id ~= e.cell.id then
                updateCellInfo(tes3.player, e.cell)
                event.trigger('S3maphoreCellChanged', StaticCellChangeData)
            end
        end
    }
}
