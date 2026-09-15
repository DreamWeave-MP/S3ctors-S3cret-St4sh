---@omw-context player

local self = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local visited = {}
local currentCellId
local currentCellName = 'Nowhere'
local root

local function checkCell()
  local cell = self.cell
  if not cell or cell.id == currentCellId then return end

  currentCellId = cell.id
  currentCellName = cell.name
  visited[currentCellId] = true
end

local function makeLayout(visitedCount)
  return {
    type = ui.TYPE.Window,
    layer = 'Windows',
    props = {
      title = 'Cell Greeter',
      position = util.vector2(80, 80),
      size = util.vector2(360, 90),
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        props = {
          text = ('%s — %d cell%s visited'):format(
            currentCellName,
            visitedCount,
            visitedCount == 1 and '' or 's'
          ),
        },
      },
    },
  }
end

local function showJournal()
  checkCell()

  local visitedCount = 0
  for _ in pairs(visited) do
    visitedCount = visitedCount + 1
  end

  if root then root:destroy() end
  root = ui.create(makeLayout(visitedCount))
end

return {
  engineHandlers = {
    onUpdate = checkCell,

    onKeyPress = function(key)
      if key.symbol == 'x' then showJournal() end
    end,

    onSave = function()
      return {
        visited = visited,
      }
    end,

    onLoad = function(data)
      visited = data and data.visited or {}
      currentCellId = nil
      currentCellName = 'Nowhere'
      if root then root:destroy() end
      root = nil
    end,
  },
}
