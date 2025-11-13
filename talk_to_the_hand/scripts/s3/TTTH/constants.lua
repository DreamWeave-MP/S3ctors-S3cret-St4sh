local util = require 'openmw.util'

---@class H4NDConstants
return {
    Colors = {
        Black = util.color.hex('000000'),
    },
    Vectors = {
        BottomLeft = util.vector2(0, 1),
        BottomRight = util.vector2(1, 1),
        Center = util.vector2(.5, .5),
        LeftCenter = util.vector2(0, .5),
        Zero = util.vector2(0, 0),
        Tiles = {
            Pinky = util.vector2(128, 256),
            Middle = util.vector2(256, 512),
            Thumb = util.vector2(278, 271),
        },
        TopRight = util.vector2(1, 0),

    }
}
