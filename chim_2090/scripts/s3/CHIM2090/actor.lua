-- Add settings for:
-- NPC-specific settings
-- Make plugin to disable vanilla fatigue regen
-- Add climbing :)

local async = require('openmw.async')
local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local modInfo = require("scripts.s3.CHIM2090.modInfo")

print(string.format("%s loaded version %s. Thank you for playing %s! <3",
                    modInfo.logPrefix,
                    modInfo.version,
                    modInfo.name))

local ActiveEffects = self.type.activeEffects(self)

local luck = self.type.stats.attributes.luck(self)
local strength = self.type.stats.attributes.strength(self)

local fatigue = self.type.stats.dynamic.fatigue(self)

local currentStrengthMod = 0
local currentWeightBonus = 0

local hasStrengthBonus = false
local hasWeightBonus = false

local globalSettings = storage.globalSection('SettingsGlobal' .. modInfo.name)
local strWghtSettings = storage.globalSection('SettingsGlobal' .. modInfo.name .. 'StrWght')
local critFumbleSettings = storage.globalSection('SettingsGlobal' .. modInfo.name .. 'CritFumble')

-- Global
local DebugLog = globalSettings:get('DebugEnable')
local showMessages = globalSettings:get('MessageEnable')
-- Strength
local EnableStrWght = strWghtSettings:get('EnableStrWght')
local MaxStrengthMultiplier = strWghtSettings:get('MaxStrengthMultiplier')
-- Crit and Fumble
local EnableCritFumble = critFumbleSettings:get('EnableCritFumble')
local CritChancePercent = critFumbleSettings:get('CritChancePercent')
local CritLuckPercent = critFumbleSettings:get('CritLuckPercent')
local CritDamageMultiplier = critFumbleSettings:get('CritDamageMultiplier')
local FumbleBaseChance = critFumbleSettings:get('FumbleBaseChance')
local FumbleChanceScale = critFumbleSettings:get('FumbleChanceScale')
local FumbleDamagePercent = critFumbleSettings:get('FumbleDamagePercent')

local function notifyPlayer(message)
    if self.type ~= types.Player or not showMessages then return end
    I.chimInterfacePlayer.notifyPlayer(message)
end

local function debugLog(...)
  if not DebugLog then return end
  print(modInfo.logPrefix .. " " .. table.concat({...}, " "))
end

local function getStrengthModifier(hitChance)
  local localHitChance = hitChance or math.min(MaxStrengthMultiplier, getNativeHitChance())
  return math.floor(((strength.modified * localHitChance) - strength.modified) + .5)
end

local function setWeightBonus(enable)
    local encumbranceMult = core.getGMST('fEncumbranceStrMult')

    currentWeightBonus = math.abs(encumbranceMult * currentStrengthMod)
    if not enable then currentWeightBonus = -currentWeightBonus end

    local targetEffect

    if currentStrengthMod < 0 then
        targetEffect = 'feather'
    else
        targetEffect = 'burden'
    end

    debugLog("Current weight bonus:", currentWeightBonus, " target effect:", targetEffect, " enable:" , tostring(enable),
            "burden magnitude:", ActiveEffects:getEffect("burden").magnitude,
            "feather magnitude:", ActiveEffects:getEffect("feather").magnitude)

    ActiveEffects:modify(currentWeightBonus, targetEffect)
    hasWeightBonus = enable
end

