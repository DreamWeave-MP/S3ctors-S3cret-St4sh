local animation = require 'openmw.animation'
local core = require 'openmw.core'
local types = require 'openmw.types'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'
---@type ProtectedTableInterface
local ProtectedTable = I.S3ProtectedTable

local ArmorRecords = types.Armor.records
local WeaponRecords = types.Weapon.records

local function toggleAllControls(state)
    s3lf.setControlSwitch(s3lf.CONTROL_SWITCH.Controls, state)
    s3lf.setControlSwitch(s3lf.CONTROL_SWITCH.Fighting, state)
    s3lf.setControlSwitch(s3lf.CONTROL_SWITCH.Jumping, state)
    s3lf.setControlSwitch(s3lf.CONTROL_SWITCH.Magic, state)
    s3lf.setControlSwitch(s3lf.CONTROL_SWITCH.ViewMode, state)
end

---@class PoiseManager: ProtectedTable
---@field Enable boolean
---@field BasePoise integer
---@field PoisePerWeight number
---@field MaxEquipmentPoise integer
---@field MaxTotalPoise integer
---@field StrengthPoiseBonus number
---@field StrengthPoiseDamageBonus number
---@field EndurancePoiseBonus number
---@field PoiseRecoveryDuration number
---@field PoiseDamageMult number
---@field WeightPoiseFactor number
---@field WeaponSkillPoiseFactor number
---@field WeaponPoiseMult number
---@field TwoHandedMult number
---@field EquipmentSlotTimeReduction number
---@field MinRecoveryDuration number
---@field ShieldsMitigatePoiseDamage boolean
---@field PoiseBreakAnimSpeed number
---@field HandToHandSkillPoiseFactor number
---@field AgilityPoiseBonus number
---@field HandToHandPoiseMult number
---@field CreatureBasePoiseDamage number
---@field CreatureStrengthPoiseFactor number
---@field AlwaysScaleHitAnimSpeed boolean
local Poise = ProtectedTable.new {
    inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'Poise',
    logPrefix = '[ CHIMPoise ]:\n',
}
---@class PoiseState
Poise.state = {
    isBroken = false,
    timeRemaining = 0.0,
    currentPoise = 0,
}

function Poise.calculateMaxPoise()
    -- Base poise everyone gets
    local totalPoise = Poise.BasePoise

    -- Equipment weight contribution (armor = poise)
    local totalWeight = 0
    for _, item in pairs(s3lf.getEquipment()) do
        local armorRecord = ArmorRecords[item.recordId]
        if item and armorRecord then
            totalWeight = totalWeight + armorRecord.weight
        end
    end

    local equipmentPoise = math.min(
        totalWeight * Poise.PoisePerWeight,
        Poise.MaxEquipmentPoise
    )
    totalPoise = totalPoise + equipmentPoise

    -- Attribute bonuses
    local strengthBonus = s3lf.strength.modified * Poise.StrengthPoiseBonus
    local enduranceBonus = s3lf.endurance.modified * Poise.EndurancePoiseBonus
    totalPoise = totalPoise + strengthBonus + enduranceBonus

    return util.clamp(totalPoise, 0, Poise.MaxTotalPoise)
end

Poise.state.currentPoise = Poise.calculateMaxPoise()

function Poise.isBroken()
    return Poise.state.isBroken
end

function Poise.recoveryTime()
    local recoveryTime = Poise.PoiseRecoveryDuration

    local equipmentSlotMult = 1 - Poise.EquipmentSlotTimeReduction

    local equipCount = 0
    for _, item in pairs(s3lf.getEquipment()) do
        if not item or not ArmorRecords[item.recordId] then goto CONTINUE end
        local itemRecord = ArmorRecords[item.recordId]

        local weight = itemRecord.weight
        if weight <= 0 then goto CONTINUE end

        recoveryTime = recoveryTime * equipmentSlotMult
        equipCount = equipCount + 1

        ::CONTINUE::
    end

    Poise.debugLog(
        ([[%s-%s: Poise Recovery Time: %.3f with %d pieces of equipment]])
        :format(
            s3lf.recordId,
            s3lf.id,
            recoveryTime,
            equipCount)
    )

    return math.max(recoveryTime, Poise.MinRecoveryDuration)
end

function Poise.startTimer()
    Poise.state.timeRemaining = Poise.recoveryTime()
end

