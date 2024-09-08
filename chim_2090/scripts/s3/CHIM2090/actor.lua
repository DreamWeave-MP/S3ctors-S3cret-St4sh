-- Add settings for:
-- NPC-specific settings
-- Make plugin to disable vanilla fatigue regen
-- Add climbing :)

local animation = require('openmw.animation')
local async = require('openmw.async')
local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local modInfo = require("scripts.s3.CHIM2090.modInfo")

local rangedWeaponTypes = {
  [types.Weapon.TYPE.MarksmanBow] = true,
  [types.Weapon.TYPE.MarksmanCrossbow] = true,
  [types.Weapon.TYPE.MarksmanThrown] = true,
}

local weaponTypesToSkills = {
  [types.Weapon.TYPE.ShortBladeOneHand] = self.type.stats.skills.shortblade(self),
  [types.Weapon.TYPE.LongBladeOneHand] = self.type.stats.skills.longblade(self),
  [types.Weapon.TYPE.LongBladeTwoHand] = self.type.stats.skills.longblade(self),
  [types.Weapon.TYPE.BluntOneHand] = self.type.stats.skills.bluntweapon(self),
  [types.Weapon.TYPE.BluntTwoClose] = self.type.stats.skills.bluntweapon(self),
  [types.Weapon.TYPE.BluntTwoWide] = self.type.stats.skills.bluntweapon(self),
  [types.Weapon.TYPE.SpearTwoWide] = self.type.stats.skills.spear(self),
  [types.Weapon.TYPE.AxeOneHand] = self.type.stats.skills.axe(self),
  [types.Weapon.TYPE.AxeTwoHand] = self.type.stats.skills.axe(self),
  [types.Weapon.TYPE.MarksmanBow] = self.type.stats.skills.marksman(self),
  [types.Weapon.TYPE.MarksmanCrossbow] = self.type.stats.skills.marksman(self),
  [types.Weapon.TYPE.MarksmanThrown] = self.type.stats.skills.marksman(self),
}

local ActiveEffects = self.type.activeEffects(self)

local agility = self.type.stats.attributes.agility(self)
local endurance = self.type.stats.attributes.endurance(self)
local luck = self.type.stats.attributes.luck(self)
local strength = self.type.stats.attributes.strength(self)
local willpower = self.type.stats.attributes.willpower(self)

local handToHand = self.type.stats.skills.handtohand(self)

local fatigue = self.type.stats.dynamic.fatigue(self)

-- Global State
local currentAttackBonus = 0
local currentStrengthMod = 0
local currentWeightBonus = 0
local currentDeltaTime = 0.
local attackDuration = 0.

local hasHitBuff = false
local hasRangedBonus = false
local hasStrengthBonus = false
local hasWeightBonus = false
local startRamping = false
local startRampDown = false

local globalSettings = storage.globalSection('SettingsGlobal' .. modInfo.name)
local fatigueSettings = storage.globalSection('SettingsGlobal' .. modInfo.name .. 'Fatigue')
local hitChanceSettings = storage.globalSection('SettingsGlobal' .. modInfo.name .. 'HitChance')
local strWghtSettings = storage.globalSection('SettingsGlobal' .. modInfo.name .. 'StrWght')
local critFumbleSettings = storage.globalSection('SettingsGlobal' .. modInfo.name .. 'CritFumble')

-- Global
local DebugLog = globalSettings:get('DebugEnable')
local showMessages = globalSettings:get('MessageEnable')
local UseRangedBonus = globalSettings:get('UseRangedBonus')
-- Fatigue
local FatiguePerSecond = fatigueSettings:get('FatiguePerSecond')
local FatigueEndMult = fatigueSettings:get('FatigueEndMult')
local UseVanillaFatigueFormula = fatigueSettings:get('UseVanillaFatigueFormula')
local MaxFatigueStrMult = fatigueSettings:get('MaxFatigueStrMult')
local MaxFatigueWilMult = fatigueSettings:get('MaxFatigueWilMult')
local MaxFatigueAgiMult = fatigueSettings:get('MaxFatigueAgiMult')
local MaxFatigueEndMult = fatigueSettings:get('MaxFatigueEndMult')
-- Hit Chance
local EnableHitChance = hitChanceSettings:get('EnableHitChance')
local AgilityHitChancePct = hitChanceSettings:get('AgilityHitChancePct')
local LuckHitChancePct = hitChanceSettings:get('LuckHitChancePct')
local MaxAttackBonus = hitChanceSettings:get('PlayerMaxAttackBonus')
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
    print(message)
    -- self:sendEvent("notify", { message = message })
