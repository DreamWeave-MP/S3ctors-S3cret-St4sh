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
local GRID_COLUMNS = 6
local GRID_ROWS = 5
local WHITE_TEXTURE = ui.texture { path = 'white' }
local BACKGROUND_COLOR = util.color.rgb(0, 0, 0)
local ICON_RELATIVE_SIZE = v2(0.58, 0.58)
local COUNT_RELATIVE_SIZE = v2(0.28, 0.22)
local TITLE_RELATIVE_SIZE = v2(1, 0.06)
local HINT_RELATIVE_SIZE = v2(1, 0.05)
local STATUS_RELATIVE_SIZE = v2(1, 0.05)
local MAX_VISIBLE_ITEMS = GRID_COLUMNS * GRID_ROWS
local STATIC_CAMERA_EXTRA_DISTANCE = 15
local TOOLTIP_LAYER = ROOT_LAYER
local TOOLTIP_SIZE = v2(360, 230)
local TOOLTIP_MOUSE_OFFSET = v2(24, 24)
local TOOLTIP_HEADER_SIZE = v2(1, 0.28)
local TOOLTIP_PRIMARY_SIZE = v2(1, 0.34)
local TOOLTIP_SECONDARY_SIZE = v2(1, 0.32)
local TOOLTIP_ICON_SIZE = v2(48, 48)
local TOOLTIP_FIELD_TEXT_SIZE = 14
local TOOLTIP_VALUE_TEXT_SIZE = 16
local EMPTY_FIELD = '—'

local rootElement = nil
local tooltipElement = nil
local statusLayout = nil
local cameraSnapshot = nil
local hudVisibleSnapshot = nil
local registeredWindow = false

local TYPE_NAMES = {
    [types.Apparatus] = 'Apparatus',
    [types.Armor] = 'Armor',
    [types.Book] = 'Book',
    [types.Clothing] = 'Clothing',
    [types.Ingredient] = 'Ingredient',
    [types.Light] = 'Light',
    [types.Lockpick] = 'Lockpick',
    [types.Miscellaneous] = 'Miscellaneous',
    [types.Potion] = 'Potion',
    [types.Probe] = 'Probe',
    [types.Repair] = 'Repair',
    [types.Weapon] = 'Weapon',
}

local ARMOR_TYPE_NAMES = {
    [types.Armor.TYPE.Boots] = 'Boots',
    [types.Armor.TYPE.Cuirass] = 'Cuirass',
    [types.Armor.TYPE.Greaves] = 'Greaves',
    [types.Armor.TYPE.Helmet] = 'Helmet',
    [types.Armor.TYPE.LBracer] = 'Left Bracer',
    [types.Armor.TYPE.LGauntlet] = 'Left Gauntlet',
    [types.Armor.TYPE.LPauldron] = 'Left Pauldron',
    [types.Armor.TYPE.RBracer] = 'Right Bracer',
    [types.Armor.TYPE.RGauntlet] = 'Right Gauntlet',
    [types.Armor.TYPE.RPauldron] = 'Right Pauldron',
    [types.Armor.TYPE.Shield] = 'Shield',
}

local CLOTHING_TYPE_NAMES = {
    [types.Clothing.TYPE.Amulet] = 'Amulet',
    [types.Clothing.TYPE.Belt] = 'Belt',
    [types.Clothing.TYPE.LGlove] = 'Left Glove',
    [types.Clothing.TYPE.Pants] = 'Pants',
    [types.Clothing.TYPE.RGlove] = 'Right Glove',
    [types.Clothing.TYPE.Ring] = 'Ring',
    [types.Clothing.TYPE.Robe] = 'Robe',
    [types.Clothing.TYPE.Shirt] = 'Shirt',
    [types.Clothing.TYPE.Shoes] = 'Shoes',
    [types.Clothing.TYPE.Skirt] = 'Skirt',
}

