local core = require 'openmw.core'
local types = require 'openmw.types'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.CHIM2090.modInfo'
local MagickEffect = core.magic.EFFECT_TYPE

---@class DynamicManager: ProtectedTable
---@field MaxFatigueWilMult integer
---@field MaxFatigueAgiMult integer
---@field MaxFatigueEndMult integer
---@field MaxFatigueStrMult integer
---@field FatiguePerSecond integer
---@field FatigueReturnMult number
---@field UseVanillaFatigueFormula boolean
---@field FortifyMagickaMultiplier number
---@field PCbaseMagickaMultiplier number
---@field NPCbaseMagickaMultiplier number
---@field FatigueBlockBase number
---@field FatigueBlockMult number
---@field WeaponFatigueBlockMult number
---@field BaseHealth integer
---@field HealthLinearMult number
---@field HealthDiminishingExponent number
---@field HealthVitalityMult number
local DynamicManager = I.S3ProtectedTable.new {
  inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'Dynamic',
  logPrefix = 'ChimManagerDynamic'
}

local Fatigue = s3lf.fatigue
local Magicka = s3lf.magicka

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

function DynamicManager.canRegenerateFatigue()
  return true
end

local FortifyMagickaEffect = MagickEffect.FortifyMagicka
function DynamicManager:calculateMaxMagicka()
  local BaseMagickaMult
  if types.Player.objectIsInstance(s3lf.object) then
    BaseMagickaMult = self.PCbaseMagickaMultiplier
  else
    BaseMagickaMult = self.NPCbaseMagickaMultiplier
  end

  local fortifyMagickaEffect = s3lf.activeEffects():getEffect(FortifyMagickaEffect).magnitude
  local fortifyMagickaFactor = fortifyMagickaEffect * self.FortifyMagickaMultiplier
  local magickaMultiplier = BaseMagickaMult + fortifyMagickaFactor
  return math.floor(s3lf.intelligence.modified * magickaMultiplier + 0.5)
end

function DynamicManager:overrideNativeMagicka()
  local expectedMaxMagicka = self:calculateMaxMagicka()
  if Magicka.base == expectedMaxMagicka then return end

  local oldMagicka = Magicka.base
  local normalizedMagicka = Magicka.current / Magicka.base
  Magicka.base = expectedMaxMagicka
  Magicka.current = normalizedMagicka * Magicka.base
  self.debugLog('MagickaMgr: Magicka updated from', oldMagicka, 'to', Magicka.base)
end

function DynamicManager:manageMagicka(dt)
  self:overrideNativeMagicka()
end

function DynamicManager.canRegenerateMagicka()
  return s3lf.activeEffects():getEffect('stuntedmagicka').magnitude == 0
end

function DynamicManager.canRegenerateHealth()
  return true
end

function DynamicManager:calculateMaxHealth()
  local endurance = s3lf.endurance.modified
  local base = self.BaseHealth
  local linear = endurance * self.HealthLinearMult
  local vitality = (endurance ^ self.HealthDiminishingExponent) * self.HealthVitalityMult

  return base + linear + vitality
end

function DynamicManager:overrideNativeHealth()
  local expectedMaxHealth = self:calculateMaxHealth()
  if s3lf.health.base == expectedMaxHealth then return end

  local oldHealth = s3lf.health.base
  local normalizedHealth = s3lf.health.current / s3lf.health.base
  s3lf.health.base = expectedMaxHealth
  s3lf.health.current = normalizedHealth * s3lf.health.base
  self.debugLog('HealthMgr: Health updated from', oldHealth, 'to', s3lf.health.base)
end

function DynamicManager:manageHealth(dt)
  self:overrideNativeHealth()
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
      DynamicManager:manageMagicka(dt)
      DynamicManager:manageFatigue(dt)
      DynamicManager:manageHealth(dt)
    end,
  },
}