end

local function debugLog(...)
  if not DebugLog then return end
  print(modInfo.logPrefix .. " " .. table.concat({...}, " "))
end

local function isUsingRanged()
  local weapon = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
  if not weapon then return false end
  return rangedWeaponTypes[types.Weapon.records[weapon.recordId].type] or false
end

local function getNativeHitChance()
    local normalizedFatigue = fatigue.current / fatigue.base
    local fatigueTerm = core.getGMST('fFatigueBase') - core.getGMST('fFatigueMult') * (1 - normalizedFatigue)

    local weapon = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
    local weaponType = types.Weapon.records[weapon.recordId].type
    local skill
    if not weapon then
        skill = handToHand.modified
    else
        skill = weaponTypesToSkills[weaponType].modified
    end

    local agilityInfluence = AgilityHitChancePct * agility.modified
    local luckInfluence = LuckHitChancePct * luck.modified

    local attackTerm = (skill + agilityInfluence +  luckInfluence) * fatigueTerm
    -- normally we wouldn't subtract anything but this script screws with the native hit chance
    local attackBonus = ActiveEffects:getEffect("fortifyattack").magnitude - currentAttackBonus
    local blindMagnitude = ActiveEffects:getEffect("blind").magnitude

    return (attackTerm + (attackBonus - blindMagnitude)) / 100
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

local function toggleRangedHitBonus(enable)
  debugLog("Toggling ranged hit chance bonus:",
    'Enable:', tostring(enable),
    'CurrentAttackBonus:', currentAttackBonus,
    'MaxAttackBonus:', MaxAttackBonus,
    "EnableHitChance:", tostring(EnableHitChance))

    if hasHitBuff then
        ActiveEffects:modify(-currentAttackBonus, "fortifyattack")
        currentAttackBonus = 0
        hasHitBuff = false
        startRamping = false
        startRampDown = false
    end

    if not enable or not EnableHitChance or not UseRangedBonus then return end

    currentAttackBonus = MaxAttackBonus

    ActiveEffects:modify(currentAttackBonus, "fortifyattack")
    hasHitBuff = true
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

local function applyRangedAttackBonus(enable)
  if hasHitBuff ~= enable then
    toggleRangedHitBonus(enable)
  end

  if hasStrengthBonus ~= enable then
    toggleStrengthBonus(enable, false)
  end

  hasRangedBonus = enable
end

local function calculateMaxFatigue()
  local fatigueWil = willpower.modified * (MaxFatigueWilMult / 100)
  local fatigueAgi = agility.modified * (MaxFatigueAgiMult / 100)
  local fatigueEnd = endurance.modified * (MaxFatigueEndMult / 100)
  local fatigueStr = strength.modified * (MaxFatigueStrMult / 100)
  return math.floor(fatigueWil + fatigueAgi + fatigueEnd + fatigueStr + 0.5)
end

local function overrideNativeFatigue()
  local expectedMaxFatigue = calculateMaxFatigue()
  if fatigue.base == expectedMaxFatigue then return end

  local normalizedFatigue = fatigue.current / fatigue.base
  fatigue.base = expectedMaxFatigue
  fatigue.current = normalizedFatigue * fatigue.base
end

