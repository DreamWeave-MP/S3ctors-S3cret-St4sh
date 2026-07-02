---@omw-context global

---@type S3maphoreStaticCellChangeData
local StaticCellChangeData = {
    staticList = {
        contentFiles = {},
        recordIds = {},
    },
    nearestRegion = '',
}

--- Maps player ids back to whatever their previous cell was
---@type table<string, string>
local PreviousPlayerCells = {}

--- Maps player ids back to the previously-running weather
---@type table<string, string>
local PreviousPlayerWeathers = {}

--- Maps players to playlist initialization state
---@type table<string, boolean>
local PlayersInitialized = {}

local FieldNames = { 'recordIds', 'contentFiles', }

local pairs, StrFind, StrFormat, StrGsub, StrLower = pairs, string.find, string.format, string.gsub, string.lower

---@type fun(cell: openmw.core.GCell, filter: openmw.types.Door | openmw.types.Static): openmw.GObject[]
local GetAll
--- Hoisted copy of GameObject.sendEvent
---@type fun(obj: openmw.Object, id: string, data: any)
local SendEvent

local Cells, DoorDestination, DoorType, GetCurrentWeather, GetExteriorCell,
IsDoor, IsTeleportDoor, Players, SqLen, StaticType

do
    local core = require 'openmw.core'
    local types = require 'openmw.types'
    local world = require 'openmw.world'

    Cells, Players = world.cells, world.players
    GetCurrentWeather = core.weather.getCurrent
    GetExteriorCell = world.getExteriorCell
    DoorDestination, DoorType, IsDoor, IsTeleportDoor = types.Door.destCell, types.Door, types.Door.objectIsInstance,
        types.Door.isTeleport
    SqLen = require 'openmw.util'.vector3(0, 0, 0).length2
    StaticType = types.Static
end

---@diagnostic disable-next-line: undefined-field
local clear = table.clear or function(t) for k in pairs(t) do t[k] = nil end end

---@param object openmw.GObject
---@param target openmw.GObject
---@param nearestDoor openmw.GObject?
---@return openmw.GObject? nearestDoor
local function checkForRegion(object, target, nearestDoor)
    if not IsDoor(object) or not IsTeleportDoor(object) then return end

    local targetPos, objectPos = target.position, object.position
    if not nearestDoor or SqLen(targetPos - objectPos) < SqLen(targetPos - nearestDoor.position) then
        return object
    end
end

---@param cell openmw.core.GCell
---@param seenRecordIds table<string, boolean>
---@param seenContentFiles table<string, boolean>
---@param outRecordIds string[]
---@param outContentFiles string[]
local function collectStaticItems(cell, seenRecordIds, seenContentFiles, outRecordIds, outContentFiles)
    local objects = GetAll(cell, StaticType)

    for i = 1, #objects do
        local staticObj = objects[i]

        if not seenRecordIds[staticObj.recordId] then
            outRecordIds[#outRecordIds + 1] = staticObj.recordId
            seenRecordIds[staticObj.recordId] = true
        end

        if staticObj.contentFile and staticObj.contentFile ~= '' then
            local contentFile = staticObj.contentFile

            if not seenContentFiles[contentFile] then
                outContentFiles[#outContentFiles + 1] = contentFile
                seenContentFiles[contentFile] = true
            end
        end
    end
end

---@param playerActor openmw.GObject
---@param playerCell openmw.core.GCell
local function updateCellInfo(playerActor, playerCell)
    for i = 1, #FieldNames do
        clear(StaticCellChangeData.staticList[FieldNames[i]])
    end

    local outRecordIds                    = StaticCellChangeData.staticList.recordIds
    local outContentFiles                 = StaticCellChangeData.staticList.contentFiles
    local seenRecordIds, seenContentFiles = {}, {}

    local nearestRegion                   = playerCell.region

    if playerCell.isExterior then
        local gridX, gridY = playerCell.gridX, playerCell.gridY

        for offsetX = -1, 1 do
            for offsetY = -1, 1 do
                local exteriorCell = GetExteriorCell(gridX + offsetX, gridY + offsetY)
                if exteriorCell then
                    collectStaticItems(exteriorCell, seenRecordIds, seenContentFiles, outRecordIds,
                        outContentFiles)
                end
            end
        end
    else
        collectStaticItems(playerCell, seenRecordIds, seenContentFiles, outRecordIds, outContentFiles)

        if not nearestRegion then
            local nearestDoor

            local allDoors = GetAll(playerCell, DoorType)

            for i = 1, #allDoors do
                nearestDoor = checkForRegion(allDoors[i], playerActor, nearestDoor)
            end

            if nearestDoor then
                local region = DoorDestination(nearestDoor).region
                if region then nearestRegion = region end
                nearestDoor = nil
            end
        end
    end

    if nearestRegion then
        StaticCellChangeData.nearestRegion = nearestRegion
    end
end

---@param player openmw.GObject
---@param playerId string
local function playerTick(player, playerId)
    local playerCell = player.cell
    ---@cast playerCell openmw.core.GCell

    local currentWeather = GetCurrentWeather(playerCell)
    local lastKnownWeather = PreviousPlayerWeathers[playerId]

    local weatherId
    if currentWeather then weatherId = currentWeather.recordId end

    if lastKnownWeather ~= weatherId then
        SendEvent(player, 'S3maphoreWeatherChanged', weatherId)
        PreviousPlayerWeathers[playerId] = weatherId
    end

    local currentCell, prevCell = playerCell.id, PreviousPlayerCells[playerId]
    if prevCell ~= currentCell then
        updateCellInfo(player, playerCell)
        SendEvent(player, 'S3maphoreCellChanged', StaticCellChangeData)
        PreviousPlayerCells[playerId] = currentCell
    end
end

return {
    interfaceName = 'S3maphoreG',
    interface = {
        findCellMatches = function(pattern)
            local cellStr = ''

            for i = 1, #Cells do
                local cell = Cells[i]; local cellName = cell.name

                if
                    cellName
                    and cellName ~= ''
                    and StrFind(StrLower(cellName), pattern)
                then
                    cellStr = StrFormat("%s['%s'] = true,\n", cellStr, StrGsub(StrLower(cellName), "'", "\\'"))
                end
            end

            return cellStr
        end,
    },

    engineHandlers = {
        onUpdate = function()
            for i = 1, #Players do
                local player = Players[i]; local playerId = player.id

                local initialized = PlayersInitialized[playerId] ~= nil

                if initialized then playerTick(player, playerId) end
            end
        end,
    },
    eventHandlers = {
        S3maphoreInitializationComplete = function(pid)
            PlayersInitialized[pid] = true
            if not SendEvent then SendEvent = Players[1].sendEvent end
            if not GetAll then GetAll = Cells[1].getAll end
        end,
    },
}
