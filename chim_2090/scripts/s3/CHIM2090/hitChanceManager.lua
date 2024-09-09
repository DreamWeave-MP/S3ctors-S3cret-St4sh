local animation = require('openmw.animation')
local core = require('openmw.core')
local gameSelf = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local modInfo = require('scripts.s3.CHIM2090.modInfo')
local ProtectedTable = require('scripts.s3.CHIM2090.protectedTable')

local groupName = 'SettingsGlobal' .. modInfo.name .. 'HitChance'

local globalSettings = storage.globalSection('SettingsGlobal' .. modInfo.name)
local hitChanceSettings = storage.globalSection(groupName)

local ActiveEffects = gameSelf.type.activeEffects(gameSelf)

local Fatigue = gameSelf.type.stats.dynamic.fatigue(gameSelf)

local Agility = gameSelf.type.stats.attributes.agility(gameSelf)
local Luck = gameSelf.type.stats.attributes.luck(gameSelf)
local HandToHand = gameSelf.type.stats.skills.handtohand(gameSelf)

local weaponTypesToSkills = {
  [types.Weapon.TYPE.ShortBladeOneHand] = gameSelf.type.stats.skills.shortblade(gameSelf),
  [types.Weapon.TYPE.LongBladeOneHand] = gameSelf.type.stats.skills.longblade(gameSelf),
  [types.Weapon.TYPE.LongBladeTwoHand] = gameSelf.type.stats.skills.longblade(gameSelf),
  [types.Weapon.TYPE.BluntOneHand] = gameSelf.type.stats.skills.bluntweapon(gameSelf),
  [types.Weapon.TYPE.BluntTwoClose] = gameSelf.type.stats.skills.bluntweapon(gameSelf),
  [types.Weapon.TYPE.BluntTwoWide] = gameSelf.type.stats.skills.bluntweapon(gameSelf),
  [types.Weapon.TYPE.SpearTwoWide] = gameSelf.type.stats.skills.spear(gameSelf),
  [types.Weapon.TYPE.AxeOneHand] = gameSelf.type.stats.skills.axe(gameSelf),
  [types.Weapon.TYPE.AxeTwoHand] = gameSelf.type.stats.skills.axe(gameSelf),
  [types.Weapon.TYPE.MarksmanBow] = gameSelf.type.stats.skills.marksman(gameSelf),
  [types.Weapon.TYPE.MarksmanCrossbow] = gameSelf.type.stats.skills.marksman(gameSelf),
  [types.Weapon.TYPE.MarksmanThrown] = gameSelf.type.stats.skills.marksman(gameSelf),
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

local HitManager = {
  EnableHitChance = hitChanceSettings:get('EnableHitChance'),
  AgilityHitChancePct = hitChanceSettings:get('AgilityHitChancePct'),
  LuckHitChancePct = hitChanceSettings:get('LuckHitChancePct'),
  PlayerMaxAttackBonus = hitChanceSettings:get('PlayerMaxAttackBonus'),
  UseRangedBonus = globalSettings:get('UseRangedBonus'),
  DebugLog = globalSettings:get('DebugEnable')
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
  local weapon = gameSelf.type.getEquipment(gameSelf, gameSelf.type.EQUIPMENT_SLOT.CarriedRight)
  if not weapon then return false end
  return rangedWeaponTypes[types.Weapon.records[weapon.recordId].type] or false
end

function HitManager.toggleDebug(newDebugEnable)
  rawset(HitManager, 'DebugLog', newDebugEnable)
end

function HitManager:debugLog(...)
  if not self.DebugLog then return end
  print(modInfo.logPrefix, 'HitManager:', table.concat({...}, " "))
end

function HitManager:getNativeHitChance()
    local normalizedFatigue = Fatigue.current / Fatigue.base
    local fatigueTerm = core.getGMST('fFatigueBase') - core.getGMST('fFatigueMult') * (1 - normalizedFatigue)

    local weapon = gameSelf.type.getEquipment(gameSelf, gameSelf.type.EQUIPMENT_SLOT.CarriedRight)
    local weaponType = types.Weapon.records[weapon.recordId].type
    local skill
    if not weapon then
        skill = HandToHand.modified
    else
        skill = weaponTypesToSkills[weaponType].modified
    end

    local agilityInfluence = self.AgilityHitChancePct * Agility.modified
    local luckInfluence = self.LuckHitChancePct * Luck.modified

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
    local minAttackTime = animation.getTextKeyTime(gameSelf, attackStartKey .. "min attack")

    local maxAttackTime = animation.getTextKeyTime(gameSelf, attackStartKey .. "max attack")

    attackDuration = maxAttackTime - minAttackTime

    -- toggleStrengthBonus(true, true)

  elseif keys.minAttack[key] and not hasHitBuff and self.EnableHitChance then
    hasHitBuff = true
    startRamping = true
    currentAttackBonus = 0
    currentDeltaTime = 0.

  elseif keys.maxAttack[key] then

    -- toggleStrengthBonus(false)

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

    self:debugLog("Current attack bonus:", currentAttackBonus, "magnitude. Delta this frame:", deltaThisFrame)

    if currentAttackBonus == 0 and startRampDown then
        currentDeltaTime = 0
        startRampDown = false
        startRamping = false
        hasHitBuff = false
    end
end

function HitManager:updateMaxAttackBonus(newMaxAttackBonus)
  local oldAttackBonus = currentAttackBonus
  self.PlayerMaxAttackBonus = newMaxAttackBonus
  if hasHitBuff then
    ActiveEffects:modify(-currentAttackBonus, "fortifyattack")
    currentAttackBonus = math.min(self.PlayerMaxAttackBonus, oldAttackBonus)
    ActiveEffects:modify(currentAttackBonus, "fortifyattack")
  end
end

function HitManager:toggleRangedHitBonus(enable)
  self:debugLog("Toggling ranged hit chance bonus:",
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
  if hasHitBuff ~= enable then
    self:toggleRangedHitBonus(enable)
  end

  -- if hasStrengthBonus ~= enable then
  --   toggleStrengthBonus(enable, false)
  -- end

  hasRangedBonus = enable
end

function HitManager:toggleHitChance(newEnableHitChance)
  if not newEnableHitChance then
    self:debugLog('Disabling hit chance bonus from setting:',
                  'hasHitBuff:', tostring(hasHitBuff),
             'hasRangedBonus:', tostring(hasRangedBonus))
    self:toggleRangedHitBonus(false)
  end

  I.s3ChimChance.Manager.EnableHitChance = newEnableHitChance

  if self.isUsingRanged() then
    self:debugLog('Enabling hit chance bonus from setting:',
                  'hasHitBuff:', tostring(hasHitBuff),
                  'hasRangedBonus:', tostring(self.hasRangedBonus),
                  'UseRangedBonus:', tostring(self.UseRangedBonus))
    self:toggleRangedHitBonus(true)
  end
end

function HitManager:handleRangedAttackBonus()
  if not self.UseRangedBonus then return end

  if self.isUsingRanged() and not hasRangedBonus then
    self:applyRangedAttackBonus(true)
  elseif not self.isUsingRanged() and hasRangedBonus then
    self:applyRangedAttackBonus(false)
  end
end

function HitManager:toggleRangedBonus(newUseRangedBonus)
  rawset(HitManager, 'UseRangedBonus', newUseRangedBonus)
  self:applyRangedAttackBonus(self.UseRangedBonus and self.isUsingRanged())
end

return {
  interfaceName = "s3ChimChance",
  interface = {
    version = modInfo.version,
    Manager = ProtectedTable(HitManager, groupName),
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
