local anim = require 'openmw.animation'
local core = require 'openmw.core'
local types = require 'openmw.types'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local blockEndAnimData = {
    startKey = 'parry start',
    stopKey = 'parry stop',
    priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted
    },
}

local function usingTwoHanded()
    local Core = I.s3ChimCore
    return Core.getWeaponHandedness() == Core.Handedness.TWO
end

local groupName = 'SettingsGlobal' .. modInfo.name .. 'Parry'
---@type ProtectedTableInterface
local ProtectedTable = I.S3ProtectedTable

local FRAME_DURATION = 1.0 / 60.0
---@class ParryManager: ProtectedTable
---@field BaseParryFrames integer
---@field BaseShieldFrames integer
---@field BlockFrameMult integer
---@field MaxParryFrames integer
---@field MinParryFrames integer
---@field PerUnitShieldWeightPenalty integer
---@field BaseDamageMultiplier number
---@field ShieldSizeInfluence number
---@field StrengthDamageBonus number
---@field BlockSkillBonus number
---@field MinDamageMultiplier number
---@field MaxDamageMultiplier number
local Parry = ProtectedTable.new { inputGroupName = groupName, logPrefix = '[CHIMParry]:\n' }
Parry.state = {
    remainingTime = 0,
}

function Parry.playParryAnim()
    local animGroup = I.s3ChimBlock.getBlockType()
    s3lf.cancel(animGroup)

    local blendMask, weaponArmPriority = anim.BLEND_MASK.LeftArm, nil
    if not I.s3ChimBlock.usingShield then
        blendMask = blendMask + anim.BLEND_MASK.RightArm
        weaponArmPriority = anim.PRIORITY.Scripted
    end

    blockEndAnimData.blendMask = blendMask
    blockEndAnimData.priority[anim.BONE_GROUP.RightArm] = weaponArmPriority

    I.AnimationController.playBlendedAnimation(animGroup, blockEndAnimData)
end

function Parry.timeRemaining()
    return Parry.state.remainingTime
end

function Parry.calculateParryFrames()
    local blockSkill = math.min(s3lf.block.base, 100) / 100                -- 0.0 to 1.0
    local agilityBonus = (math.min(s3lf.agility.modified, 100) - 50) / 200 -- -0.25 to +0.25
    local luckInfluence = (math.random(10) - 5) / 50                       -- -0.1 to +0.1 variance

    local shield = I.s3ChimBlock.getBlockingItem()
    if not shield then return 0 end
    local shieldWeight = shield.type.records[shield.recordId].weight

    -- INVERSE relationship: lighter shields = more parry frames
    -- Heaviest shields get minimal frames, lightest get bonus frames
    local shieldFrames = math.max(0,
        Parry.BaseShieldFrames -
        math.floor(shieldWeight / Parry.PerUnitShieldWeightPenalty)
    )

    local totalFrames = Parry.BaseParryFrames
        + (blockSkill * Parry.BlockFrameMult) -- Skill adds 0-3 frames
        + agilityBonus                        -- Agility adds ±2.5 frames
        + luckInfluence                       -- Small random factor ±0.1 frames
        + shieldFrames                        -- Equipment-based frames (inverse to weight)

    totalFrames = math.floor(totalFrames + .5)

    Parry.debugLog(
        ([[Agility bonus: %s
Luck Influence: %s
shield Frames: %s
Base Parry Frames: %s
block influence: %s
Total parry frames: %s
            ]]):format(
            agilityBonus,
            luckInfluence,
            shieldFrames,
            Parry.BaseParryFrames,
            blockSkill * Parry.BlockFrameMult,
            totalFrames
        )
    )

    return util.clamp(
        totalFrames,
        Parry.MinParryFrames,
        Parry.MaxParryFrames
    )
end

function Parry.calculateParryFrameSeconds()
    return Parry.calculateParryFrames() * FRAME_DURATION
end

function Parry.tick(dt)
    if
        core.isWorldPaused()
        or Parry.state.remainingTime <= 0
        or usingTwoHanded()
    then
        return
    end

    Parry.state.remainingTime = math.max(0.0, Parry.state.remainingTime - dt)
end

function Parry.start()
    if usingTwoHanded() then return end

    Parry.state.remainingTime = Parry.calculateParryFrameSeconds()
end

---@return boolean parryReady whether or not a parry can currently happen
function Parry.ready()
    if usingTwoHanded() then return false end

    return Parry.state.remainingTime > 0
end

---@return number shieldSize overall length of the equipped shield's front face in todd units
function Parry.getShieldSize()
    local shield = I.s3ChimBlock.getBlockingItem()
    if not shield then return 0 end
    return (shield:getBoundingBox().halfSize.xy * 2):length()
end

---@param hitData CHIMBlockData
function Parry.getDamage(hitData)
    local incomingDamage = hitData.damage

    if not incomingDamage or incomingDamage <= 0 then
        return 0
    end

    I.s3ChimBlock.Manager.handleHit(hitData)

    Parry.playParryAnim()

    -- Calculate base multiplier with attributes
    local damageMult = Parry.BaseDamageMultiplier

    -- Strength bonus (stronger characters hit harder on parry)
    local strengthBonus = s3lf.strength.modified * Parry.StrengthDamageBonus
    damageMult = damageMult + strengthBonus

    -- Block skill bonus (skilled blockers know how to redirect force better)
    local blockBonus = s3lf.block.modified * Parry.BlockSkillBonus
    damageMult = damageMult + blockBonus

    -- Shield size influence (larger shields can redirect more force)
    local shieldBonus = Parry.getShieldSize() * Parry.ShieldSizeInfluence
    damageMult = damageMult + shieldBonus

    -- Clamp to reasonable bounds
    damageMult = util.clamp(damageMult, Parry.MinDamageMultiplier, Parry.MaxDamageMultiplier)

    local outgoingDamage = incomingDamage * damageMult

    Parry.debugLog(
        ("Parry: %.1f health damage -> %.1f fatigue damage (mult: %.2f)"):format(
            incomingDamage,
            outgoingDamage,
            damageMult
        )
    )

    return outgoingDamage
end

local ParryInterface = {
    engineHandlers = {},
    interfaceName = 's3ChimParry',
    interface = setmetatable(
        {},
        {
            __index = function(_, key)
                if key == 'help' then
                    return
                    [[The parry interface contains functions associated with the timing and damage calculations for shield-based parrying.
Each parameter in said calculations is exposed via the `Parry` settings page, or the settings group 'SettingsGlobalCHIM-2090Parry'.
Using these settings you may increase the parry windows for specific shields, based on character skill, or change the damage transferred back through a parry.]]
                elseif key == 'getParryTimes' then
                    local shield = I.s3ChimBlock.getBlockingItem()
                    if not shield then return 'No Shield equipped!' end

                    return ('Parry time in seconds: %.2f, in frames: %.2f, with shield: %s, whose size is %d units')
                        :format(
                            Parry.calculateParryFrameSeconds(),
                            Parry.calculateParryFrames(),
                            shield.recordId,
                            Parry.getShieldSize()
                        )
                elseif key == 'Manager' then
                    return Parry
                end
            end,
        }
    )
}

if types.Player.objectIsInstance(s3lf.gameObject) then
    ParryInterface.engineHandlers.onFrame = function(dt)
        Parry.tick(dt)
    end
else
    ParryInterface.engineHandlers.onUpdate = function(dt)
        Parry.tick(dt)
    end
end

return ParryInterface
