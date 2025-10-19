local core = require 'openmw.core'
local self = require 'openmw.self'

--- https://gitlab.com/OpenMW/openmw/-/merge_requests/4334
--- https://gitlab.com/OpenMW/openmw/-/blob/96d0d1fa7cd83e41853061cca68f612b7eb9c834/CMakeLists.txt#L85
local onHitAPIRevision = 85
if core.API_REVISION < onHitAPIRevision then
    error 'CHIM-2090 requires openmw 0.50 and later! Sorry :('
end

local I = require 'openmw.interfaces'
local Combat = I.Combat

local damageTypes = { 'health', 'fatigue', 'magicka' }
local function CHIMHitHandler(attack)
    if not attack.attacker then return end

    if not attack.successful then
        attack.attacker:sendEvent('CHIMEnsureFortifyAttack')
    end

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
