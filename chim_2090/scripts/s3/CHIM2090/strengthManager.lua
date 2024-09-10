-- Add settings for:
-- NPC-specific settings
-- Fix regen when sleeping
-- Add climbing :)

local async = require('openmw.async')
local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local modInfo = require("scripts.s3.CHIM2090.modInfo")
local s3lf = require('scripts.s3.lf')

local groupName = 'SettingsGlobal' .. modInfo.name .. 'Damage'
local StrengthManager = require("scripts.s3.CHIM2090.protectedTable")(groupName)

local ActiveEffects = s3lf.activeEffects()

local Luck = s3lf.luck
local Strength = s3lf.strength

local Fatigue = s3lf.fatigue

local currentStrengthMod = 0
local currentWeightBonus = 0

local hasStrengthBonus = false
local hasWeightBonus = false

function StrengthManager:getStrengthModifier(hitChance)
  local localHitChance = hitChance or math.min(self.MaxStrengthMultiplier, I.s3ChimChance.Manager:getNativeHitChance())
  return math.floor(((Strength.modified * localHitChance) - Strength.modified) + .5)
end

function StrengthManager:setWeightBonus(enable)
    local encumbranceMult = core.getGMST('fEncumbranceStrMult')

    currentWeightBonus = math.abs(encumbranceMult * currentStrengthMod)
    if not enable then currentWeightBonus = -currentWeightBonus end

    local targetEffect

    if currentStrengthMod < 0 then
        targetEffect = 'feather'
    else
        targetEffect = 'burden'
    end

    self.debugLog("Current weight bonus:", currentWeightBonus, " target effect:", targetEffect, " enable:" , tostring(enable),
            "burden magnitude:", ActiveEffects:getEffect("burden").magnitude,
            "feather magnitude:", ActiveEffects:getEffect("feather").magnitude)

    ActiveEffects:modify(currentWeightBonus, targetEffect)
    hasWeightBonus = enable
end

function StrengthManager:setDamageBonus()
  if hasStrengthBonus then return end

  local roll = math.random()
  local luckMod = (Luck.modified / 1000) * self.CritLuckPercent
  local hitChance = math.min(self.MaxStrengthMultiplier, I.s3ChimChance.Manager:getNativeHitChance())
  local critChance = (hitChance / 100) * (self.CritChancePercent + luckMod * 50)
  local fumblePct = self.FumbleBaseChance / 100.0
  local fumbleScalePct = self.FumbleChanceScale / 100.0
  local fumbleChance = math.max(0.0, (fumblePct + (1.0 - (hitChance + luckMod)) * fumbleScalePct))

  self.debugLog("Roll:", roll, "Hit Chance:", hitChance,
    "Crit Chance:", critChance, "Fumble Chance:", fumbleChance,
    "Luck Mod:", luckMod)

  if self.EnableCritFumble then
    if roll < critChance then
      self.notifyPlayer("Critical Hit!")
      hitChance = hitChance * self.CritDamageMultiplier
    elseif roll < fumbleChance then
      self.notifyPlayer("Fumble!")
      hitChance = (hitChance / 100) * self.FumbleDamagePercent
    end
  end

  currentStrengthMod = self:getStrengthModifier(hitChance)

  Strength.modifier = Strength.modifier + currentStrengthMod
  hasStrengthBonus = true
end

function StrengthManager:toggleStrengthBonus(enable, melee)
    if hasWeightBonus then
        self:setWeightBonus(false)
    end

    if hasStrengthBonus then
        Strength.modifier = Strength.modifier - currentStrengthMod
        currentStrengthMod = 0
        hasStrengthBonus = false
    end

  self.debugLog("Toggling strength bonus:", tostring(enable),
    "current strength mod:", currentStrengthMod,
    "strength modifier:", Strength.modifier,
    "has strength bonus:", tostring(hasStrengthBonus),
    "burden magnitude:", ActiveEffects:getEffect("burden").magnitude,
    "feather magnitude:", ActiveEffects:getEffect("feather").magnitude)

    if not enable or not self.EnableStrWght then return end

    if melee then
        self:setDamageBonus()
    else
      -- Hit chance is determined by normalized fatigue
      -- so we need to calculate the strength bonus based on the hit chance
      -- But for ranged weapons we only do it once, so fatigue should be equal to base
      -- when we do it to avoid inconsistency at different fatigue levels
      local oldFatigue = Fatigue.current
      Fatigue.current = Fatigue.base
      currentStrengthMod = self:getStrengthModifier()
      Fatigue.current = oldFatigue
      Strength.modifier = Strength.modifier + currentStrengthMod
      hasStrengthBonus = true
    end

    self:setWeightBonus(true)
end

local function updateStrengthMgr(section, key)
  local hitManager = I.s3ChimChance.Manager
  if key == nil
    or key == 'EnableStrWght'
    or key == 'MaxStrengthMultiplier' then
    StrengthManager:toggleStrengthBonus(hitManager.isUsingRanged() and hitManager.UseRangedBonus)
  end

  if key then
    StrengthManager.debugLog('Updated', key, 'in', section, 'to', tostring(StrengthManager[key]))
  else
    StrengthManager.debugLog('Updated StrengthManager:', StrengthManager)
  end
end

storage.globalSection(groupName):subscribe(async:callback(updateStrengthMgr))

local function onSave()
  return {
    hasStrengthBonus = hasStrengthBonus,
    hasWeightBonus = hasWeightBonus,
    currentStrengthMod = currentStrengthMod,
    currentWeightBonus = currentWeightBonus,
  }
end

local function onLoad(state)
  hasStrengthBonus = state.hasStrengthBonus or false
  hasWeightBonus = state.hasWeightBonus or false
  currentStrengthMod = state.currentStrengthMod or 0
  currentWeightBonus = state.currentWeightBonus or 0
end

return {
  interfaceName = 's3ChimDamage',
  interface = {
    version = modInfo.version,
    Manager = StrengthManager,
  },
  engineHandlers = {
    onSave = onSave,
    onLoad = onLoad,
  }
}