local WEAPON_TYPE_NAMES = {
    [types.Weapon.TYPE.Arrow] = 'Arrow',
    [types.Weapon.TYPE.AxeOneHand] = 'One Handed Axe',
    [types.Weapon.TYPE.AxeTwoHand] = 'Two Handed Axe',
    [types.Weapon.TYPE.BluntOneHand] = 'One Handed Blunt',
    [types.Weapon.TYPE.BluntTwoClose] = 'Close Two Handed Blunt',
    [types.Weapon.TYPE.BluntTwoWide] = 'Wide Two Handed Blunt',
    [types.Weapon.TYPE.Bolt] = 'Bolt',
    [types.Weapon.TYPE.LongBladeOneHand] = 'One Handed Long Blade',
    [types.Weapon.TYPE.LongBladeTwoHand] = 'Two Handed Long Blade',
    [types.Weapon.TYPE.MarksmanBow] = 'Bow',
    [types.Weapon.TYPE.MarksmanCrossbow] = 'Crossbow',
    [types.Weapon.TYPE.MarksmanThrown] = 'Thrown',
    [types.Weapon.TYPE.ShortBladeOneHand] = 'Short Blade',
    [types.Weapon.TYPE.SpearTwoWide] = 'Spear',
}

local APPARATUS_TYPE_NAMES = {
    [types.Apparatus.TYPE.Alembic] = 'Alembic',
    [types.Apparatus.TYPE.Calcinator] = 'Calcinator',
    [types.Apparatus.TYPE.MortarPestle] = 'Mortar & Pestle',
    [types.Apparatus.TYPE.Retort] = 'Retort',
}

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

local function formatNumber(value, decimals)
    if type(value) ~= 'number' then return EMPTY_FIELD end
    if decimals then return string.format('%.' .. tostring(decimals) .. 'f', value) end
    return tostring(value)
end

local function formatDamage(minDamage, maxDamage)
    if type(minDamage) ~= 'number' or type(maxDamage) ~= 'number' then return EMPTY_FIELD end
    return tostring(minDamage) .. '–' .. tostring(maxDamage)
end

local function subtypeName(recordType, record)
    if not record then return EMPTY_FIELD end
    if recordType == types.Armor then return ARMOR_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Clothing then return CLOTHING_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Weapon then return WEAPON_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Apparatus then return APPARATUS_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Book and record.isScroll then return 'Scroll' end
    if recordType == types.Miscellaneous and record.isKey then return 'Key' end
    return EMPTY_FIELD
end

local function typeText(data)
    if not data then return EMPTY_FIELD end
    local recordType = TYPE_NAMES[data.item and data.item.type] or 'Item'
    local subtype = subtypeName(data.item and data.item.type, data.record)
    if subtype == EMPTY_FIELD then return recordType end
    return recordType .. '\n' .. subtype
end

local function goldPerWeight(record)
    if not record or type(record.weight) ~= 'number' or record.weight <= 0 or type(record.value) ~= 'number' then
        return EMPTY_FIELD
    end
    return formatNumber(record.value / record.weight, 2)
end

local function backgroundAlpha()
    return ui._getMenuTransparency()
end

local function tooltipText(name, text, props, template, external)
    props = props or {}
    props.text = text
    return {
        name = name,
        template = template or I.MWUI.templates.textNormal,
        external = external,
        props = props,
    }
end

local function tooltipField(name, label)
    return {
        name = name .. '_box',
        type = ui.TYPE.Flex,
        template = I.MWUI.templates.borders,
        props = {
            horizontal = false,
            autoSize = false,
            relativeSize = v2(0, 1),
        },
        external = { grow = 1 },
        content = ui.content {
            tooltipText(name .. '_label', label, {
                relativeSize = v2(1, 0.42),
                textSize = TOOLTIP_FIELD_TEXT_SIZE,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                autoSize = false,
            }),
            tooltipText(name .. '_value', EMPTY_FIELD, {
                relativeSize = v2(1, 0.58),
                textSize = TOOLTIP_VALUE_TEXT_SIZE,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                multiline = true,
                wordWrap = true,
                autoSize = false,
            }),
        },
    }
end

local function tooltipFieldValue(rowLayout, name)
    return rowLayout.content[name .. '_box'].content[name .. '_value']
end

local function setTooltipField(rowLayout, name, value)
    tooltipFieldValue(rowLayout, name).props.text = value or EMPTY_FIELD
end

