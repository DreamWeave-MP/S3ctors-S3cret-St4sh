---@omw-context player

local async = require 'openmw.async'
local camera = require 'openmw.camera'
local input = require 'openmw.input'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local v2 = util.vector2
local v3 = util.vector3

local WINDOW = I.UI.WINDOW.Inventory
local MODE = I.UI.MODE.Interface
local ROOT_LAYER = 'Windows'
local CAMERA_CONTROL_TAG = 's3ui_inventory'

local WINDOW_POSITION = v2(24, 80)
local WINDOW_SIZE = v2(500, 520)
local SLOT_SIZE = v2(72, 72)
local ICON_SIZE = v2(40, 40)
local GRID_COLUMNS = 6
local GRID_ROWS = 5
local MAX_VISIBLE_ITEMS = GRID_COLUMNS * GRID_ROWS
local STATIC_CAMERA_EXTRA_DISTANCE = 15

local rootElement = nil
local statusLayout = nil
local cameraSnapshot = nil
local hudVisibleSnapshot = nil
local registeredWindow = false

local function safeRecord(item)
    if not item or not item.type or not item.recordId then return nil end
    local records = item.type.records
    if not records then return nil end
    return records[item.recordId]
end

local function itemName(item, record)
    return (record and record.name) or item.recordId or 'Unknown item'
end

local function itemCount(inventory, item)
    if not item or not item.recordId then return 1 end
    local ok, count = pcall(function() return inventory:countOf(item.recordId) end)
    if ok and count and count > 0 then return count end
    return 1
end

local function collectInventoryItems()
    local inventory = types.Actor.inventory(self.object or self)
    local seen = {}
    local result = {}

    for _, item in ipairs(inventory:getAll()) do
        local recordId = item.recordId
        if recordId and not seen[recordId] then
            seen[recordId] = true
            local record = safeRecord(item)
            result[#result + 1] = {
                item = item,
                record = record,
                name = itemName(item, record),
                icon = record and record.icon,
                count = itemCount(inventory, item),
            }
        end
    end

    table.sort(result, function(left, right)
        return left.name:lower() < right.name:lower()
    end)

    return result
end

local function setStatus(text)
    if not rootElement or not rootElement.layout or not statusLayout then return end
    statusLayout.props.text = text
    rootElement:update()
end

local function textLine(text, template, props)
    props = props or {}
    local name = props.name
    props.name = nil
    props.text = text
    return {
        name = name,
        template = template or I.MWUI.templates.textNormal,
        props = props,
    }
end

local function makeSlot(data, index)
    local content = ui.content {}

    if data then
        local iconProps = {
            position = v2(16, 8),
            size = ICON_SIZE,
        }
        if data.icon then
            iconProps.resource = ui.texture { path = data.icon }
        end

        content:add {
            type = ui.TYPE.Image,
            props = iconProps,
        }

        if data.count > 1 then
            content:add(textLine(tostring(data.count), I.MWUI.templates.textNormal, {
                position = v2(46, 46),
                size = v2(22, 18),
                textSize = 13,
            }))
        end
    else
        content:add {
            type = ui.TYPE.Widget,
            props = { size = v2(1, 1) },
        }
    end

    return {
        name = 'slot_' .. tostring(index),
        template = I.MWUI.templates.box,
        props = {
            size = SLOT_SIZE,
        },
        userData = data,
        events = data and {
            mouseClick = async:callback(function(_, layout)
                local clicked = layout and layout.userData
                if clicked then
                    setStatus(clicked.name .. '  x' .. tostring(clicked.count))
                end
            end),
        } or nil,
        content = content,
    }
end

local function makeGrid(items)
    local rows = ui.content {}
    local index = 1

    for _ = 1, GRID_ROWS do
        local row = ui.content {}
        for _ = 1, GRID_COLUMNS do
            row:add(makeSlot(items[index], index))
            index = index + 1
        end
        rows:add {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = v2(GRID_COLUMNS * SLOT_SIZE.x, SLOT_SIZE.y),
            },
            content = row,
        }
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = v2(GRID_COLUMNS * SLOT_SIZE.x, GRID_ROWS * SLOT_SIZE.y),
        },
        content = rows,
    }
end

