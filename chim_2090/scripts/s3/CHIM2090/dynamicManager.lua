local core = require('openmw.core')
local storage = require('openmw.storage')

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require('scripts.s3.CHIM2090.modInfo')
local DynamicManager = I.S3ProtectedTable.new { inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'Dynamic' }

local Fatigue = s3lf.fatigue

function DynamicManager:calculateMaxFatigue()
  local fatigueWil = s3lf.willpower.modified * (self.MaxFatigueWilMult / 100)
  local fatigueAgi = s3lf.agility.modified * (self.MaxFatigueAgiMult / 100)
  local fatigueEnd = s3lf.endurance.modified * (self.MaxFatigueEndMult / 100)
  local fatigueStr = s3lf.strength.modified * (self.MaxFatigueStrMult / 100)
  return math.floor(fatigueWil + fatigueAgi + fatigueEnd + fatigueStr + 0.5)
end

function DynamicManager:overrideNativeFatigue()
  local expectedMaxFatigue = self:calculateMaxFatigue()
  if Fatigue.base == expectedMaxFatigue then return end

  local oldFatigue = Fatigue.base
  local normalizedFatigue = Fatigue.current / Fatigue.base
  Fatigue.base = expectedMaxFatigue
  Fatigue.current = normalizedFatigue * Fatigue.base
  self.debugLog('FatigueMgr: Fatigue updated from', oldFatigue, 'to', Fatigue.base)
end

function DynamicManager:handleFatigueRegen(dt)
  if Fatigue.current >= Fatigue.base then return end

  local fatigueThisFrame

  if self.UseVanillaFatigueFormula then
    fatigueThisFrame = self.FatiguePerSecond + (self.FatigueReturnMult * s3lf.endurance.modified)
  else
    fatigueThisFrame = self.FatiguePerSecond
  end

  fatigueThisFrame = Fatigue.current + (fatigueThisFrame * dt)

  Fatigue.current = math.min(Fatigue.base, fatigueThisFrame)
end

function DynamicManager:manageFatigue(dt)
  self:overrideNativeFatigue()
  self:handleFatigueRegen(dt)
end

function DynamicManager.canRegenerateMagicka()
  return s3lf.activeEffects():getEffect('stuntedmagicka').magnitude == 0
end

function DynamicManager.canRegenerateFatigue()
  return true
end

function DynamicManager.canRegenerateHealth()
  return true
end

function DynamicManager.getSleepHealthRegenBase()
  local healthMult = storage.globalSection("SettingsGlobal" .. modInfo.name .. 'Sleep'):get('RestHealthMult')
  return healthMult * (s3lf.endurance.modified + s3lf.willpower.modified)
end

function DynamicManager:getSleepMagickaRegenBase(sleepHours)
  local magicMult = storage.globalSection("SettingsGlobal" .. modInfo.name .. 'Sleep'):get('RestMagicMult')
  return sleepHours * magicMult * (s3lf.intelligence.modified + s3lf.willpower.modified)
end

function DynamicManager:getSleepFatigueRegenBase(sleepHours)
  local endFatigueMult = self.FatigueEndMult
  local totalEncumbrance = core.getGMST('fEncumbranceStrMult') * s3lf.strength.modified
  local regenPct = 1.0 - (s3lf.getEncumbrance() / totalEncumbrance)
  local fatiguePerSecond = self.FatiguePerSecond + (self.FatigueReturnMult * regenPct)
  fatiguePerSecond = fatiguePerSecond * (endFatigueMult * s3lf.endurance.modified)
  return (fatiguePerSecond * sleepHours) * self.SleepFatigueMult
end

function DynamicManager.calculateNewDynamic(stat, multiplied, newTotal, old)
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

function DynamicManager:sleepHealthRecoveryActor(sleepData)
  if not self.canRegenerateHealth() then return end
  local totalHealthRegen = self:getSleepHealthRegenBase() * sleepData.time
  local newTotal = sleepData.oldHealth + totalHealthRegen
  s3lf.health.current = math.min(s3lf.health.base, newTotal)
  self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.health.current - sleepData.oldHealth, 'health.')
end

