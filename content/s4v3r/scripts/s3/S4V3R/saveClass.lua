---@omw-context none

---@alias SaveClass
---| 1
---| 2
---| 3
---| 4
---| 5
---| 6

---@class SaveClasses
---@field AUTO 1
---@field COMBAT_START 2
---@field COMBAT_END 3
---@field GAME_START 4
---@field REST 5
---@field CELL_CHANGE 6
local SaveClass = {
  AUTO = 1,
  COMBAT_START = 2,
  COMBAT_END = 3,
  GAME_START = 4,
  REST = 5,
  CELL_CHANGE = 6,
}

return SaveClass