local function makeInventoryLayout(items)
    local visibleCount = math.min(#items, MAX_VISIBLE_ITEMS)
    local hiddenCount = math.max(0, #items - MAX_VISIBLE_ITEMS)
    local summary = tostring(visibleCount) .. ' shown'
    if hiddenCount > 0 then
        summary = summary .. ', ' .. tostring(hiddenCount) .. ' more in inventory'
    end

    return {
        type = ui.TYPE.Container,
        layer = ROOT_LAYER,
        props = {
            position = WINDOW_POSITION,
            size = WINDOW_SIZE,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.boxTransparentThick,
                props = {
                    size = WINDOW_SIZE,
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.padding,
                        content = ui.content {
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    horizontal = false,
                                    size = WINDOW_SIZE - v2(32, 32),
                                },
                                content = ui.content {
                                    textLine('Inventory', I.MWUI.templates.textHeader, { size = v2(450, 28) }),
                                    textLine('Click an item to show its name. Press I to close.', I.MWUI.templates.textNormal, { size = v2(450, 22), textSize = 15 }),
                                    makeGrid(items),
                                    textLine(summary, I.MWUI.templates.textNormal, { name = 's3ui_status', size = v2(450, 24), textSize = 15 }),
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

local function saveCamera()
    if cameraSnapshot then return end
    cameraSnapshot = {
        mode = camera.getMode(),
        yaw = camera.getYaw(),
        pitch = camera.getPitch(),
        focalOffset = camera.getFocalPreferredOffset(),
        staticPosition = camera.getPosition(),
    }
end

local function disableInventoryCameraControls()
    if not I.Camera then return end
    if I.Camera.disableModeControl then I.Camera.disableModeControl(CAMERA_CONTROL_TAG) end
    if I.Camera.disableZoom then I.Camera.disableZoom(CAMERA_CONTROL_TAG) end
    if I.Camera.disableThirdPersonOffsetControl then I.Camera.disableThirdPersonOffsetControl(CAMERA_CONTROL_TAG) end
end

local function enableInventoryCameraControls()
    if not I.Camera then return end
    if I.Camera.enableThirdPersonOffsetControl then I.Camera.enableThirdPersonOffsetControl(CAMERA_CONTROL_TAG) end
    if I.Camera.enableZoom then I.Camera.enableZoom(CAMERA_CONTROL_TAG) end
    if I.Camera.enableModeControl then I.Camera.enableModeControl(CAMERA_CONTROL_TAG) end
end

local function restoreCamera()
    if not cameraSnapshot then return end
    enableInventoryCameraControls()

    camera.setFocalPreferredOffset(cameraSnapshot.focalOffset)
    camera.setYaw(cameraSnapshot.yaw)
    camera.setPitch(cameraSnapshot.pitch)
    camera.setMode(cameraSnapshot.mode, true)

    if cameraSnapshot.mode == camera.MODE.Static then
        camera.setStaticPosition(cameraSnapshot.staticPosition)
    end

    camera.instantTransition()
    cameraSnapshot = nil
end

local function playerFrame(box, screenRight)
    local top = box.center.z + box.halfSize.z
    local bottom = box.center.z - box.halfSize.z
    local rightEdge = box.halfSize.x

    if box.vertices then
        top = -math.huge
        bottom = math.huge
        rightEdge = -math.huge

        for _, vertex in ipairs(box.vertices) do
            if vertex.z > top then top = vertex.z end
            if vertex.z < bottom then bottom = vertex.z end

            local offset = vertex - box.center
            local projectedRight = offset * screenRight
            if projectedRight > rightEdge then rightEdge = projectedRight end
        end
    end

    return {
        target = v3(box.center.x, box.center.y, (top + bottom) * 0.5),
        halfHeight = (top - bottom) * 0.5,
        rightEdge = rightEdge,
    }
end

local function saveHudVisibility()
    if hudVisibleSnapshot ~= nil then return end
    hudVisibleSnapshot = I.UI.isHudVisible()
    I.UI.setHudVisibility(false)
end

local function restoreHudVisibility()
    if hudVisibleSnapshot == nil then return end
    I.UI.setHudVisibility(hudVisibleSnapshot)
    hudVisibleSnapshot = nil
end

local function showStaticInventoryCamera()
    saveCamera()
    disableInventoryCameraControls()

    local actorYaw = self.object.rotation:getYaw()
    local front = util.transform.rotateZ(actorYaw) * v3(0, 1, 0)
    local screenRight = util.transform.rotateZ(actorYaw) * v3(-1, 0, 0)
    local bodyBounds = self.object:getBoundingBox()
    local frame = playerFrame(bodyBounds, screenRight)
    local screen = ui.screenSize()
    local aspect = screen.x / screen.y
    local verticalTan = math.tan(camera.getFieldOfView() * 0.5)
    local distance = frame.halfHeight / verticalTan + STATIC_CAMERA_EXTRA_DISTANCE
    local halfViewWidth = distance * verticalTan * aspect
    local lateralOffset = halfViewWidth - frame.rightEdge
    local pos = frame.target + front * distance - screenRight * lateralOffset

    camera.setMode(camera.MODE.Static, true)
    camera.setStaticPosition(pos)
    camera.setYaw(actorYaw + math.pi)
    camera.setPitch(0)
    camera.instantTransition()
end

local function toggleInventoryWindow()
    if I.UI.isWindowVisible(WINDOW) then
        I.UI.removeMode(MODE)
    else
        I.UI.setMode(MODE, { windows = { WINDOW } })
    end
end

local function destroyInventoryWindow()
    statusLayout = nil
    if rootElement and rootElement.layout then
        rootElement:destroy()
    end
    rootElement = nil
end

local function showInventoryWindow()
    destroyInventoryWindow()
    saveHudVisibility()
    showStaticInventoryCamera()
    rootElement = ui.create(makeInventoryLayout(collectInventoryItems()))
    statusLayout = rootElement.layout.content[1].content[1].content[1].content.s3ui_status
end

local function hideInventoryWindow()
    destroyInventoryWindow()
    restoreCamera()
    restoreHudVisibility()
end

local function registerInventoryWindow()
    if registeredWindow then return end
    I.UI.registerWindow(WINDOW, showInventoryWindow, hideInventoryWindow)
    registeredWindow = true
end

registerInventoryWindow()

return {
    engineHandlers = {
        onKeyPress = function(key)
            if key.code == input.KEY.I then
                toggleInventoryWindow()
            end
        end,
    },
}