function DynamicManager:sleepHealthRecoveryPlayer(sleepData)
  if not self.canRegenerateHealth() then return end

  local totalHealthRegen = self:getSleepHealthRegenBase() * sleepData.time

  local newTotal = sleepData.oldHealth + totalHealthRegen
  local multipliedHealth = s3lf.health.base * sleepData.sleepMultiplier

  s3lf.health.current = self.calculateNewDynamic(s3lf.health, multipliedHealth, newTotal, sleepData.oldHealth)
  self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.health.current - sleepData.oldHealth, 'health.')
end

function DynamicManager:sleepMagickaRecoveryActor(sleepData)
  if not self.canRegenerateMagicka() then return end

  local totalFatigueRegen = self:getSleepMagickaRegenBase(sleepData.time)
  local newTotal = s3lf.magicka.current + totalFatigueRegen
  local prevMagicka = s3lf.magicka.current
  s3lf.magicka.current = math.min(s3lf.magicka.base, newTotal)
  self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.magicka.current - prevMagicka, 'magicka.')
end

function DynamicManager:sleepMagickaRecoveryPlayer(sleepData)
  if not self.canRegenerateMagicka() then return end

  local totalMagickaRegen = self:getSleepMagickaRegenBase(sleepData.time)
  local multiplier = sleepData.sleepMultiplier

  local newTotal = s3lf.magicka.current + totalMagickaRegen
  local multipliedMagicka = s3lf.magicka.base * multiplier

  local prevMagicka = s3lf.magicka.current
  s3lf.magicka.current = self.calculateNewDynamic(s3lf.magicka, multipliedMagicka, newTotal)
  self.debugLog(s3lf.id, s3lf.recordId, 'Restored', s3lf.magicka.current - prevMagicka, 'magicka.')
end

function DynamicManager:sleepFatigueRecoveryActor(sleepData)
  if not self.canRegenerateFatigue() then return end

  local totalFatigueRegen = self:getSleepFatigueRegenBase(sleepData.time)
  local newTotal = s3lf.fatigue.current + totalFatigueRegen
  s3lf.fatigue.current = math.min(s3lf.fatigue.base, newTotal)
end

function DynamicManager:sleepFatigueRecoveryPlayer(sleepData)
  if not self.canRegenerateFatigue() then return end

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

function DynamicManager:sleepRecoveryActor(sleepData)
  if sleepData.restOrWait then
    self:sleepHealthRecoveryActor(sleepData)
    self:sleepMagickaRecoveryActor(sleepData)
  end
  self:sleepFatigueRecoveryActor(sleepData)
end

function DynamicManager:sleepRecoveryPlayer(sleepData)
  self:sleepHealthRecoveryPlayer(sleepData)
  self:sleepMagickaRecoveryPlayer(sleepData)
  self:sleepFatigueRecoveryPlayer(sleepData)
end

function DynamicManager:sleepRecoveryVanilla(sleepData)
  if self.UseVanillaFatigueFormula then
    -- For health, do nothing, as it's handled engine-side based on endurance
    if self.canRegenerateFatigue() then
      s3lf.fatigue.current = s3lf.fatigue.base
    end

    if sleepData.restOrWait then
      if self.canRegenerateMagicka() then
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

function DynamicManager.sleepActorHandler(sleepData)
  assert(sleepData and sleepData.time and sleepData.restOrWait ~= nil
    and sleepData.oldHealth, 's3ChimDynamic_SleepActor event requires a time value')

  if not DynamicManager:sleepRecoveryVanilla(sleepData) then
    DynamicManager:sleepRecoveryActor(sleepData)
  end
end

function DynamicManager.sleepPlayerHandler(sleepData)
  assert(sleepData and sleepData.time and sleepData.restOrWait ~= nil
    and sleepData.oldHealth and sleepData.sleepMultiplier,
    's3ChimDynamic_SleepPlayer event requires a time value and a sleep multiplier')

  if not DynamicManager:sleepRecoveryVanilla(sleepData) then
    DynamicManager:sleepRecoveryPlayer(sleepData)
  end
end

return {
  interfaceName = 's3ChimDynamic',
  interface = {
    version = modInfo.version,
    Manager = DynamicManager,
  },
  engineHandlers = {
    onUpdate = function(dt)
      if core.isWorldPaused() then return end
      DynamicManager:manageFatigue(dt)
    end,
  },
  eventHandlers = {
    s3ChimDynamic_SleepActor = DynamicManager.sleepActorHandler,
    s3ChimDynamic_SleepPlayer = DynamicManager.sleepPlayerHandler,
  },
}
