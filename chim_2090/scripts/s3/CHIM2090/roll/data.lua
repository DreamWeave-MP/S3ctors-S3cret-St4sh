local RollDirection = {
    FORWARD = 1,
    RIGHT = 2,
    BACK = 3,
    LEFT = 4,
}

local RollType = {
    FAT = 1,
    NORMAL = 2,
    FAST = 3,
}

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

return {
    DIRECTION = RollDirection,
    TYPE = RollType,
    groups = RollInfo,
    list = RollList,
}
