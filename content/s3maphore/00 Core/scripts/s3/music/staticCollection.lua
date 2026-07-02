---@omw-context global

local types = require 'openmw.types'
local world = require 'openmw.world'

local StaticCellChangeData = {
    staticList = {
        contentFiles = {},
        recordIds = {},
    },
    nearestRegion = '',
}

local NearestDoor
local FieldNames = { 'recordIds', 'contentFiles', }
local NullFunction = require 'scripts.s3.nullFunction'
local liveCheckForRegion = NullFunction

local DoorType = types.Door
local SqLen = require 'openmw.util'.vector3(0, 0, 0).length2

---@diagnostic disable-next-line: undefined-field
local clear = table.clear or function(t) for k in pairs(t) do t[k] = nil end end
local function checkForRegion(object, target)
    if not DoorType.objectIsInstance(object) or not DoorType.isTeleport(object) then return end

    local targetPos, objectPos = target.position, object.position
    if not NearestDoor or SqLen(targetPos - objectPos) < SqLen(targetPos - NearestDoor.position) then
        NearestDoor = object
    end
end

--- Given a cell object, check the hostility ratings of all actors inside of it
---@param senderCell openmw.core.GCell
local function updateCellInfo(sender, senderCell)
    for i = 1, #FieldNames do
        local fieldName = FieldNames[i]
        clear(StaticCellChangeData.staticList[fieldName])
    end

    local uniqueStaticIds, uniqueContentFiles = {}, {}

    local addedStatics, addedContentFiles = StaticCellChangeData.staticList.recordIds,
        StaticCellChangeData.staticList.contentFiles

    local nearestRegion = senderCell.region
    if not nearestRegion then
        NearestDoor = nil
        liveCheckForRegion = checkForRegion
    end

    local objects = senderCell:getAll()
    for i = 1, #objects do
        local object = objects[i]

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

    liveCheckForRegion = NullFunction

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

            for i = 1, #world.cells do
                local cell = world.cells[i]

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
}
