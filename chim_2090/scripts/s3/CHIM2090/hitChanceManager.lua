local animation = require('openmw.animation')
local async = require('openmw.async')
local core = require('openmw.core')
local s3lf = require('scripts.s3.lf')
local storage = require('openmw.storage')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

local groupName = 'SettingsGlobal' .. modInfo.name .. 'HitChance'
local HitManager = require('scripts.s3.CHIM2090.protectedTable')(groupName)

local ActiveEffects = s3lf.activeEffects()

local weaponTypes = types.Weapon.TYPE
local weaponTypesToSkills = {
  [weaponTypes.ShortBladeOneHand] = s3lf.shortblade,
  [weaponTypes.LongBladeOneHand] = s3lf.longblade,
  [weaponTypes.LongBladeTwoHand] = s3lf.longblade,
  [weaponTypes.BluntOneHand] = s3lf.bluntweapon,
  [weaponTypes.BluntTwoClose] = s3lf.bluntweapon,
  [weaponTypes.BluntTwoWide] = s3lf.bluntweapon,
  [weaponTypes.SpearTwoWide] = s3lf.spear,
  [weaponTypes.AxeOneHand] = s3lf.axe,
  [weaponTypes.AxeTwoHand] = s3lf.axe,
  [weaponTypes.MarksmanBow] = s3lf.marksman,
  [weaponTypes.MarksmanCrossbow] = s3lf.marksman,
  [weaponTypes.MarksmanThrown] = s3lf.marksman,
}

local keys = {
  attackStart = {
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
  },
  minAttack = {
    ["thrust min attack"] = true,
    ["chop min attack"] = true,
    ["slash min attack"] = true,
  },
  maxAttack = {
    ["chop small follow stop"] = true,
    ["thrust small follow stop"] = true,
    ["slash small follow stop"] = true,
  },
}

local rangedWeaponTypes = {
  [types.Weapon.TYPE.MarksmanBow] = true,
  [types.Weapon.TYPE.MarksmanCrossbow] = true,
  [types.Weapon.TYPE.MarksmanThrown] = true,
}

local attackDuration = 0.
local currentAttackBonus = 0
local currentDeltaTime = 0.
local hasHitBuff = false
local hasRangedBonus = false
local lastRangedState = false
local startRamping = false
local startRampDown = false

function HitManager.isUsingRanged()
  local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
  if not weapon then return false end
  return rangedWeaponTypes[types.Weapon.records[weapon.recordId].type] or false
end

function HitManager:getNativeHitChance()
    local normalizedFatigue = s3lf.fatigue.current / s3lf.fatigue.base
    local fatigueTerm = core.getGMST('fFatigueBase') - core.getGMST('fFatigueMult') * (1 - normalizedFatigue)

    local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
    local weaponType = s3lf.From(weapon).record.type
    local skill
    if not weapon then
        skill = s3lf.handtohand.modified
    else
        skill = weaponTypesToSkills[weaponType].modified
    end

    local agilityInfluence = self.AgilityHitChancePct * s3lf.agility.modified
    local luckInfluence = self.LuckHitChancePct * s3lf.luck.modified

    local attackTerm = (skill + agilityInfluence +  luckInfluence) * fatigueTerm
    -- normally we wouldn't subtract anything but this script screws with the native hit chance
    local attackBonus = ActiveEffects:getEffect("fortifyattack").magnitude - currentAttackBonus
    local blindMagnitude = ActiveEffects:getEffect("blind").magnitude

    return (attackTerm + (attackBonus - blindMagnitude)) / 100
end

function HitManager:handleAttackBonus(groupname, key)
  if groupname == "crossbow" or groupname == "bowandarrow" or groupname == "throwweapon" then
    return
  end

  local attackStartKey = keys.attackStart[groupname .. ":" .. key]

  if attackStartKey then
    local minAttackTime = animation.getTextKeyTime(s3lf.object, attackStartKey .. "min attack")

    local maxAttackTime = animation.getTextKeyTime(s3lf.object, attackStartKey .. "max attack")

    attackDuration = maxAttackTime - minAttackTime

    I.s3ChimDamage.Manager:toggleStrengthBonus(true, true)

  elseif keys.minAttack[key] and not hasHitBuff and self.EnableHitChance then
    hasHitBuff = true
    startRamping = true
    currentAttackBonus = 0
    currentDeltaTime = 0.

  elseif keys.maxAttack[key] then

    I.s3ChimDamage.Manager:toggleStrengthBonus(false)

    if hasHitBuff then
      if not startRamping then startRamping = true end
      currentDeltaTime = 0.
      startRampDown = true
    end
  end
end

I.AnimationController.addTextKeyHandler('', function(...) HitManager:handleAttackBonus(...) end)

