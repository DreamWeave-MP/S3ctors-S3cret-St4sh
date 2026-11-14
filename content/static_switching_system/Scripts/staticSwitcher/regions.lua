---@omw-context global

local types = require 'openmw.types'

local Door = types.Door

local ipairs, type = ipairs, type

---@type table<string, string|true>
local InteriorRegions = {}

--- An interior has no region of its own; it takes the region of the exterior cell behind
--- its nearest teleport door.
---@param cell openmw.core.GCell
---@param position openmw.util.Vector3
---@return string? region
local function getExteriorRegionFromDoor(cell, position)
  local cached = InteriorRegions[cell.id]

  if cached then
    if type(cached) == 'string' then return cached end

    return
  end

  local nearestDoor
  local nearestDistSq = math.huge

  for _, door in ipairs(cell:getAll(types.Door)) do
    if Door.isTeleport(door) then
      local dest = Door.destCell(door)

      if dest and dest.isExterior then
        local distSq = (position - door.position):length2()

        if distSq < nearestDistSq then
          nearestDistSq = distSq
          nearestDoor = door
        end
      end
    end
  end

  if not nearestDoor then
    InteriorRegions[cell.id] = true

    return
  end

  local region = Door.destCell(nearestDoor).region

  InteriorRegions[cell.id] = region or true

  return region
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
