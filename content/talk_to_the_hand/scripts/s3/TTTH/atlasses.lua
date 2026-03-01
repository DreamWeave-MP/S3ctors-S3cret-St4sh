local I = require 'openmw.interfaces'

---@param Constants H4NDConstants
---@param getColorForElement function
---@return ImageAtlas, ImageAtlas, ImageAtlas
return function(Constants, getColorForElement)
    local PinkyAtlas = I.S3AtlasConstructor.constructAtlas {
        tileSize = Constants.Vectors.Tiles.Pinky,
        tilesPerRow = 10,
        totalTiles = 100,
        atlasPath = 'textures/s3/ttth/tribunalpinky.dds'
    }

    local MiddleAtlas = I.S3AtlasConstructor.constructAtlas {
        tileSize = Constants.Vectors.Tiles.Middle,
        tilesPerRow = 10,
        totalTiles = 100,
        atlasPath = 'textures/s3/ttth/tribunalmiddle.dds'
    }

    local ThumbAtlas = I.S3AtlasConstructor.constructAtlas {
        tileSize = Constants.Vectors.Tiles.Thumb,
        tilesPerRow = 10,
        totalTiles = 100,
        atlasPath = 'textures/s3/ttth/tribunalthumb.dds'
    }

    local ThumbSize, ThumbPos = Constants.Attrs.Thumb()
    ThumbAtlas:spawn {
        color = getColorForElement('Thumb'),
        name = 'Thumb',
        size = Constants.Vectors.Zero,
        relativeSize = ThumbSize,
        relativePosition = ThumbPos,
        anchor = Constants.Vectors.BottomLeft,
    }

    local middleSize, middlePos = Constants.Attrs.Middle()
    MiddleAtlas:spawn {
        color = getColorForElement('Middle'),
        name = 'Middle',
        relativeSize = middleSize,
        size = Constants.Vectors.Zero,
        relativePosition = middlePos,
        anchor = Constants.Vectors.BottomLeft,
    }

    local pinkySize, pinkyPos = Constants.Attrs.Pinky()
    PinkyAtlas:spawn {
        color = getColorForElement('Pinky'),
        name = 'Pinky',
        relativeSize = pinkySize,
        size = Constants.Vectors.Zero,
        relativePosition = pinkyPos,
        anchor = Constants.Vectors.BottomLeft,
    }

    return ThumbAtlas, MiddleAtlas, PinkyAtlas
end
