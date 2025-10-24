local core = require 'openmw.core'
local types = require 'openmw.types'

local I = require 'openmw.interfaces'

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local ChameleonEffect = core.magic.EFFECT_TYPE.Chameleon
local InvisibleEffect = core.magic.EFFECT_TYPE.Invisibility
local ParalyzeEffect = core.magic.EFFECT_TYPE.Paralyze
local SanctuaryEffect = core.magic.EFFECT_TYPE.Sanctuary

local s3lf = I.s3lf

local groupName = 'SettingsGlobal' .. modInfo.name .. 'Core'

---@class ChimCore: ProtectedTable
---@field EnableCritFumble boolean Whether or not critical/fumbling attacks are enabled
---@field CritDamageMultiplier number floating point number determining how much stronger a critical attack is. Probably could do to use a more advanced formula instead of being a straight multiplier.
---@field CritLuckPercent integer multiplier for how much influence luck has upon critical strikes. Default 10
---@field CritChancePercent integer multiplier
---@field MaxDamageMultiplier number Maximum multiplier for damage done in comparison to one's native hit chance. EG, this is the maximum amount of damage one may do in comparison to their hit chance as calculated by the base game, not including defender stats.
---@field AgilityHitChancePct number influence of agility on hit chance calculations. Defaults to 20%
---@field LuckHitChancePct number influence of agility on hit chance calculations. Defaults to 10%
---@field FumbleDamagePercent integer Percentage of damage done on a fumble, expressed as an integer between 0 and 100. Default 25
---@field FumbleBaseChance integer Base chance for a fumbling attack prior to taking stat calculations or chance scaling into account. Default 3
---@field FumbleChanceScale integer Scaling applied to fumble chance globally. Increases or decreases the overall chance for fumbles; Default 10
---@field GlobalDamageScaling number Global multiplier applied to damage on physical strikes
---@field LightAnimSpeedThreshold number
---@field MediumAnimSpeedThreshold number
---@field HeavyAnimSpeedThreshold number
---@field LightAnimSpeed number
---@field MediumAnimSpeed number
---@field HeavyAnimSpeed number
---@field OverloadedAnimSpeed number
local ChimCore = I.S3ProtectedTable.new { inputGroupName = groupName, logPrefix = '[ CHIMCore ]:' }

local ActiveEffects = s3lf.activeEffects()

local TargetAttackMagnitude = 32000
local function ensureFortifyAttack()
    local currentFortifyAttackMagnitude = ActiveEffects:getEffect(core.magic.EFFECT_TYPE.FortifyAttack).magnitude
    ActiveEffects:modify(TargetAttackMagnitude - currentFortifyAttackMagnitude, core.magic.EFFECT_TYPE.FortifyAttack)
end
ensureFortifyAttack()

local fCombatInvisoMult = core.getGMST('fCombatInvisoMult')
local fFatigueBase = core.getGMST('fFatigueBase')
local fFatigueMult = core.getGMST('fFatigueMult')

local weaponTypes = types.Weapon.TYPE
local weaponTypesToSkills = {
    [weaponTypes.ShortBladeOneHand] = 'shortblade',
    [weaponTypes.LongBladeOneHand] = 'longblade',
    [weaponTypes.LongBladeTwoHand] = 'longblade',
    [weaponTypes.BluntOneHand] = 'bluntweapon',
    [weaponTypes.BluntTwoClose] = 'bluntweapon',
    [weaponTypes.BluntTwoWide] = 'bluntweapon',
    [weaponTypes.SpearTwoWide] = 'spear',
    [weaponTypes.AxeOneHand] = 'axe',
    [weaponTypes.AxeTwoHand] = 'axe',
    [weaponTypes.MarksmanBow] = 'marksman',
    [weaponTypes.MarksmanCrossbow] = 'marksman',
    [weaponTypes.MarksmanThrown] = 'marksman',
}

local twoHandedTypes = {
    [weaponTypes.LongBladeTwoHand] = true,
    [weaponTypes.BluntTwoClose] = true,
    [weaponTypes.BluntTwoWide] = true,
    [weaponTypes.SpearTwoWide] = true,
    [weaponTypes.AxeTwoHand] = true,
    --- Bows are technically also two-handed but we'll do this only for crossbows to simulate them hitting harder
    [weaponTypes.MarksmanCrossbow] = true,
}

---@param actor GameObject
---@return number fatigueTerm fatigue cost for this action??
local function getFatigueTerm(actor)
    local normalizedFatigue = actor.fatigue.current / actor.fatigue.base
    local fatigueTerm = fFatigueBase - fFatigueMult * (1 - normalizedFatigue)
    return fatigueTerm
end

---@param weapon GameObject
---@param attacker GameObject
function ChimCore.getWeaponSkill(weapon, attacker)
    local weaponType = weapon.type.records[weapon.recordId].type
    local weaponSkill = weaponTypesToSkills[weaponType]
    attacker = s3lf.From(attacker)
    return attacker[weaponSkill].modified
end

---Given a weapon object return whether it is a two-handed type
---@param weapon GameObject
---@return boolean
function ChimCore.weaponIsTwoHanded(weapon)
    local weaponType = weapon.type.records[weapon.recordId].type
    return twoHandedTypes[weaponType] or false
end

function ChimCore.getRandomHitGroup()
    local formatString, range

    if s3lf.isSwimming() then
        formatString, range = 'swimhit%d', 3
    else
        formatString, range = 'hit%d', 5
    end

    return formatString:format(math.random(1, range))
end