function HitManager:applyPerFrameAttackBonus(dt)

    if not startRamping then return end

    currentDeltaTime = currentDeltaTime + dt
    local rateToMax = math.min(currentDeltaTime / attackDuration, 1)

    local deltaThisFrame

    if startRampDown then
        deltaThisFrame = currentAttackBonus * rateToMax
    else
        deltaThisFrame = (self.PlayerMaxAttackBonus * rateToMax) - currentAttackBonus
    end

    deltaThisFrame = math.floor(deltaThisFrame + 0.5)

    if deltaThisFrame <= 0 then return end

    if startRampDown then deltaThisFrame = -deltaThisFrame end

    ActiveEffects:modify(deltaThisFrame, "fortifyattack")
    currentAttackBonus = currentAttackBonus + deltaThisFrame

    self.debugLog("Current attack bonus:", currentAttackBonus, "magnitude. Delta this frame:", deltaThisFrame)

    if currentAttackBonus == 0 and startRampDown then
        currentDeltaTime = 0
        startRampDown = false
        startRamping = false
        hasHitBuff = false
    end
end

function HitManager:updateMaxAttackBonus()
  if not hasHitBuff then return end

  local oldAttackBonus = currentAttackBonus
  ActiveEffects:modify(-currentAttackBonus, "fortifyattack")

  currentAttackBonus = math.min(self.PlayerMaxAttackBonus, oldAttackBonus)
  ActiveEffects:modify(currentAttackBonus, "fortifyattack")
end

function HitManager:toggleRangedHitBonus(enable)
  self.debugLog("Toggling ranged hit chance bonus:",
    'Enable:', tostring(enable),
    'CurrentAttackBonus:', currentAttackBonus,
    'MaxAttackBonus:', self.PlayerMaxAttackBonus,
    "EnableHitChance:", tostring(self.EnableHitChance),
    "UseRangedBonus:", tostring(self.UseRangedBonus))

    if hasHitBuff then
        ActiveEffects:modify(-currentAttackBonus, "fortifyattack")
        currentAttackBonus = 0
        hasHitBuff = false
        startRamping = false
        startRampDown = false
    end

    if not enable or not self.EnableHitChance or not self.UseRangedBonus then return end

    currentAttackBonus = self.PlayerMaxAttackBonus

    ActiveEffects:modify(currentAttackBonus, "fortifyattack")
    hasHitBuff = true
end

function HitManager:applyRangedAttackBonus(enable)
  self:toggleRangedHitBonus(enable)
  I.s3ChimDamage.Manager:toggleStrengthBonus(enable, false)
  hasRangedBonus = enable
end

function HitManager:handleRangedAttackBonus()
  if not self.UseRangedBonus then return end

  local currentRangedState = self.isUsingRanged()
  if currentRangedState == lastRangedState then return end

  self:applyRangedAttackBonus(currentRangedState)
  lastRangedState = currentRangedState
end

function HitManager:toggleRangedBonus()
    self:applyRangedAttackBonus(self.UseRangedBonus and self.isUsingRanged())
end

local updateHitMgr = async:callback(function(section, key)
  if key == nil then
    HitManager:toggleRangedBonus()
    HitManager:updateMaxAttackBonus()
  elseif key == 'UseRangedBonus' or key == 'EnableHitChance' then
    HitManager:toggleRangedBonus()
  elseif key == 'PlayerMaxAttackBonus' then
    HitManager:updateMaxAttackBonus()
  end

  if key then
    HitManager.debugLog('Updated', key, 'in', section, 'to', tostring(HitManager[key]))
  else
    HitManager.debugLog('Updated HitManager:', HitManager)
  end
end)

storage.globalSection(groupName):subscribe(updateHitMgr)

return {
  interfaceName = "s3ChimChance",
  interface = {
    version = modInfo.version,
    Manager = HitManager,
  },
  engineHandlers = {
    onUpdate = function(dt)
      HitManager:handleRangedAttackBonus()
      HitManager:applyPerFrameAttackBonus(dt)
    end,
    onSave = function()
      return {
        attackDuration = attackDuration,
        currentAttackBonus = currentAttackBonus,
        currentDeltaTime = currentDeltaTime,
        hasHitBuff = hasHitBuff,
        hasRangedBonus = hasRangedBonus,
        lastRangedState = lastRangedState,
        startRampDown = startRampDown,
        startRamping = startRamping,
      }
    end,
    onLoad = function(state)
      attackDuration = state.attackDuration or 0
      currentAttackBonus = state.currentAttackBonus or 0
      currentDeltaTime = state.currentDeltaTime or 0
      hasHitBuff = state.hasHitBuff or false
      hasRangedBonus = state.hasRangedBonus or false
      lastRangedState = state.lastRangedState or false
      startRampDown = state.startRampDown or false
      startRamping = state.startRamping or false
    end,
  }
}