local function setDamageBonus()
  if hasStrengthBonus then return end

  local roll = math.random()
  local luckMod = (luck.modified / 1000) * CritLuckPercent
  local hitChance = math.min(MaxStrengthMultiplier, getNativeHitChance())
  local critChance = (hitChance / 100) * (CritChancePercent + luckMod * 50)
  local fumblePct = FumbleBaseChance / 100.0
  local fumbleScalePct = FumbleChanceScale / 100.0
  local fumbleChance = math.max(0.0, (fumblePct + (1.0 - (hitChance + luckMod)) * fumbleScalePct))

  debugLog("Roll:", roll, "Hit Chance:", hitChance,
    "Crit Chance:", critChance, "Fumble Chance:", fumbleChance,
    "Luck Mod:", luckMod)

  if EnableCritFumble then
    if roll < critChance then
      notifyPlayer("Critical Hit!")
      hitChance = hitChance * CritDamageMultiplier
    elseif roll < fumbleChance then
      notifyPlayer("Fumble!")
      hitChance = (hitChance / 100) * FumbleDamagePercent
    end
  end

  currentStrengthMod = getStrengthModifier(hitChance)

  strength.modifier = strength.modifier + currentStrengthMod
  hasStrengthBonus = true
end

local function toggleStrengthBonus(enable, melee)
    if hasWeightBonus then
        setWeightBonus(false)
    end

    if hasStrengthBonus then
        strength.modifier = strength.modifier - currentStrengthMod
        currentStrengthMod = 0
        hasStrengthBonus = false
    end

  debugLog("Toggling strength bonus:", tostring(enable),
    "current strength mod:", currentStrengthMod,
    "strength modifier:", strength.modifier,
    "has strength bonus:", tostring(hasStrengthBonus),
    "burden magnitude:", ActiveEffects:getEffect("burden").magnitude,
    "feather magnitude:", ActiveEffects:getEffect("feather").magnitude)

    if not enable or not EnableStrWght then return end

    if melee then
        setDamageBonus()
    else
      -- Hit chance is determined by normalized fatigue
      -- so we need to calculate the strength bonus based on the hit chance
      -- But for ranged weapons we only do it once, so fatigue should be equal to base
      -- when we do it to avoid inconsistency at different fatigue levels
      local oldFatigue = fatigue.current
      fatigue.current = fatigue.base
      currentStrengthMod = getStrengthModifier()
      fatigue.current = oldFatigue
      strength.modifier = strength.modifier + currentStrengthMod
      hasStrengthBonus = true
    end

    setWeightBonus(true)
end

