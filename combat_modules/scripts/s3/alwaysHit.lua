-- [[
--
--]]

local animation = require('openmw.animation')
local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local ui = require('openmw.ui')

local debugLog = false
-- Make configurable
local MaxAttackBonus = 100
local FatiguePerSecond = 3
local showMessages = true
-- Crit Chance vars
local CritChancePercent = 4
local CritLuckPercent = 1
local CritChanceMultiplier = 4
local MaxStrengthMultiplier = 1.5
-- Fumble Chance vars
local FumbleBaseChance = 0.03
local FumbleChanceScale = 0.1
local FumbleDamagePercent = 25

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

local rangedWeaponTypes = {
  [types.Weapon.TYPE.MarksmanBow] = true,
  [types.Weapon.TYPE.MarksmanCrossbow] = true,
  [types.Weapon.TYPE.MarksmanThrown] = true,
}

local weaponTypesToSkills = {
  [types.Weapon.TYPE.ShortBladeOneHand] = self.type.stats.skills.shortblade,
  [types.Weapon.TYPE.LongBladeOneHand] = self.type.stats.skills.longblade,
  [types.Weapon.TYPE.LongBladeTwoHand] = self.type.stats.skills.longblade,
  [types.Weapon.TYPE.BluntOneHand] = self.type.stats.skills.bluntweapon,
  [types.Weapon.TYPE.BluntTwoClose] = self.type.stats.skills.bluntweapon,
  [types.Weapon.TYPE.BluntTwoWide] = self.type.stats.skills.bluntweapon,
  [types.Weapon.TYPE.SpearTwoWide] = self.type.stats.skills.spear,
  [types.Weapon.TYPE.AxeOneHand] = self.type.stats.skills.axe,
  [types.Weapon.TYPE.AxeTwoHand] = self.type.stats.skills.axe,
  [types.Weapon.TYPE.MarksmanBow] = self.type.stats.skills.marksman,
  [types.Weapon.TYPE.MarksmanCrossbow] = self.type.stats.skills.marksman,
  [types.Weapon.TYPE.MarksmanThrown] = self.type.stats.skills.marksman,
}

local agility = self.type.stats.attributes.agility(self)
local luck = self.type.stats.attributes.luck(self)
local strength = self.type.stats.attributes.strength(self)

local handToHand = self.type.stats.skills.handtohand(self)

local fatigue = self.type.stats.dynamic.fatigue(self)

local function notifyPlayer(message)
    ui.showMessage(message)
    -- if self.recordId ~= 'player' or not showMessages then return end
    -- self:sendEvent("notify", { message = message })
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
        skill = weaponTypesToSkills[weaponType](self).modified
    end

    local attackTerm = (skill + .2 * agility.modified + .1 * luck.modified) * fatigueTerm
    -- normally we wouldn't subtract anything but this script screws with the native hit chance
    local attackBonus = self.type.activeEffects(self):getEffect("fortifyattack").magnitude - currentAttackBonus
    local blindMagnitude = self.type.activeEffects(self):getEffect("blind").magnitude

    return (attackTerm + (attackBonus - blindMagnitude)) / 100
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

    print('setting weight bonus', currentWeightBonus, targetEffect, " current magnitude is: "
          .. self.type.activeEffects(self):getEffect('feather').magnitude,
          self.type.activeEffects(self):getEffect('burden').magnitude)

    self.type.activeEffects(self):modify(currentWeightBonus, targetEffect)
    hasWeightBonus = enable
end

local function getStrengthModifier()
  local hitChance = math.min(MaxStrengthMultiplier, getNativeHitChance())
  return math.floor(((strength.modified * hitChance) - strength.modified) + .5)
end

local function setDamageBonus()
  if hasStrengthBonus then return end

  local roll = math.random()
  local luckMod = (luck.modified / 1000) * CritLuckPercent
  local hitChance = math.min(MaxStrengthMultiplier, getNativeHitChance())
  local critChance = (hitChance / 100) * (CritChancePercent + luckMod * 50)
  local fumbleChance = math.max(0.0, (FumbleBaseChance + (1.0 - (hitChance + luckMod)) * FumbleChanceScale))

  print(roll, fumbleChance, luckMod, critChance)

  if roll < critChance then
    notifyPlayer("Critical Hit!")
    hitChance = hitChance * CritChanceMultiplier
  elseif roll < fumbleChance then
    notifyPlayer("Fumble!")
    hitChance = (hitChance / 100) * FumbleDamagePercent
  end

  currentStrengthMod = getStrengthModifier()

  strength.modifier = strength.modifier + currentStrengthMod
  hasStrengthBonus = true
end

local function handleAttackBonus(groupname, key)
  if groupname == "crossbow" or groupname == "bowandarrow" or groupname == "throwweapon" then
    -- handleRangedAttackBonus()
    return
  end

  local attackStartKey = attackStartKeys[groupname .. ":" .. key]

  if attackStartKey then
    local minAttackTime = animation.getTextKeyTime(self, attackStartKey .. "min attack")

    local maxAttackTime = animation.getTextKeyTime(self, attackStartKey .. "max attack")

    attackDuration = maxAttackTime - minAttackTime

    if hasWeightBonus then
      setWeightBonus(false)
    end

    setDamageBonus()
    setWeightBonus(true)

  elseif minAttackKeys[key] and not hasHitBuff then
    -- if we save the original behavior as an option this needs to be behind it also
    hasHitBuff = true
    startRamping = true
    currentAttackBonus = 0
    currentDeltaTime = 0.

  elseif maxAttackKeys[key] then

    if hasStrengthBonus then
      setWeightBonus(false)
      strength.modifier = strength.modifier - currentStrengthMod
      currentStrengthMod = 0
      hasStrengthBonus = false
    end

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

    self.type.activeEffects(self):modify(deltaThisFrame, "fortifyattack")
    currentAttackBonus = currentAttackBonus + deltaThisFrame

    if debugLog then
        print("Current attack bonus: " .. currentAttackBonus .. " magnitude" .. " delta this frame: " .. deltaThisFrame)
    end

    if currentAttackBonus == 0 and startRampDown then
        currentDeltaTime = 0
        startRampDown = false
        startRamping = false
        hasHitBuff = false
    end
end

local function handleFatigueRegen(dt)
    if fatigue.current < fatigue.base then
        fatigue.current = fatigue.current + (FatiguePerSecond * dt)
    end
end

local function applyRangedAttackBonus(enable)
    currentAttackBonus = MaxAttackBonus

    if not enable then
      currentAttackBonus = -currentAttackBonus
      currentStrengthMod = -currentStrengthMod
      setWeightBonus(enable)
    else
      setWeightBonus(enable)
      currentStrengthMod = getStrengthModifier()
    end


    self.type.activeEffects(self):modify(currentAttackBonus, "fortifyattack")
    strength.modifier = strength.modifier + currentStrengthMod

    hasStrengthBonus = enable
    hasHitBuff = enable
    hasRangedBonus = enable
end

local function handleRangedAttackBonus()
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
      handleFatigueRegen(dt)
      applyPerFrameAttackBonus(dt)
    end,
    -- eventHandlers = {
    --   notify = function() if self.type ~= types.Player then return end end,
    -- },
    onSave = onSave,
    onLoad = onLoad,
  }
}