local function makeTooltipLayout()
    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        layer = TOOLTIP_LAYER,
        props = {
            position = WINDOW_POSITION + v2(WINDOW_SIZE.x + 16, 0),
            size = TOOLTIP_SIZE,
            visible = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEXTURE,
                    color = BACKGROUND_COLOR,
                    alpha = backgroundAlpha(),
                    relativeSize = v2(1, 1),
                },
            },
            {
                name = 's3ui_tooltip_body',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    relativeSize = v2(1, 1),
                    autoSize = false,
                },
                content = ui.content {
                    {
                        name = 's3ui_tooltip_header',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            relativeSize = TOOLTIP_HEADER_SIZE,
                            autoSize = false,
                        },
                        content = ui.content {
                            {
                                name = 's3ui_tooltip_icon',
                                type = ui.TYPE.Image,
                                props = {
                                    size = TOOLTIP_ICON_SIZE,
                                },
                            },
                            tooltipText('s3ui_tooltip_name', EMPTY_FIELD, {
                                size = v2(250, 0),
                                textSize = 21,
                                textAlignH = ui.ALIGNMENT.Start,
                                textAlignV = ui.ALIGNMENT.Center,
                                multiline = true,
                                wordWrap = true,
                                autoSize = false,
                            }, I.MWUI.templates.textHeader, { stretch = 1 }),
                            tooltipText('s3ui_tooltip_count', '', {
                                size = v2(52, 0),
                                textSize = 18,
                                textAlignH = ui.ALIGNMENT.Center,
                                textAlignV = ui.ALIGNMENT.Center,
                                autoSize = false,
                            }, nil, { stretch = 1 }),
                        },
                    },
                    {
                        name = 's3ui_tooltip_primary',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            relativeSize = TOOLTIP_PRIMARY_SIZE,
                            autoSize = false,
                        },
                        content = ui.content {
                            tooltipField('s3ui_tooltip_type', 'Type'),
                            tooltipField('s3ui_tooltip_value', 'Value'),
                            tooltipField('s3ui_tooltip_weight', 'Weight'),
                            tooltipField('s3ui_tooltip_gold_per_weight', 'Gold/Wt'),
                        },
                    },
                    {
                        name = 's3ui_tooltip_secondary',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            relativeSize = TOOLTIP_SECONDARY_SIZE,
                            autoSize = false,
                        },
                        content = ui.content {
                            tooltipField('s3ui_tooltip_reach', 'Reach'),
                            tooltipField('s3ui_tooltip_speed', 'Speed'),
                            tooltipField('s3ui_tooltip_thrust', 'Thrust'),
                            tooltipField('s3ui_tooltip_chop', 'Chop'),
                            tooltipField('s3ui_tooltip_slash', 'Slash'),
                        },
                    },
                },
            },
        },
    }
end

local function hideTooltip()
    if not tooltipElement or not tooltipElement.layout then return end
    tooltipElement.layout.props.visible = false
    tooltipElement:update()
end

local function moveTooltip(mouseEvent)
    if not tooltipElement or not tooltipElement.layout or not mouseEvent or not mouseEvent.position then return end
    local screen = ui.screenSize()
    local position = mouseEvent.position + TOOLTIP_MOUSE_OFFSET
    if position.x + TOOLTIP_SIZE.x > screen.x then position.x = screen.x - TOOLTIP_SIZE.x end
    if position.y + TOOLTIP_SIZE.y > screen.y then position.y = screen.y - TOOLTIP_SIZE.y end
    if position.x < 0 then position.x = 0 end
    if position.y < 0 then position.y = 0 end
    tooltipElement.layout.props.position = position
end

local function updateTooltip(data, mouseEvent)
    if not tooltipElement or not tooltipElement.layout or not data then return end

    moveTooltip(mouseEvent)

    local bodyContent = tooltipElement.layout.content.s3ui_tooltip_body.content
    local header = bodyContent.s3ui_tooltip_header.content
    local primary = bodyContent.s3ui_tooltip_primary
    local secondary = bodyContent.s3ui_tooltip_secondary
    local record = data.record

    if data.icon then
        header.s3ui_tooltip_icon.props.resource = ui.texture { path = data.icon }
    else
        header.s3ui_tooltip_icon.props.resource = WHITE_TEXTURE
    end

    header.s3ui_tooltip_name.props.text = data.name or itemName(data.item, record)
    header.s3ui_tooltip_count.props.text = data.count and data.count > 1 and ('x' .. tostring(data.count)) or ''

    setTooltipField(primary, 's3ui_tooltip_type', typeText(data))
    setTooltipField(primary, 's3ui_tooltip_value', record and record.value and tostring(record.value) or EMPTY_FIELD)
    setTooltipField(primary, 's3ui_tooltip_weight', formatNumber(record and record.weight, 2))
    setTooltipField(primary, 's3ui_tooltip_gold_per_weight', goldPerWeight(record))

    if data.item and data.item.type == types.Weapon then
        setTooltipField(secondary, 's3ui_tooltip_reach', formatNumber(record and record.reach, 2))
        setTooltipField(secondary, 's3ui_tooltip_speed', formatNumber(record and record.speed, 2))
        setTooltipField(secondary, 's3ui_tooltip_thrust', formatDamage(record and record.thrustMinDamage, record and record.thrustMaxDamage))
        setTooltipField(secondary, 's3ui_tooltip_chop', formatDamage(record and record.chopMinDamage, record and record.chopMaxDamage))
        setTooltipField(secondary, 's3ui_tooltip_slash', formatDamage(record and record.slashMinDamage, record and record.slashMaxDamage))
    else
        setTooltipField(secondary, 's3ui_tooltip_reach', '')
        setTooltipField(secondary, 's3ui_tooltip_speed', '')
        setTooltipField(secondary, 's3ui_tooltip_thrust', '')
        setTooltipField(secondary, 's3ui_tooltip_chop', '')
        setTooltipField(secondary, 's3ui_tooltip_slash', '')
    end

    tooltipElement.layout.props.visible = true
    tooltipElement:update()
