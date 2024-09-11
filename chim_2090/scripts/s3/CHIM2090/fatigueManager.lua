local core = require('openmw.core')

local s3lf = require('scripts.s3.lf')
local modInfo = require('scripts.s3.CHIM2090.modInfo')
local FatigueManager = require('scripts.s3.CHIM2090.protectedTable')('SettingsGlobal' .. modInfo.name .. 'Fatigue')

local Fatigue = s3lf.fatigue

function FatigueManager:calculateMaxFatigue()
  local fatigueWil = s3lf.willpower.modified * (self.MaxFatigueWilMult / 100)
  local fatigueAgi = s3lf.agility.modified * (self.MaxFatigueAgiMult / 100)
  local fatigueEnd = s3lf.endurance.modified * (self.MaxFatigueEndMult / 100)
  local fatigueStr = s3lf.strength.modified * (self.MaxFatigueStrMult / 100)
  return math.floor(fatigueWil + fatigueAgi + fatigueEnd + fatigueStr + 0.5)
end

function FatigueManager:overrideNativeFatigue()
  local expectedMaxFatigue = self:calculateMaxFatigue()
  if Fatigue.base == expectedMaxFatigue then return end

  local oldFatigue = Fatigue.base
  local normalizedFatigue = Fatigue.current / Fatigue.base
  Fatigue.base = expectedMaxFatigue
  Fatigue.current = normalizedFatigue * Fatigue.base
  self.debugLog('FatigueMgr: Fatigue updated from', oldFatigue, 'to', Fatigue.base)
end

function FatigueManager:handleFatigueRegen(dt)
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

function FatigueManager:manageFatigue(dt)
  self:overrideNativeFatigue()
  self:handleFatigueRegen(dt)
end

function FatigueManager:getSleepRegenBase(sleepHours)
  local endFatigueMult = self.FatigueEndMult
  local totalEncumbrance = core.getGMST('fEncumbranceStrMult') * s3lf.strength.modified
  local regenPct = 1.0 - (s3lf.getEncumbrance() / totalEncumbrance)
  local fatiguePerSecond = self.FatiguePerSecond + (self.FatigueReturnMult * regenPct)
  fatiguePerSecond = fatiguePerSecond * (endFatigueMult * s3lf.endurance.modified)
  return (fatiguePerSecond * sleepHours) * self.SleepFatigueMult
end

function FatigueManager.calculateNewDynamic(stat, multiplied, newTotal)
  local current = stat.current
  local base = stat.base
  if multiplied == base then
    return math.min(base, newTotal)
  elseif multiplied >= newTotal then
    return newTotal
  elseif current < multiplied or multiplied <= 0 then
    return multiplied
  end
  return stat.current
end

function FatigueManager:sleepHealthRecoveryActor(prevHealth)
end

function FatigueManager:sleepHealthRecoveryPlayer(prevHealth)
end

function FatigueManager:sleepMagickaRecoveryActor(prevMagicka)
end

function FatigueManager:sleepMagickaRecoveryPlayer(prevMagicka)
end

function FatigueManager:sleepFatigueRecoveryActor(sleepData)
  local totalFatigueRegen = self:getSleepRegenBase(sleepData.time)
  local newTotal = s3lf.fatigue.current + totalFatigueRegen
  s3lf.fatigue.current = math.min(s3lf.fatigue.base, newTotal)
end

function FatigueManager:sleepFatigueRecoveryPlayer(sleepData)
  local totalFatigueRegen = self:getSleepRegenBase(sleepData.time)

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

function FatigueManager:sleepRecoveryActor(sleepData)
  self:sleepFatigueRecoveryActor(sleepData)
end

function FatigueManager:sleepRecoveryPlayer(sleepData)
  self:sleepFatigueRecoveryPlayer(sleepData)
end

function FatigueManager:sleepRecoveryVanilla()
  if self.UseVanillaFatigueFormula then
    s3lf.fatigue.current = s3lf.fatigue.base
    return true
  end
  return false
end

function FatigueManager.sleepActorHandler(sleepData)
  assert(sleepData and sleepData.time
         and sleepData.actorStats, 's3ChimFatigue_SleepActor event requires a time value')

  if not FatigueManager:sleepRecoveryVanilla() then
    FatigueManager:sleepRecoveryActor(sleepData)
  end
end

function FatigueManager.sleepPlayerHandler(sleepData)
  assert(sleepData and sleepData.time
         and sleepData.sleepMultiplier and sleepData.actorStats,
         's3ChimFatigue_SleepPlayer event requires a time value and a sleep multiplier')

  if not FatigueManager:sleepRecoveryVanilla() then
    FatigueManager:sleepRecoveryPlayer(sleepData)
  end
end

return {
  interfaceName = 's3ChimFatigue',
  interface = {
    version = modInfo.version,
    Manager = FatigueManager,
  },
  engineHandlers = {
    onUpdate = function(dt)
      if core.isWorldPaused() then return end
      FatigueManager:manageFatigue(dt)
    end,
  },
  eventHandlers = {
    s3ChimFatigue_SleepActor = FatigueManager.sleepActorHandler,
    s3ChimFatigue_SleepPlayer = FatigueManager.sleepPlayerHandler,
  },
}
