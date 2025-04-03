---@module 'Scripts.S3.Doc.vector3.lua'

local async = require('openmw.async')
local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')

local I = require('openmw.interfaces')

--- @class ClimbMod
--- @field CLIMB_ACTIVATE_RANGE number The maximum range (in units) within which climbing can be activated.
--- @field CLIMB_SEARCH_STEP_RANGE number The step range (in units) used for searching for the top of climbable surfaces.

--- @class ClimbState
--- @field climbEngaged boolean Indicates whether the climbing state is currently active.
--- @field climbRisePos nil|util.vector3 The first stopping point during the climb, before moving forward. Nil if not climbing.
--- @field climbEndPos nil|util.vector3 The position where the climb ends. Nil if not climbing.
--- @field prevCamMode nil|number The previous camera mode before climbing was engaged. Nil if not climbing.

local ClimbMod = {
    CLIMB_ACTIVATE_RANGE = 64,
    CLIMB_SEARCH_STEP_RANGE = 2,
}

local ClimbState = {
    climbEngaged = false,
    climbRisePos = nil,
    climbEndPos = nil,
    prevCamMode = nil,
}

--- Engages the climbing mode by setting the climb state to active and
--- storing the starting and ending positions of the climb.
--- Both will be sent as inputs to a global function
---
--- @param risePos util.vector3 The starting position of the climb, typically a vector or coordinate.
--- @param endPos util.vector3 The ending position of the climb, typically a vector or coordinate.
function ClimbMod.engage(risePos, endPos)
    ClimbState.climbEngaged = true
    ClimbState.climbRisePos = risePos
    ClimbState.climbEndPos = endPos
    I.Controls.overrideMovementControls(true)
    I.Controls.overrideCombatControls(true)
    I.Controls.overrideUiControls(true)
    ClimbState.prevCamMode = camera.getMode()
    camera.setMode(camera.MODE.FirstPerson)
end

--- Disengages the climbing mode for the player.
---
--- This function resets the climbing state by setting `climbEngaged` to `false`
--- and clearing the positions (`climbRisePos` and `climbEndPos`) associated with
--- the climbing process.
---
--- Usage:
--- Call in an eventHandler when the player is no longer climbing
function ClimbMod.disengage()
    ClimbState.climbEngaged = false
    ClimbState.climbRisePos = nil
    ClimbState.climbEndPos = nil
    I.Controls.overrideMovementControls(false)
    I.Controls.overrideCombatControls(false)
    I.Controls.overrideUiControls(false)
    camera.setMode(ClimbState.prevCamMode or camera.MODE.ThirdPerson)
    ClimbState.prevCamMode = nil
end

--- Calculates the climbing range for the player based on their bounding box.
---
--- This function determines the center of the player's bounding box and a point
--- directly above it at a height equal to twice the bounding box's half-size along the z-axis.
---
--- @return number minHeight The center of the player's bounding box. Objects lower than this can't be climbed.
--- @return number topPoint Z position of player's center + 2X z halfSize. Objects higher than this can't be climbed.
function ClimbMod.climbRanges()
    local box = self:getBoundingBox()
    local height = box.halfSize.z * 2
    return box.center.z, box.center.z + height
end

input.registerTriggerHandler(
    "Jump",
    async:callback(function()
        -- Transform encompassing player's current Z Rotation
        local zTransform = util.transform.rotateZ(self.rotation:getYaw())
        local center = self:getBoundingBox().center
        -- Player's current position, rotated, CLIMB_ACTIVATE_RANGE units forward
        local scanPos = center + zTransform:apply(util.vector3(0, ClimbMod.CLIMB_ACTIVATE_RANGE, 0))
        -- You have to hit, at least at the waist
        -- If you hit at the waist, check to find the maximum height of the obstacle
        -- If between waist and max, climb is valid!

        local waistHit = nearby.castRay(
            center,
            scanPos,
            { ignore = { self } }
        )

        if not waistHit.hit then
            print("No hit detected at waist level.")
            return
        elseif not waistHit.hitObject then
                error("No hit object detected, but something was hit! Is the collisionType correct?")
        end

        print('\n', "Center is:", center, '\n', 'scanPos is:', scanPos, '\n', 'zTransform is', zTransform, '\n\n\n')

        local upwardHit

        print("Detected a hit! Object was: ", waistHit.hitObject)

        while true do
            -- Increment Z position of both start and end points
            center = center + util.vector3(0, 0, ClimbMod.CLIMB_SEARCH_STEP_RANGE)
            scanPos = scanPos + util.vector3(0, 0, ClimbMod.CLIMB_SEARCH_STEP_RANGE)

            -- Perform raycast at the new height
            local currentHit = nearby.castRay(
                center,
                scanPos,
                { ignore = { self } }
            )

            if not currentHit.hit then
                print("No hit detected at height:", center.z)
                break
            end

            print("Hit detected at height:", center.z, "Object was:", currentHit.hitObject)
            upwardHit = currentHit
        end

        if not upwardHit.hit then
            print("No upward hit detected.")
            return
        end

        local climbMin, climbMax = ClimbMod.climbRanges()

        -- In order to climb something, it must be at least waist high
        -- and within arm's length, eg a ledge
        if upwardHit.hitPos.z < climbMin or upwardHit.hitPos.z > climbMax then
            print("Hit object is too high or too low to climb.")
            return
        end

        -- Use the original position, bumped up a bit
        local firstStopPoint = util.vector3(upwardHit.hitPos.x, upwardHit.hitPos.y, upwardHit.hitPos.z + 5)
        print("Vertical destination is", upwardHit.hitObject, upwardHit.hitPos)

        -- Now, we have the first destination. We then need to determine the final destination, after moving forward once more
        local forwardVec = zTransform:apply(util.vector3(0, self:getBoundingBox().halfSize.y, 0))
        local finalStopPoint = firstStopPoint + forwardVec

        local finalHit = nearby.castRay(
            firstStopPoint,
            finalStopPoint,
            { ignore = { self } }
        )

        -- If we didn't actually hit anything, then just move to the final position
        -- Otherwise, use the collision point as our destination
        -- Mind the player's z pos refers to their feet
        local finalDestination
        if finalHit.hit then
            finalDestination = finalHit.hitPos
            print("No hit detected at final destination.")
        else
            finalDestination = finalStopPoint
            print("Hit detected at final destination:", upwardHit.hitObject)
        end

        print("Final destination is", finalDestination)
        ClimbMod.engage(firstStopPoint, finalDestination)

        core.sendGlobalEvent('S3_ChimClimb_ClimbStart', {
            target = self.object,
            startPos = firstStopPoint,
            endPos = finalDestination,
        })
    end)
)

return {
    engineHandlers = {
        onFrame = function(dt)
            if ClimbState.climbEngaged then
                self.controls.jump = false
                if camera.getMode() ~= camera.MODE.FirstPerson then
                    camera.setMode(camera.MODE.FirstPerson)
                end
            end
        end,
        onSave = function()
            return ClimbState
        end,
        onLoad = function(data)
            ClimbState = data or {
                climbEngaged = false,
                climbRisePos = nil,
                climbEndPos = nil,
                prevCamMode = nil,
            }
        end,
    },
    eventHandlers = {
        S3_ChimClimb_ClimbEnd = ClimbMod.disengage
    },
}
