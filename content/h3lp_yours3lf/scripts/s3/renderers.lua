local async = require('openmw.async')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local markTexture = ui.texture({ path = 'textures/menu_map_smark.dds' })

I.Settings.registerRenderer('ScreenPosition', function(value, set)
    local buttonSize = util.vector2(20, 20)
    local containerSize = util.vector2(50, 50)
    local update = async:callback(function(event)
        if event.button ~= 1 then return end
        local relativeOffset = (event.offset - buttonSize / 2):ediv(containerSize)
        local clampedOffset = util.vector2(
            util.clamp(relativeOffset.x, 0, 1),
            util.clamp(relativeOffset.y, 0, 1))
        set(clampedOffset)
    end)

    return {
        template = I.MWUI.templates.box,
        content = ui.content({
            {
                props = {
                    size = containerSize + buttonSize,
                },
                content = ui.content({
                    {
                        template = I.MWUI.templates.borders,
                        props = {
                            anchor = value,
                            relativePosition = value,
                            size = buttonSize,
                        },
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
                    },
                }),
                events = {
                    mouseMove = update,
                    mousePress = update,
                },
            },
        }),
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
