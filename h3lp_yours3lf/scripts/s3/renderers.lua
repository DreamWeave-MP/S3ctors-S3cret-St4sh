---@omw-context menu

local async = require 'openmw.async'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local clamp = util.clamp

local I = require 'openmw.interfaces'

local markTexture = ui.texture { path = 'textures/menu_map_smark.dds' }
local whiteTexture = ui.texture { path = 'white' }
local screenPositionLayer = 'Modal'

local screenPositionPopup
local screenPositionGeneration = 0

local function normalizedScreenPosition(value)
    if value == nil then
        return util.vector2(0.5, 0.5)
    end
    return util.vector2(
        clamp(value.x, 0, 1),
        clamp(value.y, 0, 1))
end

local function sameScreenPosition(a, b)
    return a and b and a.x == b.x and a.y == b.y
end

local function destroyScreenPositionPopup()
    local popup = screenPositionPopup
    if not popup then return end
    popup.alive = false
    screenPositionPopup = nil
    if popup.element and popup.element.layout then
        popup.element:destroy()
    end
end

local function isScreenPositionPopupAlive(popup, generation)
    return popup
        and popup.alive
        and screenPositionPopup == popup
        and popup.generation == generation
        and popup.element
        and popup.element.layout ~= nil
end

local function menuTransparency()
    ---@diagnostic disable-next-line: undefined-field
    return ui._getMenuTransparency()
end

local function screenPositionTitle(argument)
    if type(argument) ~= 'table' then
        return nil
    end
    if type(argument.title) == 'string' then
        return argument.title
    end
    if type(argument.l10n) == 'string' and type(argument.name) == 'string' then
        return core.l10n(argument.l10n)(argument.name)
    end
    return nil
end

I.Settings.registerRenderer('ScreenPosition', function(value, set, argument)
    local l10n = core.l10n('H3')
    local buttonSize = util.vector2(20, 20)
    local previewSize = util.vector2(50, 50)
    local titleText = screenPositionTitle(argument)
    local panelRelativeSize = util.vector2(0.18, titleText and 0.24 or 0.21)
    local titleRelativePosition = util.vector2(0.5, 0.09)
    local titleRelativeSize = util.vector2(0.9, 0.1)
    local pickerRelativePosition = util.vector2(0.5, titleText and 0.48 or 0.42)
    local pickerRelativeSize = util.vector2(0.82, titleText and 0.56 or 0.68)
    local markerRelativeSize = util.vector2(0.08, 0.11)
    local buttonRelativeSize = util.vector2(0.3, 0.12)
    local applyButtonRelativePosition = util.vector2(0.33, 0.88)
    local cancelButtonRelativePosition = util.vector2(0.67, 0.88)
    local currentValue = normalizedScreenPosition(value)

    local function marker(position, props)
        props = props or { size = buttonSize }
        props.anchor = position
        props.relativePosition = position
        return {
            template = I.MWUI.templates.borders,
            props = props,
            content = ui.content({
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = markTexture,
                        relativeSize = util.vector2(1, 1),
                        color = util.color.rgb(202 / 255, 165 / 255, 96 / 255),
                    },
                },
            }),
        }
    end

    local function openPopup()
        destroyScreenPositionPopup()
        screenPositionGeneration = screenPositionGeneration + 1

        local original = normalizedScreenPosition(value)
        local draft = original
        local writtenValue = nil
        local dragging = false
        local popup = {
            alive = true,
            generation = screenPositionGeneration,
            element = nil,
        }
        local screenSize = ui.screenSize()
        local panelSize = util.vector2(
            screenSize.x * panelRelativeSize.x,
            screenSize.y * panelRelativeSize.y)
        local pickerSize = util.vector2(
            panelSize.x * pickerRelativeSize.x,
            panelSize.y * pickerRelativeSize.y)
        local generation = popup.generation
        local markerLayout = marker(draft, { relativeSize = markerRelativeSize })
        local backgroundAlpha = menuTransparency()
        local panelContent = ui.content({})

        local function updateMarker()
            markerLayout.props.anchor = draft
            markerLayout.props.relativePosition = draft
            if isScreenPositionPopupAlive(popup, generation) then
                popup.element:update()
            end
        end

        local function offsetToDraft(offset)
            draft = util.vector2(
                clamp(offset.x / pickerSize.x, 0, 1),
                clamp(offset.y / pickerSize.y, 0, 1))
            updateMarker()
        end

        local function offsetInsidePicker(offset)
            return offset.x >= 0 and offset.y >= 0 and offset.x <= pickerSize.x and offset.y <= pickerSize.y
        end

        local function closePopup()
            if isScreenPositionPopupAlive(popup, generation) then
                destroyScreenPositionPopup()
            end
        end

        local function button(label, callback, props)
            return {
                props = props,
                content = ui.content({
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = whiteTexture,
                            relativeSize = util.vector2(1, 1),
                            color = util.color.rgb(0, 0, 0),
                            alpha = backgroundAlpha,
                        },
                    },
                    {
                        template = I.MWUI.templates.borders,
                        props = {
                            relativeSize = util.vector2(1, 1),
                        },
                    },
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = label,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            autoSize = false,
                            relativeSize = util.vector2(1, 1),
                        },
                    },
                }),
                events = {
                    mouseClick = async:callback(function()
                        if isScreenPositionPopupAlive(popup, generation) then
                            callback()
                        end
                    end),
                },
            }
        end

        panelContent:add({
            type = ui.TYPE.Image,
            props = {
                resource = whiteTexture,
                relativeSize = util.vector2(1, 1),
                color = util.color.rgb(0, 0, 0),
                alpha = backgroundAlpha,
            },
        })
        panelContent:add({
            template = I.MWUI.templates.borders,
            props = {
                relativeSize = util.vector2(1, 1),
            },
        })
        if titleText then
            panelContent:add({
                template = I.MWUI.templates.textHeader,
                props = {
                    anchor = util.vector2(0.5, 0.5),
                    relativePosition = titleRelativePosition,
                    relativeSize = titleRelativeSize,
                    text = titleText,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    autoSize = false,
                },
            })
        end
        panelContent:add({
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = pickerRelativePosition,
                relativeSize = pickerRelativeSize,
            },
            content = ui.content({
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = whiteTexture,
                        relativeSize = util.vector2(1, 1),
                        color = util.color.rgb(0, 0, 0),
                        alpha = backgroundAlpha,
                    },
                },
                {
                    template = I.MWUI.templates.borders,
                    props = {
                        relativeSize = util.vector2(1, 1),
                    },
                },
                markerLayout,
            }),
            events = {
                mousePress = async:callback(function(event)
                    if not isScreenPositionPopupAlive(popup, generation) or not event or event.button ~= 1 then
                        return
                    end
                    dragging = true
                    offsetToDraft(event.offset)
                end),
                mouseMove = async:callback(function(event)
                    if not isScreenPositionPopupAlive(popup, generation) or not dragging or not event then
                        return
                    end
                    offsetToDraft(event.offset)
                end),
                mouseRelease = async:callback(function(event)
                    if not isScreenPositionPopupAlive(popup, generation) or not dragging or not event or event.button ~= 1 then
                        return
                    end
                    dragging = false
                    if offsetInsidePicker(event.offset) then
                        offsetToDraft(event.offset)
                    end
                    writtenValue = draft
                    set(draft)
                end),
                focusLoss = async:callback(function()
                    dragging = false
                end),
            },
        })
        panelContent:add({
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = applyButtonRelativePosition,
                relativeSize = buttonRelativeSize,
            },
            content = ui.content({
                button(l10n('button_apply'), closePopup, {
                    relativeSize = util.vector2(1, 1),
                }),
            }),
        })
        panelContent:add({
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = cancelButtonRelativePosition,
                relativeSize = buttonRelativeSize,
            },
            content = ui.content({
                button(l10n('button_cancel'), function()
                    if writtenValue and not sameScreenPosition(writtenValue, original) then
                        set(original)
                    end
                    closePopup()
                end, {
                    relativeSize = util.vector2(1, 1),
                }),
            }),
        })

        popup.element = ui.create({
            layer = screenPositionLayer,
            props = {
                relativeSize = util.vector2(1, 1),
            },
            content = ui.content({
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = whiteTexture,
                        relativeSize = util.vector2(1, 1),
                        color = util.color.rgb(0, 0, 0),
                        alpha = 0.45,
                    },
                },
                {
                    props = {
                        anchor = util.vector2(0.5, 0.5),
                        relativePosition = util.vector2(0.5, 0.5),
                        relativeSize = panelRelativeSize,
                    },
                    content = panelContent,
                },
            }),
        })
        screenPositionPopup = popup
    end

    return {
        props = {
            size = previewSize + buttonSize,
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    resource = whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = util.color.rgb(0, 0, 0),
                    alpha = menuTransparency(),
                },
            },
            {
                template = I.MWUI.templates.borders,
                props = {
                    relativeSize = util.vector2(1, 1),
                },
            },
            marker(currentValue, { size = buttonSize }),
        }),
        events = {
            mouseClick = async:callback(openPopup),
        },
    }
