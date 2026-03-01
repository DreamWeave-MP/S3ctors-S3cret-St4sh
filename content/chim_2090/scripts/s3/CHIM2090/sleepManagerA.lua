local storage = require 'openmw.storage'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

---@type ProtectedTableInterface
local protectedTableInterface = I.S3ProtectedTable

---@class SleepManagerA: ProtectedTable
local SleepManagerA = protectedTableInterface.new { inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'Sleep', logPrefix = 'ChimSleepManagerA' }

function SleepManagerA.calculateNewDynamic(stat, multiplied, newTotal, old)
    local current = old or stat.current
    local base = stat.base
    if multiplied == base then
        return math.min(base, newTotal)
    elseif multiplied >= newTotal then
        return newTotal
    elseif current < multiplied or multiplied <= 0 then
        return multiplied
    end
    return current
end

function SleepManagerA:sleepHealthRecoveryActor(sleepData)
    if not I.s3ChimDynamic.canRegenerateHealth() then return end
    local totalHealthRegen = self:getSleepHealthRegenBase() * sleepData.time
    local newTotal = sleepData.oldHealth + totalHealthRegen
    s3lf.health.current = math.min(s3lf.health.base, newTotal)
    self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.health.current - sleepData.oldHealth, 'health.')
end

function SleepManagerA:sleepHealthRecoveryPlayer(sleepData)
    if not I.s3ChimDynamic.canRegenerateHealth() then return end

    local totalHealthRegen = self:getSleepHealthRegenBase() * sleepData.time

    local newTotal = sleepData.oldHealth + totalHealthRegen
    local multipliedHealth = s3lf.health.base * sleepData.sleepMultiplier

    s3lf.health.current = self.calculateNewDynamic(s3lf.health, multipliedHealth, newTotal, sleepData.oldHealth)
    self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.health.current - sleepData.oldHealth, 'health.')
end

function SleepManagerA.getSleepHealthRegenBase()
    local healthMult = storage.globalSection("SettingsGlobal" .. modInfo.name .. 'Sleep'):get('RestHealthMult')
    return healthMult * (s3lf.endurance.modified + s3lf.willpower.modified)
end

function SleepManagerA:getSleepMagickaRegenBase(sleepHours)
    local magicMult = storage.globalSection("SettingsGlobal" .. modInfo.name .. 'Sleep'):get('RestMagicMult')
    return sleepHours * magicMult * (s3lf.intelligence.modified + s3lf.willpower.modified)
end

function SleepManagerA:getSleepFatigueRegenBase(sleepHours)
    local endFatigueMult = self.FatigueEndMult
    local totalEncumbrance = core.getGMST('fEncumbranceStrMult') * s3lf.strength.modified
    local regenPct = 1.0 - (s3lf.getEncumbrance() / totalEncumbrance)
    local fatiguePerSecond = self.FatiguePerSecond + (self.FatigueReturnMult * regenPct)
    fatiguePerSecond = fatiguePerSecond * (endFatigueMult * s3lf.endurance.modified)
    return (fatiguePerSecond * sleepHours) * self.SleepFatigueMult
end

function SleepManagerA:sleepMagickaRecoveryActor(sleepData)
    if not I.s3ChimDynamic.canRegenerateMagicka() then return end

    local totalFatigueRegen = self:getSleepMagickaRegenBase(sleepData.time)
    local newTotal = s3lf.magicka.current + totalFatigueRegen
    local prevMagicka = s3lf.magicka.current
    s3lf.magicka.current = math.min(s3lf.magicka.base, newTotal)
    self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.magicka.current - prevMagicka, 'magicka.')
end

function SleepManagerA:sleepMagickaRecoveryPlayer(sleepData)
    if not I.s3ChimDynamic.canRegenerateMagicka() then return end

    local totalMagickaRegen = self:getSleepMagickaRegenBase(sleepData.time)
    local multiplier = sleepData.sleepMultiplier

    local newTotal = s3lf.magicka.current + totalMagickaRegen
    local multipliedMagicka = s3lf.magicka.base * multiplier

    local prevMagicka = s3lf.magicka.current
    s3lf.magicka.current = self.calculateNewDynamic(s3lf.magicka, multipliedMagicka, newTotal)
    self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.magicka.current - prevMagicka, 'magicka.')