end

local function makeSlot(data, index)
    local content = ui.content {}

    if data then
        local iconProps = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.45),
            relativeSize = ICON_RELATIVE_SIZE,
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
                anchor = v2(1, 1),
                relativePosition = v2(0.88, 0.88),
                relativeSize = COUNT_RELATIVE_SIZE,
                textSize = 13,
            }))
        end
    else
        content:add {
            type = ui.TYPE.Widget,
            props = { relativeSize = v2(1, 1) },
        }
    end

    return {
        name = 'slot_' .. tostring(index),
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = v2(1 / GRID_COLUMNS, 1),
        },
        userData = data,
        events = data and {
            focusGain = async:callback(function(mouseEvent, layout)
                updateTooltip(layout and layout.userData, mouseEvent)
            end),
            focusLoss = async:callback(function()
                hideTooltip()
            end),
            mouseMove = async:callback(function(mouseEvent, layout)
                updateTooltip(layout and layout.userData, mouseEvent)
            end),
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
                relativeSize = v2(1, 1 / GRID_ROWS),
                autoSize = false,
            },
            content = row,
        }
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            relativeSize = v2(1, 0),
            autoSize = false,
        },
        external = { grow = 1 },
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
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        layer = ROOT_LAYER,
        props = {
            position = WINDOW_POSITION,
            size = WINDOW_SIZE,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEXTURE,
                    color = BACKGROUND_COLOR,
                    alpha = backgroundAlpha(),
                    relativeSize = v2(1, 1),
                },
            },
            {
                name = 's3ui_body',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    relativeSize = v2(1, 1),
                    autoSize = false,
                },
                content = ui.content {
                    textLine('Inventory', I.MWUI.templates.textHeader, { relativeSize = TITLE_RELATIVE_SIZE }),
                    textLine('Click an item to show its name. Press I to close.', I.MWUI.templates.textNormal, { relativeSize = HINT_RELATIVE_SIZE, textSize = 15 }),
                    makeGrid(items),
                    textLine(summary, I.MWUI.templates.textNormal, { name = 's3ui_status', relativeSize = STATUS_RELATIVE_SIZE, textSize = 15 }),
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
    local leftEdge = -box.halfSize.x

    if box.vertices then
        top = -math.huge
        bottom = math.huge
        rightEdge = -math.huge
        leftEdge = math.huge

        for _, vertex in ipairs(box.vertices) do
            if vertex.z > top then top = vertex.z end
            if vertex.z < bottom then bottom = vertex.z end

            local offset = vertex - box.center
            local projectedRight = offset * screenRight
            if projectedRight > rightEdge then rightEdge = projectedRight end
            if projectedRight < leftEdge then leftEdge = projectedRight end
        end
    end

    return {
        target = v3(box.center.x, box.center.y, (top + bottom) * 0.5),
        halfHeight = (top - bottom) * 0.5,
        rightEdge = rightEdge,
        width = rightEdge - leftEdge,
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
    local lateralOffset = halfViewWidth - frame.rightEdge - frame.width
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
    if tooltipElement and tooltipElement.layout then
        tooltipElement:destroy()
    end
    tooltipElement = nil
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
    statusLayout = rootElement.layout.content.s3ui_body.content.s3ui_status
    tooltipElement = ui.create(makeTooltipLayout())
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
