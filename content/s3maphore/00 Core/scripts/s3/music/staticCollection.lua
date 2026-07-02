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

local NearestDoor
local FieldNames = { 'recordIds', 'contentFiles', }
local NullFunction = require 'scripts.s3.nullFunction'
local liveCheckForRegion = NullFunction

local pairs, StrFind, StrFormat, StrGsub, StrLower = pairs, string.find, string.format, string.gsub, string.lower

---@type fun(cell: openmw.core.GCell): openmw.GObject[]
local GetAll
--- Hoisted copy of GameObject.sendEvent
---@type fun(obj: openmw.Object, id: string, data: any)
local SendEvent

local Cells, DoorDestination, GetCurrentWeather, IsDoor,
IsStatic, IsTeleportDoor, Players, SqLen

do
    local core = require 'openmw.core'
    local types = require 'openmw.types'
    local world = require 'openmw.world'

    Cells, Players = world.cells, world.players
    GetCurrentWeather = core.weather.getCurrent
    IsStatic = types.Static.objectIsInstance
    DoorDestination, IsDoor, IsTeleportDoor = types.Door.destCell, types.Door.objectIsInstance, types.Door.isTeleport
    SqLen = require 'openmw.util'.vector3(0, 0, 0).length2
end

---@diagnostic disable-next-line: undefined-field
local clear = table.clear or function(t) for k in pairs(t) do t[k] = nil end end

---@param object openmw.GObject
---@param target openmw.GObject
local function checkForRegion(object, target)
    if not IsDoor(object) or not IsTeleportDoor(object) then return end

    local targetPos, objectPos = target.position, object.position
    if not NearestDoor or SqLen(targetPos - objectPos) < SqLen(targetPos - NearestDoor.position) then
        NearestDoor = object
    end
end

--- Given a cell object, check the hostility ratings of all actors inside of it
---@param cellId openmw.core.GCell
local function updateCellInfo(sender, cellId)
    for i = 1, #FieldNames do
        local fieldName = FieldNames[i]
        clear(StaticCellChangeData.staticList[fieldName])
    end

    local uniqueStaticIds, uniqueContentFiles = {}, {}

    local addedStatics, addedContentFiles = StaticCellChangeData.staticList.recordIds,
        StaticCellChangeData.staticList.contentFiles

    local nearestRegion = cellId.region
    if not nearestRegion then
        NearestDoor = nil
        liveCheckForRegion = checkForRegion
    end

    local objects = GetAll(cellId)
    for i = 1, #objects do
        local object = objects[i]

        if IsStatic(object) then
            if not uniqueStaticIds[object.recordId] then
                addedStatics[#addedStatics + 1] = object.recordId
                uniqueStaticIds[object.recordId] = true
            end

            if not uniqueContentFiles[object.contentFile] then
                if object.contentFile and object.contentFile ~= '' then
                    addedContentFiles[#addedContentFiles + 1] = StrLower(object.contentFile)
                    uniqueContentFiles[object.contentFile] = true
                end
            end
        end

        liveCheckForRegion(object, sender)
    end

    if NearestDoor then
        -- Teleport doors *should* always have a target cell
        local region = DoorDestination(NearestDoor).region

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
