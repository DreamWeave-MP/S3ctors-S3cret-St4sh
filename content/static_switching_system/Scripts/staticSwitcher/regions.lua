---@omw-context global

local types = require 'openmw.types'

local Door = types.Door

local ipairs = ipairs

---@type table<string, SSSExteriorDoor[]>
local ExteriorDoorsByCell = {}

--- The doors are cached, not the answer: an interior with exits into different regions
--- belongs to whichever is nearest to the position asked about.
---@param cell openmw.core.GCell
---@return SSSExteriorDoor[] exteriorDoors
local function getExteriorDoors(cell)
  local exteriorDoors = ExteriorDoorsByCell[cell.id]
  if exteriorDoors then return exteriorDoors end

  exteriorDoors = {}

  for _, door in ipairs(cell:getAll(types.Door)) do
    if Door.isTeleport(door) then
      local destination = Door.destCell(door)

      if destination and destination.isExterior then
        exteriorDoors[#exteriorDoors + 1] = {
          position = door.position,
          region = destination.region,
        }
      end
    end
  end

  ExteriorDoorsByCell[cell.id] = exteriorDoors
  return exteriorDoors
end

--- An interior has no region of its own; it takes the region of the exterior cell behind
--- its nearest teleport door.
---@param cell openmw.core.GCell
---@param position openmw.util.Vector3
---@return string? region
local function getExteriorRegionFromDoor(cell, position)
  local exteriorDoors = getExteriorDoors(cell)
  local nearestRegion
  local nearestDistSq = math.huge

  for doorIdx = 1, #exteriorDoors do
    local exteriorDoor = exteriorDoors[doorIdx]
    local distSq = (position - exteriorDoor.position):length2()

    if distSq < nearestDistSq then
      nearestDistSq = distSq
      nearestRegion = exteriorDoor.region
    end
  end

  return nearestRegion
end

---@param cell openmw.core.GCell
---@param position openmw.util.Vector3 where in the cell to measure door distance from
---@return string? region
local function resolveRegion(cell, position)
  local region = cell.region
  if region or cell.isExterior then return region end

  return getExteriorRegionFromDoor(cell, position)
end

return { resolveRegion = resolveRegion }
