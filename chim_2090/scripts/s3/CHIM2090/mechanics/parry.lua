local anim = require 'openmw.animation'
local types = require 'openmw.types'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local function getShield()
    local carriedLeft = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft)
    if not carriedLeft or not types.Armor.records[carriedLeft.recordId] then return end
    return carriedLeft
end

local blockEndAnimData = {
    startKey = 'block hit',
    stopKey = 'block stop',
    priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted,
    },
    blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso,
}

local function playBlockEndAnim()
    I.AnimationController.playBlendedAnimation('shield', blockEndAnimData)
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

function Parry.timeRemaining()
    return Parry.state.remainingTime
end

function Parry.calculateParryFrames()
    local blockSkill = math.min(s3lf.block.base, 100) / 100                -- 0.0 to 1.0
    local agilityBonus = (math.min(s3lf.agility.modified, 100) - 50) / 200 -- -0.25 to +0.25
    local luckInfluence = (math.random(10) - 5) / 50                       -- -0.1 to +0.1 variance

    local shield = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedLeft)
    local shieldWeight = types.Armor.records[shield.recordId].weight

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
    if Parry.state.remainingTime <= 0 then return end
    Parry.state.remainingTime = math.max(0.0, Parry.state.remainingTime - dt)
end

function Parry.start()
    Parry.state.remainingTime = Parry.calculateParryFrameSeconds()
end

---@return boolean parryReady whether or not a parry can currently happen
function Parry.ready()
    return Parry.state.remainingTime > 0
end

---@return number shieldSize overall length of the equipped shield's front face in todd units
function Parry.getShieldSize()
    local shield = getShield()
    if not shield then return 0 end
    return (shield:getBoundingBox().halfSize.xy * 2):length()
end

---@param hitData CHIMBlockData
function Parry.getDamage(hitData)
    local incomingDamage = hitData.damage

    if not incomingDamage or incomingDamage <= 0 then
        return 0
    end

    I.s3ChimBlock.handleBlockHit(hitData)

    playBlockEndAnim()

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
    engineHandlers = {
        onFrame = function(dt)
            Parry.tick(dt)
        end,
    },
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
                    local shield = getShield()
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

return ParryInterface
