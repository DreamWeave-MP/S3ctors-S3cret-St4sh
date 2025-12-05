local core = require 'openmw.core'
local util = require 'openmw.util'
local world = require 'openmw.world'

---@class MoveData
---@field x number
---@field y number
---@field z number
---@field yaw number

--- Evil, but who cares rn
local MoveScript = world.mwscript.getGlobalScript('P37Z_PlayerMove', world.players[1]).variables

return {
    eventHandlers = {
        P37Z_PlayerPosSync = function(moveData)
            MoveScript.moveX = moveData.x
            MoveScript.moveY = moveData.y
            MoveScript.moveZ = moveData.z
            MoveScript.zRot = moveData.yaw
        end,
        P37Z_ToggleMount = function(mountEnableInfo)
            local isMounted,
            position,
            owner =
                mountEnableInfo.isMounted,
                mountEnableInfo.position,
                mountEnableInfo.owner

            owner:teleport(
                mountEnableInfo.mount.cell,
                position,
                isMounted and
                util.transform.rotateZ(-mountEnableInfo.mount.rotation:getYaw())
                or nil
            )

            owner.type.activeEffects(owner):modify(isMounted and 1 or -1, core.magic.EFFECT_TYPE.Levitate)

            local value = isMounted and 1 or 0
            MoveScript.isMounted = value
        end,
    }
}