function Poise.creaturePoiseDamage(attackInfo)
    local attacker = s3lf.From(attackInfo.attacker)

    -- Simple base + strength scaling
    local basePoise = Poise.CreatureBasePoiseDamage
    local strengthBonus = attacker.strength.modified * Poise.CreatureStrengthPoiseFactor

    local totalPoise = basePoise + strengthBonus

    Poise.debugLog(
        ([[Creature Attack
        Attacker: %s-%s
        Base Creature Poise Damage: %d
        Strength Bonus: %.2f
        Total Poise Damage: %.2f]]):format(
            attacker.recordId,
            attacker.id,
            basePoise,
            strengthBonus,
            totalPoise
        )
    )

    return totalPoise * (attackInfo.attackStrength or 1.0)
end

---@param attackInfo AttackInfo
---@return number poiseDamage total poise damage dealt by this (hand to hand) attack
function Poise.handToHandPoiseDamage(attackInfo)
    local attacker = s3lf.From(attackInfo.attacker)

    -- Base from hand-to-hand skill (better technique = better force transfer)
    local handToHandSkill = attacker.handtohand.modified
    local skillPoise = handToHandSkill * Poise.HandToHandSkillPoiseFactor

    -- Strength bonus (stronger punches carry more force)
    local strengthBonus = skillPoise * (attacker.strength.modified * Poise.StrengthPoiseDamageBonus)

    -- Weapons gain a bonus from their weight, whereas hand-to-hand combatants instead use their agility
    local agilityBonus = skillPoise * (attacker.agility.modified * Poise.AgilityPoiseBonus)

    local totalPoise = (skillPoise + strengthBonus + agilityBonus) * Poise.HandToHandPoiseMult

    Poise.debugLog(
        ([[Hand to Hand Attack
        Attacker: %s-%s
        Hand-To-Hand Poise: %.2f
        Strength Bonus: %.2f
        Agility Bonus: %.2f
        Total Poise: %.2f]]):format(
            attacker.recordId,
            attacker.id,
            skillPoise,
            strengthBonus,
            agilityBonus,
            totalPoise
        )
    )

    return totalPoise * (attackInfo.attackStrength or 1.0)
end

---@param attackInfo AttackInfo
function Poise.weaponPoiseDamage(attackInfo)
    local weapon = attackInfo.weapon
    assert(weapon)
    local weaponRecord = WeaponRecords[weapon.recordId]
    local attacker = s3lf.From(attackInfo.attacker)

    -- Base from weapon weight (heavier weapons stagger more)
    local weightPoise = weaponRecord.weight * Poise.WeightPoiseFactor

    local weaponSkill = I.s3ChimCore.Manager.getWeaponSkill(weapon, attackInfo.attacker)
    local skillPoise = weaponSkill * Poise.WeaponSkillPoiseFactor

    -- Strength bonus (stronger swings carry more force)
    local strengthBonus = (weightPoise + skillPoise) * (attacker.strength.modified * Poise.StrengthPoiseDamageBonus)

    local totalPoise = (weightPoise + skillPoise + strengthBonus) * Poise.WeaponPoiseMult

    -- Two-handed weapons get bonus, or crossbows
    local handedness = I.s3ChimCore.getWeaponHandedness(weapon)
    local usingTwoHanded = handedness == I.s3ChimCore.Handedness.TWO or
        weaponRecord.type == weapon.type.TYPE.MarksmanCrossbow

    if usingTwoHanded then
        totalPoise = totalPoise * Poise.TwoHandedMult
    end

    Poise.debugLog(
        ([[Weapon Id: %s
        Attacker: %s
        Weight Poise: %.2f
        Skill Poise: %.2f
        Strength Poise: %.2f
        Two Handed Mult: %.2f (Using two handed: %s)
        Total Poise: %.2f]]):format(
            weapon.recordId,
            attacker.recordId,
            weightPoise,
            skillPoise,
            strengthBonus,
            Poise.TwoHandedMult,
            usingTwoHanded,
            totalPoise
        )
    )

    return totalPoise * (attackInfo.attackStrength or 1.0)
end

---@param value integer
---@return true? poiseBroken
function Poise.hitDamage(value)
    if I.s3ChimBlock and Poise.ShieldsMitigatePoiseDamage then
        value = value * I.s3ChimBlock.Manager.calculateMitigation()
    end

    Poise.state.currentPoise = math.max(0, math.floor(Poise.get() - value))
    if Poise.get() ~= 0 or Poise.isBroken() then return end

    s3lf.gameObject:sendEvent('CHIMPoiseBreak')
    return true
end

---@return integer currentPoise
function Poise.get()
    return Poise.state.currentPoise
end

---@class AttackDamageTypes
---@field health number?
---@field magicka number?
---@field fatigue number?