end

function SleepManagerA:sleepFatigueRecoveryActor(sleepData)
    if not I.s3ChimDynamic.canRegenerateFatigue() then return end

    local totalFatigueRegen = self:getSleepFatigueRegenBase(sleepData.time)
    local newTotal = s3lf.fatigue.current + totalFatigueRegen
    s3lf.fatigue.current = math.min(s3lf.fatigue.base, newTotal)
end

function SleepManagerA:sleepFatigueRecoveryPlayer(sleepData)
    if not I.s3ChimDynamic.canRegenerateFatigue() then return end

    local totalFatigueRegen = self:getSleepFatigueRegenBase(sleepData.time)

    local multiplier = sleepData.sleepMultiplier

    local newTotal = s3lf.fatigue.current + totalFatigueRegen
    local multipliedFatigue = s3lf.fatigue.base * multiplier

    s3lf.fatigue.current = self.calculateNewDynamic(s3lf.fatigue, multipliedFatigue, newTotal)

    self.debugLog('Player rested for'
    , sleepData.time, 'hours. The player'
    , sleepData.restOrWait and 'slept' or 'waited'
    , 'and regenerated', totalFatigueRegen, 'fatigue.'
    , 'The player has', s3lf.fatigue.current, 'fatigue out of', s3lf.fatigue.base
    , '. Their multiplier was', multiplier)
end

function SleepManagerA:sleepRecoveryActor(sleepData)
    if sleepData.restOrWait then
        self:sleepHealthRecoveryActor(sleepData)
        self:sleepMagickaRecoveryActor(sleepData)
    end
    self:sleepFatigueRecoveryActor(sleepData)
end

function SleepManagerA:sleepRecoveryPlayer(sleepData)
    self:sleepHealthRecoveryPlayer(sleepData)
    self:sleepMagickaRecoveryPlayer(sleepData)
    self:sleepFatigueRecoveryPlayer(sleepData)
end

function SleepManagerA:sleepRecoveryVanilla(sleepData)
    if self.UseVanillaFatigueFormula then
        -- For health, do nothing, as it's handled engine-side based on endurance
        if I.s3ChimDynamic.canRegenerateFatigue() then
            s3lf.fatigue.current = s3lf.fatigue.base
        end

        if sleepData.restOrWait then
            if I.s3ChimDynamic.canRegenerateMagicka() then
                local magicMult = storage.globalSection("SettingsGlobal" .. modInfo.name .. 'Sleep'):get('RestMagicMult')
                local magickaPerHour = s3lf.intelligence.modified * magicMult
                s3lf.magicka.current = math.min(s3lf.magicka.base,
                    s3lf.magicka.current + (magickaPerHour * sleepData.time))
            end
        end
        return true
    end
    return false
end

function SleepManagerA.sleepActorHandler(sleepData)
    assert(sleepData and sleepData.time and sleepData.restOrWait ~= nil
        and sleepData.oldHealth, 's3ChimDynamic_SleepActor event requires a time value')

    if not SleepManagerA:sleepRecoveryVanilla(sleepData) then
        SleepManagerA:sleepRecoveryActor(sleepData)
    end
end

function SleepManagerA.sleepPlayerHandler(sleepData)
    assert(sleepData and sleepData.time and sleepData.restOrWait ~= nil
        and sleepData.oldHealth and sleepData.sleepMultiplier,
        's3ChimDynamic_SleepPlayer event requires a time value and a sleep multiplier')

    if not SleepManagerA:sleepRecoveryVanilla(sleepData) then
        SleepManagerA:sleepRecoveryPlayer(sleepData)
    end
end

return {
    interfaceName = 's3ChimSleepA',
    interface = {
        version = modInfo.version,
        Manager = SleepManagerA,
    },
    eventHandlers = {
        s3ChimDynamic_SleepActor = SleepManagerA.sleepActorHandler,
        s3ChimDynamic_SleepPlayer = SleepManagerA.sleepPlayerHandler,
    },
}