end)

I.Settings.registerRenderer('List', function(input, set)
    local l10n = core.l10n('H3')
    local value = {}
    for i = 1, #input do
        table.insert(value, input[i])
    end
    local header = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content({}),
        external = {
            stretch = 1,
        },
    }
    local inputText = ''
    header.content:add({
        template = I.MWUI.templates.box,
        content = ui.content({
            {
                template = I.MWUI.templates.textEditLine,
                events = {
                    textChanged = async:callback(function(text)
                        inputText = text:lower()
                    end),
                },
            },
        }),
    })
    header.content:add({
        template = I.MWUI.templates.padding,
        external = {
            grow = 1,
        },
    })
    header.content:add({
        template = I.MWUI.templates.box,
        content = ui.content({
            {
                template = I.MWUI.templates.textNormal,
                props = {
                    text = l10n('button_add'),
                },
                events = {
                    mouseClick = async:callback(function()
                        table.insert(value, inputText)
                        set(value)
                    end),
                },
            },
        }),
    })
    local body = {
        type = ui.TYPE.Flex,
        content = ui.content({}),
    }
    local function remove(text)
        for i, v in ipairs(value) do
            if v == text then
                table.remove(value, i)
            end
            return
        end
    end
    for _, text in ipairs(value) do
        body.content:add({
            template = I.MWUI.templates.padding,
        })
        body.content:add({
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
            },
            content = ui.content({
                {
                    template = I.MWUI.templates.textNormal,
                    props = { text = text },
                },
                {
                    template = I.MWUI.templates.padding,
                },
                {
                    template = I.MWUI.templates.box,
                    content = ui.content({
                        {
                            template = I.MWUI.templates.textNormal,
                            props = { text = l10n('button_remove') },
                            events = {
                                mouseClick = async:callback(function()
                                    remove(text)
                                    set(value)
                                end),
                            },
                        },
                    }),
                },
            }),
        })
    end
    return {
        type = ui.TYPE.Flex,
        content = ui.content({
            header,
            body,
        }),
    }
end)

---@type { engineHandlers: table }
return {}
