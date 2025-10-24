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

    for _, item in pairs(s3lf.getEquipment()) do
        if item and ArmorRecords[item.recordId] then
            local weight = ArmorRecords[item.recordId].weight
            if weight > 0 then
                recoveryTime = recoveryTime * (1 - Poise.EquipmentSlotTimeReduction)
            end
        end
    end

    Poise.debugLog(
        ([[%s: Poise Recovery Time: %.3f]]):format(s3lf.recordId, recoveryTime)
    )
    return math.max(recoveryTime, Poise.MinRecoveryDuration)
end

function Poise.startTimer()
    Poise.state.timeRemaining = Poise.recoveryTime()
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

    -- Two-handed weapons get bonus
    local usingTwoHanded = I.s3ChimCore.Manager.weaponIsTwoHanded(weapon)
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
    if not damage or damage == 0 or not Poise.Enable then return 1.0 end
    if Poise.isBroken() then return Poise.PoiseDamageMult end

    Poise.startTimer()

    local poiseDamage
    if attackInfo.weapon then
        poiseDamage = Poise.weaponPoiseDamage(attackInfo)
    else
        error('Hand to hand/creatures not yet supported!')
    end

    Poise.hitDamage(poiseDamage)

    return 1.0
end

function Poise.tick(dt)
    if Poise.state.timeRemaining <= 0 then return end
    Poise.state.timeRemaining = math.max(0.0, Poise.state.timeRemaining - dt)
    if Poise.state.timeRemaining == 0.0 then Poise.state.currentPoise = Poise.calculateMaxPoise() end
end

function Poise.reset()
    Poise.state.currentPoise = Poise.calculateMaxPoise()
    Poise.state.timeRemaining = 0.
end

--- Needs to also handle melee attacks and probably spells as well
I.AnimationController.addTextKeyHandler('',
    function(group, key)
        if group == 'knockout' and Poise.isBroken() then return s3lf.cancel(group) end

        if group == 'knockdown' and key == 'stop' and Poise.isBroken() then
            Poise.state.isBroken = false

            if types.Player.objectIsInstance(s3lf.gameObject) then
                toggleAllControls(true)
            end
        end

        if Poise.isBroken() and group:find('weapon') then
            s3lf.setStance(s3lf.STANCE.Nothing)
        end
    end
)

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
                        speed = I.s3ChimCore.getHitAnimationSpeed() * 0.85,
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
