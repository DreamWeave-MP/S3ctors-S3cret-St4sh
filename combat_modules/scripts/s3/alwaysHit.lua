-- [[
-- Repro better balanced combat formula for increasing str/burden based on weapon skill
--]]

local animation = require('openmw.animation')
local self = require('openmw.self')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local MaxAttackBonus = 250

local currentAttackBonus = 0
local currentDeltaTime = 0.
local attackDuration = 0.

local hasHitBuff = false
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

-- Still not exactly certain about which groups should be used
-- But current impl seems solid so keeping this for now
local maxAttackKeys = {
  -- ["thrust max attack"] = true,
  -- ["chop max attack"] = true,
  -- ["slash max attack"] = true,
  ["chop small follow stop"] = true,
  ["thrust small follow stop"] = true,
  ["slash small follow stop"] = true,
  -- ["chop large follow stop"] = true,
  -- ["thrust large follow stop"] = true,
  -- ["slash large follow stop"] = true,
  -- ["chop medium follow stop"] = true,
  -- ["thrust medium follow stop"] = true,
  -- ["slash medium follow stop"] = true,
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

  elseif minAttackKeys[key] and not hasHitBuff then
    -- if we save the original behavior as an option this needs to be behind it also
    hasHitBuff = true
    startRamping = true
    currentAttackBonus = 0
    currentDeltaTime = 0.

  elseif maxAttackKeys[key] and hasHitBuff then
    -- ui.showMessage("Ramping down from: " .. currentAttackBonus .. " magnitude")
    -- self.type.activeEffects(self):modify(-currentAttackBonus, "fortifyattack")
    -- hasHitBuff = false
    -- startRamping = false
    -- currentAttackBonus = 0

    currentDeltaTime = 0.
    startRampDown = true

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

  print("Current attack bonus: " .. currentAttackBonus .. " magnitude" .. " delta this frame: " .. deltaThisFrame)

  if currentAttackBonus == MaxAttackBonus and not startRampDown then
    ui.showMessage("Perfect Strike!")
  end

  if currentAttackBonus == 0 and startRampDown then
    currentDeltaTime = 0
    startRampDown = false
    startRamping = false
    hasHitBuff = false
  end
end

local function onSave()
  return {
    hasHitBuff = hasHitBuff,
    startRamping = startRamping,
    rampDown = startRampDown,
    currentAttackBonus = currentAttackBonus,
    attackDuration = attackDuration,
    currentDeltaTime = currentDeltaTime,
  }
end

local function onLoad(state)
  hasHitBuff = state.hasHitBuff or false
  startRamping = state.startRamping or false
  startRampDown = state.startRampDown or false
  currentAttackBonus = state.currentAttackBonus or 0
  currentDeltaTime = state.currentDeltaTime or 0
  attackDuration = state.attackDuration or 0
end

return {
  engineHandlers = {
    onFrame = applyPerFrameAttackBonus,
    onSave = onSave,
    onLoad = onLoad,
  }
}
