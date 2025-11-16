local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

---@class WeaponIndicatorConstructor
---@field Constants H4NDConstants
---@field enchantFrameVisible boolean
---@field durabilityColor util.color
---@field weaponIcon string
---@field weaponHealth number
---@field barSize util.vector2

---@param constructor WeaponIndicatorConstructor
return function(constructor)
    local Attrs, Vectors = constructor.Constants.Attrs, constructor.Constants.Vectors

    return ui.create {
        type = ui.TYPE.Flex,
        name = 'WeaponIndicator',
        props = {
            relativePosition = Attrs.Weapon(),
            anchor = util.vector2(.5, 1),
            autoSize = false,
            relativeSize = util.vector2(.2, .2),
        },
        content = ui.content {
            {
                name = 'WeaponIconBox',
                template = I.MWUI.templates.borders,
                props = {
                    relativeSize = constructor.Constants.Attrs.IndicatorSize(),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        name = 'WeaponBackground',
                        props = {
                            resource = ui.texture { path = 'white' },
                            relativeSize = constructor.Constants.Vectors.BottomRight,
                            color = constructor.Constants.Colors.Black,
                            alpha = 0.5,
                        },
                    },
                    {
                        type = ui.TYPE.Image,
                        name = 'EnchantFrame',
                        props = {
                            resource = ui.texture {
                                path = 'textures/menu_icon_magic_equip.dds',
                                offset = util.vector2(2, 2),
                                size = util.vector2(40, 40)
                            },
                            relativeSize = Vectors.BottomRight,
                            visible = constructor.enchantFrameVisible,
                        }
                    },
                    {
                        type = ui.TYPE.Image,
                        name = 'WeaponIcon',
                        props = {
                            resource = ui.texture { path = constructor.weaponIcon },
                            relativeSize = Vectors.BottomRight,
                        }
                    },
                }
            },
            {
                name = 'DurabilityBarContainer',
                template = I.MWUI.templates.borders,
                props = {
                    relativeSize = constructor.Constants.Attrs.BarContainer(),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        name = 'DurabilityBarBackground',
                        props = {
                            resource = ui.texture { path = 'white' },
                            relativeSize = constructor.Constants.Vectors.BottomRight,
                            color = constructor.Constants.Colors.Black,
                            alpha = 0.5,
                        },
                    },
                    {
                        type = ui.TYPE.Image,
                        name = 'DurabilityBar',
                        props = {
                            resource = ui.texture { path = 'white' },
                            relativeSize = util.vector2(constructor.weaponHealth, 1),
                            color = constructor.durabilityColor,
                        },
                    },
                }
            },
        }
    }
end
