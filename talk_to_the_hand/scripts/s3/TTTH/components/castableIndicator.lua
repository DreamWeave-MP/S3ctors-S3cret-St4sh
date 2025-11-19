local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

---@class CastableConstructor
---@field barColor util.color
---@field castableIcon string?
---@field castableWidth number
---@field Constants H4NDConstants
---@field useDebug boolean
---@field dragEvents table<string, function>
---@field H4ND H4ND

---@param constructor CastableConstructor
return function(constructor)
    local Attrs,
    Colors,
    Vectors =
        constructor.Constants.Attrs,
        constructor.Constants.Colors,
        constructor.Constants.Vectors

    local width = constructor.H4ND.CastableIndicatorSize
    return ui.create {
        name = 'CastableIndicator',
        layer = 'Windows',
        props = {
            anchor = constructor.H4ND.CastableIndicatorAnchor,
            relativeSize = util.vector2(width, width * 1.125),
            relativePosition = constructor.H4ND.CastableIndicatorPos,
        },
        events = constructor.dragEvents,
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                name = 'CastableIndicator',
                props = {
                    autoSize = false,
                    relativeSize = Vectors.BottomRight,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        template = I.MWUI.templates.borders,
                        name = 'CastableIcon',
                        props = {
                            resource = ui.texture { path = constructor.castableIcon or 'white' },
                            relativeSize = Attrs.IndicatorSize(),
                            visible = true,
                            color = constructor.castableIcon == nil and Colors.Black or nil,
                            alpha = constructor.castableIcon ~= nil and 1.0 or .5,
                        },
                        external = {
                            grow = 1,
                            stretch = 1,
                        }
                    },
                    {
                        name = 'CastChanceContainer',
                        template = I.MWUI.templates.borders,
                        props = {
                            relativeSize = constructor.Constants.Attrs.BarContainer(),
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Image,
                                name = 'CastChanceBackground',
                                props = {
                                    resource = ui.texture { path = 'white' },
                                    relativeSize = Vectors.BottomRight,
                                    color = Colors.Black,
                                    alpha = 0.5,
                                },
                            },
                            {
                                type = ui.TYPE.Image,
                                name = 'CastChanceBar',
                                props = {
                                    resource = ui.texture { path = 'white' },
                                    relativeSize = util.vector2(constructor.castableWidth, 1),
                                    color = constructor.barColor,
                                },
                            },
                        }
                    },
                }
            },
            {
                name = 'DebugContent',
                props = {
                    visible = constructor.useDebug,
                    relativeSize = Vectors.BottomRight,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            relativeSize = Vectors.BottomRight,
                            alpha = .5,
                            resource = ui.texture { path = 'white', },
                            color = util.color.hex('00ffff'),
                        },
                    },
                    {
                        template = I.MWUI.templates.textHeader,
                        props = {
                            anchor = Vectors.Center,
                            relativePosition = Vectors.Center,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            text = 'Castable Container',
                        },
                    }
                }
            },
        }
    }
end
