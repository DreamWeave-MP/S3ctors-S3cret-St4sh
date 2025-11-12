local ui = require 'openmw.ui'
local util = require 'openmw.util'

---@class ImageAtlas
local ImageAtlas = {
    textureArray = {},
    element = nil,
    tileSize = util.vector2(0, 0),
    tilesPerRow = 0,
    totalTiles = 0,
    currentTile = 1,
}

---@param frameNum integer
function ImageAtlas:getCoordinates(frameNum)
    frameNum = frameNum - 1
    local row = frameNum % self.tilesPerRow
    local column = math.floor(frameNum / self.tilesPerRow)

    return util.vector2(self.tileSize.x * row, self.tileSize.y * column)
end

---@param nextOrPrev boolean
function ImageAtlas:getNextFrame(nextOrPrev)
    local currentTile = self.currentTile
    if nextOrPrev then
        if currentTile == self.totalTiles then
            currentTile = 1
        else
            currentTile = currentTile + 1
        end
    else
        if currentTile == 1 then
            currentTile = self.totalTiles
        else
            currentTile = currentTile - 1
        end
    end

    self.currentTile = currentTile

    return currentTile
end

function ImageAtlas:cycleFrame(nextOrPrev, update)
    local element = self.element
    assert(element)
    local props = element.layout.props

    local currentTile = self:getNextFrame(nextOrPrev)

    props.resource = self.textureArray[currentTile]

    element:update()
end

---@class AtlasSpawnerData
---@field layer string
---@field relativePosition util.vector2?
---@field name string?
---@field color util.color?
---@field visible boolean?
---@field alpha number?
---@field anchor util.vector2?
---@field size util.vector2?
---@field position util.vector2?
---@field relativeSize util.vector2?

---@param elementData AtlasSpawnerData
function ImageAtlas:spawn(elementData)
    self.element = ui.create {
        type = ui.TYPE.Image,
        layer = elementData.layer,
        name = elementData.name,
        props = {
            resource = self.textureArray[1],
            position = elementData.position,
            relativePosition = elementData.relativePosition,
            relativeSize = elementData.relativeSize,
            size = elementData.size or self.tileSize,
            color = elementData.color,
            anchor = elementData.anchor,
            alpha = elementData.alpha or 1.0,
            visible = elementData.visible or true,
        },
    }
end

function ImageAtlas:getElement()
    return self.element
end

---@class AtlasConstructorData
---@field totalTiles integer
---@field tilesPerRow integer
---@field atlasPath string
---@field tileSize util.vector2
---@field create boolean
---@field layer string?
---@field name string?

---@param atlasData AtlasConstructorData
local function constructAtlas(atlasData)
    ---@type ImageAtlas
    local copy = {}

    for k, v in pairs(ImageAtlas) do
        copy[k] = v
    end

    copy.tileSize = atlasData.tileSize
    copy.tilesPerRow = atlasData.tilesPerRow
    copy.totalTiles = atlasData.totalTiles
    copy.textureArray = {}

    for i = 1, copy.totalTiles do
        copy.textureArray[i] = ui.texture {
            path = atlasData.atlasPath,
            offset = copy:getCoordinates(i),
            size = copy.tileSize,
        }
    end

    return copy
end

return {
    interfaceName = 'S3AtlasConstructor',
    interface = {
        constructAtlas = constructAtlas,
    },
}