local settingHandlers = {
  ["SettingsGlobal" .. modInfo.name] = {
    DebugEnable = function(newDebugEnable)
      if self.type ~= types.Player then return end
      DebugLog = newDebugEnable
      I.s3ChimChance.Manager.toggleDebug(DebugLog)
      I.chimInterfacePlayer.notifyPlayer(modInfo.logPrefix, 'Debug messages enabled: ', tostring(DebugLog))
    end,
    MessageEnable = function(newMessageEnable)
      showMessages = newMessageEnable
    end,
    UseRangedBonus = function(newUseRangedBonus)
      I.s3ChimChance.Manager:toggleRangedBonus(newUseRangedBonus)
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. 'Fatigue'] = {
    UseVanillaFatigueFormula = function(newUseVanillaFatigueFormula)
      I.s3ChimFatigue.Manager.UseVanillaFatigueFormula = newUseVanillaFatigueFormula
    end,
    FatiguePerSecond = function(newFatiguePerSecond)
      I.s3ChimFatigue.Manager.FatiguePerSecond = newFatiguePerSecond
    end,
    FatigueEndMult = function(newFatigueEndMult)
      I.s3ChimFatigue.Manager.FatigueEndMult = newFatigueEndMult
    end,
    -- Call the thing that actually updates max fatigue on all of these
    MaxFatigueStrMult = function(newMaxFatigueStrMult)
      I.s3ChimFatigue.Manager.MaxFatigueStrMult = newMaxFatigueStrMult
    end,
    MaxFatigueWilMult = function(newMaxFatigueWilMult)
      I.s3ChimFatigue.Manager.MaxFatigueWilMult = newMaxFatigueWilMult
    end,
    MaxFatigueAgiMult = function(newMaxFatigueAgiMult)
      I.s3ChimFatigue.Manager.MaxFatigueAgiMult = newMaxFatigueAgiMult
    end,
    MaxFatigueEndMult = function(newMaxFatigueEndMult)
      I.s3ChimFatigue.Manager.MaxFatigueEndMult = newMaxFatigueEndMult
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. "HitChance"] = {
    EnableHitChance = function(newEnableHitChance)
      I.s3ChimChance.Manager:toggleHitChance(newEnableHitChance)
    end,
    PlayerMaxAttackBonus = function(newMaxAttackBonus)
      I.s3ChimChance.Manager:updateMaxAttackBonus(newMaxAttackBonus)
    end,
    AgilityHitChancePct = function(newAgilityHitChancePct)
      I.s3ChimChance.Manager.AgilityHitChancePct = newAgilityHitChancePct
    end,
    LuckHitChancePct = function(newLuckHitChancePct)
      I.s3ChimChance.Manager.LuckHitChancePct = newLuckHitChancePct
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. "StrWght"] = {
    EnableStrWght = function(newEnableStrWght)
      local hitManager = I.s3ChimChance.Manager

      if not newEnableStrWght then
        debugLog('Disabling strength bonus from setting:',
          'hasStrWghtBuff:', tostring(hasStrengthBonus),
          'hasRangedBonus:', tostring(hitManager.hasRangedBonus))
        -- toggleStrengthBonus(false)
      end

      EnableStrWght = newEnableStrWght

      if hitManager.isUsingRanged() and hitManager.UseRangedBonus then
        debugLog('Enabling strength bonus from setting:',
          'hasStrWghtBuff:', tostring(hasStrengthBonus),
          'hasRangedBonus:', tostring(hitManager.hasRangedBonus))
        -- toggleStrengthBonus(true)
      end
    end,
    MaxStrengthMultiplier = function(newMaxStrengthMultiplier)
      MaxStrengthMultiplier = newMaxStrengthMultiplier
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. "CritFumble"] = {
    EnableCritFumble = function(newEnableCritFumble)
      EnableCritFumble = newEnableCritFumble
    end,
    CritChancePercent = function(newCritChancePercent)
      CritChancePercent = newCritChancePercent
    end,
    CritLuckPercent = function(newCritLuckPercent)
      CritLuckPercent = newCritLuckPercent
    end,
    CritDamageMultiplier = function(newCritDamageMultiplier)
      CritDamageMultiplier = newCritDamageMultiplier
    end,
    FumbleBaseChance = function(newFumbleBaseChance)
      FumbleBaseChance = newFumbleBaseChance
    end,
    FumbleChanceScale = function(newFumbleChanceScale)
      FumbleChanceScale = newFumbleChanceScale
    end,
    FumbleDamagePercent = function(newFumbleDamagePercent)
      FumbleDamagePercent = newFumbleDamagePercent
    end,
  },
}

local updateSection = async:callback(function(section, key)
    assert(settingHandlers[section] ~= nil, 'Unsupported section: ' .. section)
    local storageSection = storage.globalSection(section)

    local function logSettingChanged(newValue)
      debugLog("Changed", key, "in", section, "to", tostring(newValue))
    end

    if key then
      assert(settingHandlers[section][key] ~= nil, 'Unsupported key: ' .. key .. " in section: " .. section)
      local newValue = storageSection:get(key)
      settingHandlers[section][key](newValue)
      logSettingChanged(newValue)
    else
      for subKey, updateFunction in pairs(settingHandlers[section]) do
        local newValue = storageSection:get(subKey)
        updateFunction(newValue)
        logSettingChanged(newValue)
      end
    end
end)

for section, _ in pairs(settingHandlers) do
  storage.globalSection(section):subscribe(updateSection)
end

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.l10nName,
	name = "CHIM 2090",
	description = "Manages actor fatigue, carry weight, hit chance, and strength in combat."
}

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
  engineHandlers = {
    onSave = onSave,
    onLoad = onLoad,
  }
}
