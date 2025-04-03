local util = require('openmw.util')

local ClimbQueue = {}

local ZHeightBuffer = 10

---@class GameObject userdata
---@field position util.vector3
---@field getBoundingBox function(): userdata



--- Calculates a buffered position for a given object by adjusting its Z-coordinate.
--- The buffered position is determined by adding the half-size of the object's bounding box
--- along the Z-axis to the object's current position.
---
--- @param object GameObject The object for which the buffered position is calculated.
---                      It is expected to have a `position` property (a vector3 with x, y, z fields)
---                      and a `getBoundingBox` method that returns a bounding box with a `halfSize.z` field.
--- @return util.vector3 vector3 table representing the buffered position with adjusted Z-coordinate.
local function BufferedPosition(object)
    local vector = object.position
    return util.vector3(vector.x, vector.y, vector.z + object:getBoundingBox().halfSize.z)
end

--- Helper function to handle movement logic
--- @param target table The target object to move.
--- @param targetPos util.vector3 The target position to move toward.
--- @param dt number Delta time for the frame.
--- @return boolean True if the target was moved, false if the movement is complete.
local function moveTargetTowards(target, targetPos, dt)
    local moveDistance = (targetPos - target.position) * dt
    if moveDistance:length() > 0.1 then
        target:teleport(target.cell, target.position + moveDistance)
        return true
    end
    return false
end

--- Handles the per-frame climbing logic for a target.
--- This function moves the target towards specified positions (startPos or endPos) 
--- and updates the climbing state accordingly. If the target reaches the end of 
--- the climb, it sends a climb end event and clears the climb queue for the target.
---
--- @param dt number The delta time since the last frame, used to calculate movement.
--- @param target table The entity that is performing the climb.
--- @param targetPositions table A table containing the positions for the climb:
---                              - `startPos`: The starting position of the climb.
---                              - `endPos`: The ending position of the climb.
---
--- The function performs the following steps:
--- 1. If `startPos` exists, it moves the target towards it. Once reached, `startPos` is cleared.
--- 2. If `startPos` is nil and `endPos` exists, it moves the target towards `endPos`. 
---    Once reached, the target is teleported to a buffered position, and `endPos` is cleared.
--- 3. If both `startPos` and `endPos` are nil, it sends a climb end event and removes 
---    the target from the climb queue.
local function handlePerFrameClimb(dt, target, targetPositions)
    if targetPositions.startPos then
        if not moveTargetTowards(target, targetPositions.startPos, dt) then
            ClimbQueue[target].startPos = nil
        end
    elseif targetPositions.endPos then
        if not moveTargetTowards(target, targetPositions.endPos, dt) then
            target:teleport(target.cell, BufferedPosition(target), { onGround = true })
            ClimbQueue[target].endPos = nil
        end
    else
        target:sendEvent('S3_ChimClimb_ClimbEnd')
        ClimbQueue[target] = nil
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            for player, positions in pairs(ClimbQueue) do
                handlePerFrameClimb(dt, player, positions)
            end
        end,
    },
    eventHandlers = {
        S3_ChimClimb_ClimbStart = function(climbData)
            local queuedClimber = ClimbQueue[climbData.target]
            if not queuedClimber then
                ClimbQueue[climbData.target] = {
                    startPos = climbData.startPos,
                    endPos = climbData.endPos,
                }
            end
        end,
    }
}
