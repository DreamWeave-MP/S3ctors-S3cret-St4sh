local I = require 'openmw.interfaces'

---@param Constants H4NDConstants
---@param handSize util.vector2
---@param getColorForElement function
return function(Constants, handSize, getColorForElement)
    print(Constants, handSize, getColorForElement)

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

    local ThumbSize, ThumbPos = Constants.Attrs.Thumb(handSize)
    ThumbAtlas:spawn {
        color = getColorForElement('Thumb'),
        name = 'Thumb',
        size = ThumbSize,
        position = ThumbPos,
    }

    local middleSize, middlePos = Constants.Attrs.Middle(handSize)
    MiddleAtlas:spawn {
        color = getColorForElement('Middle'),
        name = 'Middle',
        size = middleSize,
        position = middlePos,
    }

    local pinkySize, pinkyPos = Constants.Attrs.Pinky(handSize)
    PinkyAtlas:spawn {
        color = getColorForElement('Pinky'),
        name = 'Pinky',
        size = pinkySize,
        position = pinkyPos,
    }

    return ThumbAtlas, MiddleAtlas, PinkyAtlas
end