---@class AttackInfo
---@field attacker GameObject?
---@field weapon GameObject?
---@field attackStrength number
---@field defender GameObject
---@field damage AttackDamageTypes

---@param attackInfo AttackInfo
---@return number poiseDamageMult
function Poise.onHit(attackInfo)
    local damage = attackInfo.damage.health or attackInfo.damage.fatigue
    if not attackInfo.attacker or not damage or damage == 0 or not Poise.Enable then return 1.0 end
    if Poise.isBroken() then return Poise.PoiseDamageMult end

    Poise.startTimer()

    local poiseDamage
    if attackInfo.weapon then
        poiseDamage = Poise.weaponPoiseDamage(attackInfo)
    else
        -- We'll assume that bipedal creatures are always using a weapon.
        -- Maybe possibly this will bite us in the ass later but we'll scream test it.
        if types.NPC.objectIsInstance(attackInfo.attacker) then
            poiseDamage = Poise.handToHandPoiseDamage(attackInfo)
        else
            poiseDamage = Poise.creaturePoiseDamage(attackInfo)
        end
    end

    if Poise.hitDamage(poiseDamage) then
        return Poise.PoiseDamageMult
    else
        return 1.0
    end
end

function Poise.tick(dt)
    if Poise.state.timeRemaining <= 0 or s3lf.isDead() then return end
    Poise.state.timeRemaining = math.max(0.0, Poise.state.timeRemaining - dt)
    if Poise.state.timeRemaining == 0.0 then Poise.state.currentPoise = Poise.calculateMaxPoise() end
end

function Poise.reset()
    Poise.state.currentPoise = Poise.calculateMaxPoise()
    Poise.state.timeRemaining = 0.
end

---@return true? knockdownInterrupted
local function cancelKnockdownIfDead()
    if
        s3lf.isDead()
        and Poise.isBroken()
        and s3lf.isPlaying('knockdown')
    then
        s3lf.cancel('knockdown')
    end
end

local textKeyHandlers = {
    knockout = function(group, _)
        if not Poise.isBroken() then return end

        Poise.debugLog(
            ('cancelling knockdown on %s'):format(s3lf.recordId)
        )
        s3lf.cancel(group)
    end,
    knockdown = function(_, key)
        if key ~= 'stop' or not Poise.isBroken() then return end

        Poise.state.isBroken = false

        if types.Player.objectIsInstance(s3lf.gameObject) then
            toggleAllControls(true)
        end
    end,
}

--- Needs to also handle melee attacks and probably spells as well
I.AnimationController.addTextKeyHandler('',
    function(group, key)
        local keyHandler = textKeyHandlers[group]
        if keyHandler then keyHandler(group, key) end

        if
            Poise.AlwaysScaleHitAnimSpeed
            and (group == 'knockdown' or group:match('^hit'))
        then
            s3lf.setSpeed(group, I.s3ChimCore.getHitAnimationSpeed())
        end
    end
)

--- Awkward hack to prevent NPCs from attacking whilst knocked down
local function interruptAttacksIfPoiseBroken()
    if not s3lf.hasAnimation() then return end
    local activeArm = s3lf.getActiveGroup(s3lf.BONE_GROUP.RightArm)
    if not activeArm:find('weapon') or not Poise.isBroken() then return end
    s3lf.setStance(s3lf.STANCE.Nothing)
end

return {
    interfaceName = 's3ChimPoise',
    interface = setmetatable(
        {},
        {
            __index = function(_, key)
                local managerKey = Poise[key]

                if key == 'help' then
                    return [[
                    ]]
                elseif managerKey then
                    return managerKey
                elseif key == 'Manager' then
                    return Poise
                end
            end,
        }
    ),
    engineHandlers = {
        onUpdate = function(dt)
            if core.isWorldPaused() or not Poise.Enable then return end

            cancelKnockdownIfDead()
            interruptAttacksIfPoiseBroken()
            Poise.tick(dt)
        end,
    },
    eventHandlers = {
        CHIMPoiseBreak = function()
            if not Poise.Enable then return end

            if s3lf.canMove() and s3lf.fatigue.current > 0 then
                I.AnimationController.playBlendedAnimation(
                    'knockdown',
                    {
                        priority = animation.PRIORITY.Scripted,
                        speed = I.s3ChimCore.getHitAnimationSpeed() * Poise.PoiseBreakAnimSpeed,
                    }
                )

                if types.Player.objectIsInstance(s3lf.gameObject) then
                    toggleAllControls(false)
                end
            end

            Poise.state.isBroken = true

            -- Technically this is a dark souls *2* feature but for the sake of fun I think we should try it
            Poise.reset()
        end,

    },
}
