local animation = require 'openmw.animation'
local core = require 'openmw.core'
local self = require 'openmw.self'
local types = require 'openmw.types'

local isPlayer, ui = types.Player.objectIsInstance(self)
if isPlayer then
    ui = require 'openmw.ui'
end

--- https://gitlab.com/OpenMW/openmw/-/merge_requests/4334
--- https://gitlab.com/OpenMW/openmw/-/blob/96d0d1fa7cd83e41853061cca68f612b7eb9c834/CMakeLists.txt#L85
local onHitAPIRevision = 85
if core.API_REVISION < onHitAPIRevision then
    error 'CHIM-2090 requires openmw 0.50 and later! Sorry :('
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

    if isPlayer then
        local incomingDamage = attack.damage.health or attack.damage.fatigue
        if I.s3ChimParry.Manager.ready() then
            local outgoingDamage = I.s3ChimParry.Manager.getDamage {
                damage = incomingDamage,
                hitPos = attack.hitPos, -- For now we'll assume these always exist but that won't necessarily be the case!
            }

            attacker:sendEvent('CHIMOnParry', {
                damage = outgoingDamage,
            })

            ui.showMessage('Attack parried!')
            return false
        elseif I.s3ChimBlock.isBlocking() then
            I.s3ChimBlock.handleBlockHit {
                damage = incomingDamage,
                hitPos = attack.hitPos,
                playVfx = true,
            }
        end
    end

    --- We should also have some way to determine if an attack fumbled or not
    --- and use that data to remove enchantments when appropriate
    local damageMult = I.s3ChimCore.Manager:getDamageBonus {
        attacker = attack.attacker,
        defender = self.object,
        attackInfo = attack
    }

    for _, damageType in ipairs(damageTypes) do
        if attack.damage[damageType] ~= nil then
            attack.damage[damageType] = attack.damage[damageType] * damageMult
        end
    end
end

Combat.addOnHitHandler(CHIMHitHandler)

I.AnimationController.addTextKeyHandler('', function(group, key)
    if types.Player.objectIsInstance(self) then
        print(self.recordId, group, key)
    end
end)

return {
    eventHandlers = {
        CHIMOnParry = function(parryData)
            Fatigue.current = Fatigue.current - parryData.damage

            if Fatigue.current > 0 then
                I.AnimationController.playBlendedAnimation(
                -- 'knockdown',
                    ('hit%d'):format(math.random(1, 5)),
                    {
                        priority = animation.PRIORITY.Scripted,
                        -- need a formula for determining the animation speed here too
                    }
                )
            end
        end,
    }
}
