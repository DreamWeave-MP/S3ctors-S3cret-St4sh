local ui = require 'openmw.ui'
local util = require 'openmw.util'

---@class WeaponIndicatorConstructor
---@field handSize util.vector2
---@field Constants H4NDConstants
---@field enchantFrameVisible boolean
---@field durabilityColor util.color
---@field weaponIcon string
---@field weaponHealth number
---@field barSize util.vector2

---@param constructor WeaponIndicatorConstructor
return function(constructor)
    local Attrs, Vectors, handSize = constructor.Constants.Attrs, constructor.Constants.Vectors, constructor.handSize

    return ui.create {
        type = ui.TYPE.Flex,
        name = 'WeaponIndicator',
        props = {
            position = Attrs.Weapon(handSize),
        },
        content = ui.content {
            {
                name = 'WeaponIconBox',
                props = {
                    size = Attrs.SubIcon(handSize),
                },
                content = ui.content {
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
                type = ui.TYPE.Image,
                name = 'DurabilityBar',
                props = {
                    resource = ui.texture { path = 'white' },
                    size = util.vector2(constructor.weaponHealth * constructor.barSize.x, constructor.barSize.y),
                    color = constructor.durabilityColor,
                },
            },
        }
    }
end
