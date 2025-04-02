local util = require('openmw.util')

local ClimbQueue = {}

local ZHeightBuffer = 10

local function BufferedPosition(object)
    local vector = object.position
    return util.vector3(vector.x, vector.y, vector.z + object:getBoundingBox().halfSize.z)
end

local function handlePerFrameClimb(dt, target, targetPositions)
    local moveDistance
    if targetPositions.startPos then
        moveDistance = (targetPositions.startPos - target.position) * dt

        if moveDistance:length() > 0.1 then
            target:teleport(target.cell, target.position + moveDistance)
        else
            ClimbQueue[target].startPos = nil
        end
    elseif targetPositions.endPos then
        moveDistance = (targetPositions.endPos - target.position) * dt

        if moveDistance:length() > 0.1 then
            target:teleport(target.cell, target.position + moveDistance)
        else
            target:teleport(target.cell, BufferedPosition(target))
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
