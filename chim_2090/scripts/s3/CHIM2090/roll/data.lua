---@enum RollDirection
local RollDirection = {
    FORWARD = 1,
    RIGHT = 2,
    BACK = 3,
    LEFT = 4,
}

---@enum RollType
local RollType = {
    FAT = 1,
    NORMAL = 2,
    FAST = 3,
}

---@alias RollMap table<RollType, string?>
---@alias RollDirectionMap table<RollDirection, RollMap>

---@type RollDirectionMap
local RollInfo = {
    [RollDirection.FORWARD] = {
        [RollType.FAT] = 'rollof',
        [RollType.NORMAL] = 'rollf',
        [RollType.FAST] = 'flipf',
    },
    [RollDirection.RIGHT] = {
        [RollType.FAT] = nil,
        [RollType.NORMAL] = 'dodger',
        [RollType.FAST] = 'dodger',
    },
    [RollDirection.BACK] = {
        [RollType.FAT] = 'backstepo',
        [RollType.NORMAL] = 'rollb',
        [RollType.FAST] = 'flipb',
    },
    [RollDirection.LEFT] = {
        [RollType.FAT] = nil,
        [RollType.NORMAL] = 'dodgel',
        [RollType.FAST] = 'dodgel',
    },
}

---@type string[]
local RollList = {
    'dodgel',
    'dodger',
    'rollf',
    'rollb',
    'flipf',
    'flipb',
    'backstep',
    'backstepo',
    'rollof',
}

---@class RollInfo
---@field TYPE table<string, RollType>
---@field DIRECTION table<string, RollDirection>
---@field groups RollDirectionMap
---@field list string[]
return require 'openmw.util'.makeStrictReadOnly {
    DIRECTION = RollDirection,
    TYPE = RollType,
    groups = RollInfo,
    list = RollList,
}