local settingHandlers = {
  ["SettingsGlobal" .. modInfo.name] = {
    DebugEnable = function(newDebugEnable)
      DebugLog = newDebugEnable
    end,
    MessageEnable = function(newMessageEnable)
      showMessages = newMessageEnable
    end,
    UseRangedBonus = function(newUseRangedBonus)
      UseRangedBonus = newUseRangedBonus
      applyRangedAttackBonus(UseRangedBonus and isUsingRanged())
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. 'Fatigue'] = {
    UseVanillaFatigueFormula = function(newUseVanillaFatigueFormula)
      UseVanillaFatigueFormula = newUseVanillaFatigueFormula
    end,
    FatiguePerSecond = function(newFatiguePerSecond)
      FatiguePerSecond = newFatiguePerSecond
    end,
    FatigueEndMult = function(newFatigueEndMult)
      FatigueEndMult = newFatigueEndMult
    end,
    -- Call the thing that actually updates max fatigue on all of these
    MaxFatigueStrMult = function(newMaxFatigueStrMult)
      MaxFatigueStrMult = newMaxFatigueStrMult
    end,
    MaxFatigueWilMult = function(newMaxFatigueWilMult)
      MaxFatigueWilMult = newMaxFatigueWilMult
    end,
    MaxFatigueAgiMult = function(newMaxFatigueAgiMult)
      MaxFatigueAgiMult = newMaxFatigueAgiMult
    end,
    MaxFatigueEndMult = function(newMaxFatigueEndMult)
      MaxFatigueEndMult = newMaxFatigueEndMult
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. "HitChance"] = {
    EnableHitChance = function(newEnableHitChance)
      if not newEnableHitChance then
        debugLog('Disabling hit chance bonus from setting:',
          'hasHitBuff:', tostring(hasHitBuff),
          'hasRangedBonus:', tostring(hasRangedBonus))
        toggleRangedHitBonus(false)
      end

      EnableHitChance = newEnableHitChance

      if isUsingRanged() then
        debugLog('Enabling hit chance bonus from setting:',
          'hasHitBuff:', tostring(hasHitBuff),
          'hasRangedBonus:', tostring(hasRangedBonus),
          'UseRangedBonus:', tostring(UseRangedBonus))
        toggleRangedHitBonus(true)
      end
    end,
    PlayerMaxAttackBonus = function(newMaxAttackBonus)
      local oldAttackBonus = currentAttackBonus
      MaxAttackBonus = newMaxAttackBonus
      if hasHitBuff then
        ActiveEffects:modify(-currentAttackBonus, "fortifyattack")
        currentAttackBonus = math.min(MaxAttackBonus, oldAttackBonus)
        ActiveEffects:modify(currentAttackBonus, "fortifyattack")
      end
    end,
    AgilityHitChancePct = function(newAgilityHitChancePct)
      AgilityHitChancePct = newAgilityHitChancePct
    end,
    LuckHitChancePct = function(newLuckHitChancePct)
      LuckHitChancePct = newLuckHitChancePct
    end,
  },
  ["SettingsGlobal" .. modInfo.name .. "StrWght"] = {
    EnableStrWght = function(newEnableStrWght)
      if not newEnableStrWght then
        debugLog('Disabling strength bonus from setting:',
          'hasStrWghtBuff:', tostring(hasStrengthBonus),
          'hasRangedBonus:', tostring(hasRangedBonus))
        toggleStrengthBonus(false)
      end

      EnableStrWght = newEnableStrWght

      if isUsingRanged() and UseRangedBonus then
        debugLog('Enabling strength bonus from setting:',
          'hasStrWghtBuff:', tostring(hasStrengthBonus),
          'hasRangedBonus:', tostring(hasRangedBonus))
        toggleStrengthBonus(true)
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

local attackStartKeys = {
  ["weapononehand:thrust start"] = "weapononehand: thrust ",
  ["weapononehand:chop start"] = "weapononehand: chop ",
  ["weapononehand:slash start"] = "weapononehand: slash ",
  ["weapontwowide:thrust start"] = "weapontwowide: thrust ",
  ["weapontwowide:chop start"] = "weapontwowide: chop ",
  ["weapontwowide:slash start"] = "weapontwowide: slash ",
  ["weapontwohand:thrust start"] = "weapontwohand: thrust ",
  ["weapontwohand:chop start"] =  "weapontwohand: chop ",
  ["weapontwohand:slash start"] = "weapontwohand: slash ",
  ["handtohand:thrust start"] = "handtohand: thrust ",
  ["handtohand:chop start"] =  "handtohand: chop ",
  ["handtohand:slash start"] = "handtohand: slash ",
}

local minAttackKeys = {
  ["thrust min attack"] = true,
  ["chop min attack"] = true,
  ["slash min attack"] = true,
}

local maxAttackKeys = {
  ["chop small follow stop"] = true,
  ["thrust small follow stop"] = true,
  ["slash small follow stop"] = true,
}

local function handleAttackBonus(groupname, key)
  if groupname == "crossbow" or groupname == "bowandarrow" or groupname == "throwweapon" then
    return
  end

  local attackStartKey = attackStartKeys[groupname .. ":" .. key]

  if attackStartKey then
    local minAttackTime = animation.getTextKeyTime(self, attackStartKey .. "min attack")

    local maxAttackTime = animation.getTextKeyTime(self, attackStartKey .. "max attack")

    attackDuration = maxAttackTime - minAttackTime

    toggleStrengthBonus(true, true)

  elseif minAttackKeys[key] and not hasHitBuff and EnableHitChance then
    hasHitBuff = true
    startRamping = true
    currentAttackBonus = 0
    currentDeltaTime = 0.

  elseif maxAttackKeys[key] then

    toggleStrengthBonus(false)

    if hasHitBuff then
      if not startRamping then startRamping = true end
      currentDeltaTime = 0.
      startRampDown = true
    end
  end
end

I.AnimationController.addTextKeyHandler('', handleAttackBonus)

local function applyPerFrameAttackBonus(dt)

    if not startRamping then return end

    currentDeltaTime = currentDeltaTime + dt
    local rateToMax = math.min(currentDeltaTime / attackDuration, 1)

    local deltaThisFrame

    if startRampDown then
        deltaThisFrame = currentAttackBonus * rateToMax
    else
        deltaThisFrame = (MaxAttackBonus * rateToMax) - currentAttackBonus
    end

    deltaThisFrame = math.floor(deltaThisFrame + 0.5)

    if deltaThisFrame <= 0 then return end

    if startRampDown then deltaThisFrame = -deltaThisFrame end

    ActiveEffects:modify(deltaThisFrame, "fortifyattack")
    currentAttackBonus = currentAttackBonus + deltaThisFrame

    debugLog("Current attack bonus:", currentAttackBonus, "magnitude. Delta this frame:", deltaThisFrame)

    if currentAttackBonus == 0 and startRampDown then
        currentDeltaTime = 0
        startRampDown = false
        startRamping = false
        hasHitBuff = false
    end
end

local function handleFatigueRegen(dt)
  if fatigue.current >= fatigue.base then return end

  local fatigueThisFrame

  if UseVanillaFatigueFormula then
    fatigueThisFrame = FatiguePerSecond + (FatigueEndMult * endurance.modified)
  else
    fatigueThisFrame = FatiguePerSecond
  end

  fatigue.current = math.min(fatigue.base, fatigue.current + (fatigueThisFrame * dt))
end

local function manageFatigue(dt)
  overrideNativeFatigue()
  handleFatigueRegen(dt)
end

local function handleRangedAttackBonus()
  if not UseRangedBonus then return end

  if isUsingRanged() and not hasRangedBonus then
    applyRangedAttackBonus(true)
  elseif not isUsingRanged() and hasRangedBonus then
    applyRangedAttackBonus(false)
  end
end

local function onSave()
  return {
    hasHitBuff = hasHitBuff,
    hasRangedBonus = hasRangedBonus,
    hasStrengthBonus = hasStrengthBonus,
    hasWeightBonus = hasWeightBonus,
    startRampDown = startRampDown,
    startRamping = startRamping,
    attackDuration = attackDuration,
    currentAttackBonus = currentAttackBonus,
    currentDeltaTime = currentDeltaTime,
    currentStrengthMod = currentStrengthMod,
    currentWeightBonus = currentWeightBonus,
  }
end

local function onLoad(state)
  hasHitBuff = state.hasHitBuff or false
  hasRangedBonus = state.hasRangedBonus or false
  hasStrengthBonus = state.hasStrengthBonus or false
  hasWeightBonus = state.hasWeightBonus or false
  startRampDown = state.startRampDown or false
  startRamping = state.startRamping or false
  attackDuration = state.attackDuration or 0
  currentAttackBonus = state.currentAttackBonus or 0
  currentDeltaTime = state.currentDeltaTime or 0
  currentStrengthMod = state.currentStrengthMod or 0
  currentWeightBonus = state.currentWeightBonus or 0
end

return {
  engineHandlers = {
    onFrame = function(dt)
      handleRangedAttackBonus()
      manageFatigue(dt)
      applyPerFrameAttackBonus(dt)
    end,
    onSave = onSave,
    onLoad = onLoad,
  }
}
