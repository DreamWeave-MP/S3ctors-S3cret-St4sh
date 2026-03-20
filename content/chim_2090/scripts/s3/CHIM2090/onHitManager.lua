local animation = require 'openmw.animation'

---@alias AttackType integer

---@class CHIMBlockData
---@field attacker GameObject?
---@field damage number
---@field hitPos util.vector3
---@field playVfx true?
---@field type AttackType
---@field weapon GameObject
---@field attackStrength number
---@field applyDurabilityDamage boolean

local gameSelf = require 'openmw.self'
local I = require 'openmw.interfaces'

local s3lf, Combat, Core = I.s3.lf, I.Combat, I.s3ChimCore; local Fatigue = s3lf.fatigue

local DefaultAttack = s3lf.ATTACK_TYPE.Thrust

local function CHIMHitHandler(attack)
    local attacker = attack.attacker
    local meleeOrRanged = attack.sourceType == Combat.ATTACK_SOURCE_TYPES.Melee
        or attack.sourceType == Combat.ATTACK_SOURCE_TYPES.Ranged

    -- Since hits caused by parries will be sent here,
    -- potentially without an attacker?
    -- maybe we don't actually want to do this
    if not attacker or not meleeOrRanged then return end

    s3lf:sendEvent('CHIMEnsureStats')
    attacker:sendEvent('CHIMEnsureStats')

    if not attack.successful then
        return attacker:sendEvent('CHIMEnsureFortifyAttack')
    end

    if I.s3ChimRoll and I.s3ChimRoll.hasIFrames then
        return false
    end

    local shieldMultiplier, didBlock = 1.0, false
    local canBlock, flankMult = I.s3ChimBlock.Manager.canBlockAtAngle(attack.attacker, gameSelf)

    if canBlock then
        ---@type CHIMBlockData
        local blockData = {
            damage = attack.damage.health or attack.damage.fatigue,
            hitPos = attack.hitPos, -- For now we'll assume these always exist but that won't necessarily be the case!
            type = attack.type or DefaultAttack,
            weapon = attack.weapon,
            attackStrength = attack.strength,
            applyDurabilityDamage = true,
            attacker = attack.attacker,
        }

        if I.s3ChimParry.Manager.ready() then
            blockData.applyDurabilityDamage = false
            attacker:sendEvent('CHIMOnParry', {
                damage = I.s3ChimParry.Manager.getDamage(blockData),
            })

            if I.S3LockOn then s3lf:sendEvent('S3TargetLockHit', attacker) end

            return false
        elseif I.s3ChimBlock.isBlocking then
            local blockResult = I.s3ChimBlock.Manager.handleHit(blockData)
            shieldMultiplier = blockResult.damageMult
            attack.hitPos = nil
            didBlock = true
        end
    end

    --- We should also have some way to determine if an attack fumbled or not
    --- and use that data to remove enchantments when appropriate
    local damageMult = Core.Manager:getDamageBonus {
        attacker = attack.attacker,
        defender = gameSelf.object,
        attackInfo = attack
    }

    local poiseMult = I.s3ChimPoise.onHit(attack)
    local endMult = damageMult
        * shieldMultiplier
        * poiseMult
        * I.s3ChimCore.Manager.GlobalDamageScaling

    if
        I.s3ChimCore.EnableFlankDamage
        and not didBlock
        and flankMult >= 0.333333333333
        and s3lf.canMove()
    then
        endMult = endMult + flankMult
    end

    if attack.damage.health ~= nil then
        attack.damage.health = attack.damage.health * endMult
    end

    if attack.damage.magicka ~= nil then
        attack.damage.magicka = attack.damage.magicka * endMult
    end

    if attack.damage.fatigue ~= nil then
        attack.damage.fatigue = attack.damage.fatigue * endMult
    end

    if Core.DebugEnable then
        Core.debugLog(
            (
                [[Health Damage: %.2f
    Fatigue Damage: %.2f
    Shield Multiplier: %.2f
    Hit Chance Mult: %.2f
    Global Damage Scaling: %.2f
    Poise Damage Bonus: %.1f
    Flank Mult: %.3f
    Final Damage Mult: %.2f]]
            ):format(
                attack.damage.health or 0,
                attack.damage.fatigue or 0,
                shieldMultiplier,
                damageMult,
                I.s3ChimCore.Manager.GlobalDamageScaling,
                poiseMult,
                flankMult,
                endMult
            )
        )
    end
end

Combat.addOnHitHandler(CHIMHitHandler)

return {
    eventHandlers = {
        CHIMOnParry = function(parryData)
            Fatigue.current = Fatigue.current - parryData.damage

            if Fatigue.current > 0 then
                I.AnimationController.playBlendedAnimation(
                    I.s3ChimCore.getRandomHitGroup(),
                    {
                        priority = animation.PRIORITY.Scripted,
                        speed = I.s3ChimCore.getHitAnimationSpeed()
                    }
                )
            end
        end,
    }
}
