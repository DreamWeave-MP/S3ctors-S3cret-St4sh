local animation = require 'openmw.animation'
local core = require 'openmw.core'
local self = require 'openmw.self'
local types = require 'openmw.types'

---@alias AttackType integer

---@class CHIMBlockData
---@field damage number
---@field hitPos util.vector3
---@field playVfx true?
---@field type AttackType
---@field weapon GameObject
---@field attackStrength number
---@field applyDurabilityDamage boolean

local isPlayer, ui = types.Player.objectIsInstance(self)
if isPlayer then
    ui = require 'openmw.ui'
end

local I = require 'openmw.interfaces'
local Combat = I.Combat

local Fatigue = self.type.stats.dynamic.fatigue(self)
local damageTypes = { 'health', 'fatigue', 'magicka' }
local function CHIMHitHandler(attack)
    local attacker = attack.attacker
    local meleeOrRanged = attack.sourceType == Combat.ATTACK_SOURCE_TYPES.Melee
        or attack.sourceType == Combat.ATTACK_SOURCE_TYPES.Ranged

    -- Since hits caused by parries will be sent here,
    -- potentially without an attacker?
    -- maybe we don't actually want to do this
    if not attacker or not meleeOrRanged then return end

    if not attack.successful then
        return attacker:sendEvent('CHIMEnsureFortifyAttack')
    end

    local shieldMultiplier = 1.0
    if isPlayer then
        ---@type CHIMBlockData
        local blockData = {
            damage = attack.damage.health or attack.damage.fatigue,
            hitPos = attack.hitPos, -- For now we'll assume these always exist but that won't necessarily be the case!
            type = attack.type or self.ATTACK_TYPE.Thrust,
            weapon = attack.weapon,
            attackStrength = attack.strength,
            applyDurabilityDamage = true,
        }

        if I.s3ChimParry.Manager.ready() then
            blockData.applyDurabilityDamage = false
            attacker:sendEvent('CHIMOnParry', {
                damage = I.s3ChimParry.Manager.getDamage(blockData),
            })

            ui.showMessage('Attack parried!')
            return false
        elseif I.s3ChimBlock.isBlocking then
            blockData.playVfx = true
            local blockResult = I.s3ChimBlock.Manager.handleHit(blockData)
            shieldMultiplier = blockResult.damageMult
        end
    end

    --- We should also have some way to determine if an attack fumbled or not
    --- and use that data to remove enchantments when appropriate
    local damageMult = I.s3ChimCore.Manager:getDamageBonus {
        attacker = attack.attacker,
        defender = self.object,
        attackInfo = attack
    }

    local poiseMult = I.s3ChimPoise.onHit(attack)
    local endMult = damageMult
        * shieldMultiplier
        * poiseMult
        * I.s3ChimCore.Manager.GlobalDamageScaling

    for _, damageType in ipairs(damageTypes) do
        if attack.damage[damageType] ~= nil then
            attack.damage[damageType] = attack.damage[damageType] * endMult
        end
    end

    I.s3ChimCore.debugLog(([[Health Damage: %.2f
    Fatigue Damage: %.2f
    Shield Multiplier: %.2f
    Global Damage Scaling: %.2f
    Poise Damage Bonus: %.1f]]):format(
        attack.damage.health or 0,
        attack.damage.fatigue or 0,
        shieldMultiplier,
        I.s3ChimCore.Manager.GlobalDamageScaling,
        poiseMult
    ))
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
