local gameSelf = require('openmw.self')

local agility = gameSelf.type.stats.attributes.agility(gameSelf)
local endurance = gameSelf.type.stats.attributes.endurance(gameSelf)
local fatigue = gameSelf.type.stats.dynamic.fatigue(gameSelf)
local strength = gameSelf.type.stats.attributes.strength(gameSelf)
local willpower = gameSelf.type.stats.attributes.willpower(gameSelf)

local modInfo = require('scripts.s3.CHIM2090.modInfo')
local Manager = require('scripts.s3.CHIM2090.protectedTable')

local FatigueManager = Manager('SettingsGlobal' .. modInfo.name .. 'Fatigue')

function FatigueManager:calculateMaxFatigue()
  local fatigueWil = willpower.modified * (self.MaxFatigueWilMult / 100)
  local fatigueAgi = agility.modified * (self.MaxFatigueAgiMult / 100)
  local fatigueEnd = endurance.modified * (self.MaxFatigueEndMult / 100)
  local fatigueStr = strength.modified * (self.MaxFatigueStrMult / 100)
  return math.floor(fatigueWil + fatigueAgi + fatigueEnd + fatigueStr + 0.5)
end

function FatigueManager:overrideNativeFatigue()
  local expectedMaxFatigue = self:calculateMaxFatigue()
  if fatigue.base == expectedMaxFatigue then return end

  local oldFatigue = fatigue.base
  local normalizedFatigue = fatigue.current / fatigue.base
  fatigue.base = expectedMaxFatigue
  fatigue.current = normalizedFatigue * fatigue.base
  self.debugLog('FatigueMgr: Fatigue updated from', oldFatigue, 'to', fatigue.base)
end

function FatigueManager:handleFatigueRegen(dt)
  if fatigue.current >= fatigue.base then return end

  local fatigueThisFrame

  if self.UseVanillaFatigueFormula then
    fatigueThisFrame = self.FatiguePerSecond + (self.FatigueEndMult * endurance.modified)
  else
    fatigueThisFrame = self.FatiguePerSecond
  end

  fatigueThisFrame = fatigue.current + (fatigueThisFrame * dt)

  fatigue.current = math.min(fatigue.base, fatigueThisFrame)
end

function FatigueManager:manageFatigue(dt)
  self:overrideNativeFatigue()
  self:handleFatigueRegen(dt)
end

return {
  interfaceName = 's3ChimFatigue',
  interface = {
    version = modInfo.version,
    Manager = FatigueManager,
  },
  engineHandlers = {
    onUpdate = function(dt)
      FatigueManager:manageFatigue(dt)
    end,
  },
}