---@param attacker GameObject
---@param defender GameObject
---@return number defenseTerm Influence of the defending character's stats on an attack's chance to hit. Not actually used in CHIM, probably.
function ChimCore:getAttackDefenseTerm(attacker, defender)
    if defender.fatigue.current <= 0 then
        return 0
    end

    local defenseTerm = 0
    local defenderEffects = defender.activeEffects()
    local unaware = defender.stance == defender.STANCE.Nothing and types.Player.objectIsInstance(attacker.gameObject)
    local isKnockedDown = defender.isPlaying('knockout')
    local isParalyzed = defenderEffects:getEffect(ParalyzeEffect).magnitude > 0

    if not (unaware or isKnockedDown or isParalyzed) then
        local agilityDefenseInfluence = self.AgilityHitChancePct * defender.agility.modified
        local luckDefenseInfluence = self.LuckHitChancePct * defender.luck.modified
        local defenderFatigueTerm = getFatigueTerm(defender)
        defenseTerm = (agilityDefenseInfluence + luckDefenseInfluence) * defenderFatigueTerm

        local sanctuaryEffect = defenderEffects:getEffect(SanctuaryEffect).magnitude
        sanctuaryEffect = math.min(100, sanctuaryEffect)
        defenseTerm = defenseTerm + sanctuaryEffect
    end

    local chameleonEffect = math.min(100, fCombatInvisoMult * defenderEffects:getEffect(ChameleonEffect).magnitude)
    local invisibilityEffect = math.min(100, fCombatInvisoMult * defenderEffects:getEffect(InvisibleEffect)
        .magnitude)

    defenseTerm = defenseTerm + chameleonEffect + invisibilityEffect

    return defenseTerm
end

---@param attackData CHIMAttackData
---@return number hitChance hit chance used to determine the overall attack effectiveness
function ChimCore:getNativeHitChance(attackData)
    local attacker, defender = attackData.attacker, attackData.defender

    local attackerFatigueTerm = getFatigueTerm(attacker)

    local weapon = attacker.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)

    local skillValue
    if types.Creature.objectIsInstance(attacker.gameObject) then
        skillValue = attacker.combatSkill
    elseif not weapon then
        skillValue = attacker.handtohand.modified
    else
        local weaponType = weapon.type.records[weapon.recordId].type
        local skillName = weaponTypesToSkills[weaponType]
        skillValue = attacker[skillName].modified
    end

    local agilityInfluence = self.AgilityHitChancePct * attacker.agility.modified
    local luckInfluence = self.LuckHitChancePct * attacker.luck.modified

    local attackTerm = (skillValue + agilityInfluence + luckInfluence) * attackerFatigueTerm
    local blindMagnitude = attacker.activeEffects():getEffect("blind").magnitude

    attackTerm = (attackTerm - blindMagnitude) / 100

    return attackTerm
end

---@class CHIMAttackData
---@field attacker GameObject
---@field defender GameObject
---@field attackInfo table<string, any>

---@param attackData CHIMAttackData
function ChimCore:getDamageBonus(attackData)
    attackData.attacker = I.s3lf.From(attackData.attacker)
    attackData.defender = I.s3lf.From(attackData.defender)

    local roll = math.random()
    local luckMod = (math.min(attackData.attacker.luck.modified, 100) / 100.0) * self.CritLuckPercent
    local hitChance = math.min(self.MaxDamageMultiplier, I.s3ChimCore.Manager:getNativeHitChance(attackData))
    local critChance = hitChance * (self.CritChancePercent / 100.0) * (1 + luckMod)
    local fumblePct = self.FumbleBaseChance / 100.0
    local fumbleScalePct = self.FumbleChanceScale / 100.0
    local fumbleChance = math.max(0.0,
        (
            fumblePct +
            (1.0 - (hitChance + luckMod)
            ) * fumbleScalePct
        )
    )

    self.debugLog(
        (
            [[Roll: %s
Hit Chance: %s
Crit Chance: %s
Fumble Chance: %s
Luck Mod: %s]]
        ):format(roll, hitChance, critChance, fumbleChance, luckMod)
    )

    if self.EnableCritFumble then
        if roll < fumbleChance then
            hitChance = hitChance * (self.FumbleDamagePercent / 100)
        elseif roll < critChance then
            hitChance = hitChance * self.CritDamageMultiplier
        end
    end

    return hitChance
end

function ChimCore.getTotalEquipmentWeight()
    local totalEquippedWeight = 0
    for _, item in ipairs(s3lf.getEquipment()) do
        if not item then goto CONTINUE end

        local countsAsEquipment = types.Armor.objectIsInstance(item) or types.Weapon.objectIsInstance(item)

        if not countsAsEquipment then goto CONTINUE end

        local itemRecord = item.type.records[item.recordId]
        totalEquippedWeight = totalEquippedWeight + itemRecord.weight

        ::CONTINUE::
    end

    return totalEquippedWeight
end

function ChimCore.getHitAnimationSpeed()
    local equipmentWeight = ChimCore.getTotalEquipmentWeight()

    if equipmentWeight <= ChimCore.LightAnimSpeedThreshold then
        return ChimCore.LightAnimSpeed
    elseif equipmentWeight <= ChimCore.MediumAnimSpeedThreshold then
        return ChimCore.MediumAnimSpeed
    elseif equipmentWeight <= ChimCore.HeavyAnimSpeedThreshold then
        return ChimCore.OverloadedAnimSpeed
    else
        return ChimCore.OverloadedAnimSpeed
    end
end

return {
    interfaceName = "s3ChimCore",
    interface = setmetatable(
        {},
        {
            __index = function(_, key)
                local managerKey = ChimCore[key]

                if key == 'help' then
                    return [[
                    ]]
                elseif managerKey then
                    return managerKey
                elseif key == 'Manager' then
                    return ChimCore
                end
            end,
        }
    ),
    eventHandlers = {
        CHIMEnsureFortifyAttack = ensureFortifyAttack,
    },
}
