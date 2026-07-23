---@omw-context runtime

local core = require 'openmw.core'
local types = require 'openmw.types'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3.lf
local isPlayer = s3lf.actorType == 0

local IsGodMode
---@omw-context-begin player
if isPlayer then
  local debug = require 'openmw.debug'
  IsGodMode = debug.isGodMode
end
---@omw-context-end player

local error, floor, huge, max, min, random, tostring =
  error, math.floor, math.huge, math.max, math.min, math.random, tostring

local EffectRecords, MagicEffects, SpellRecords, SkillRecords, RANGE_Target, RANGE_Self, SPELL_TYPE_Spell, SPELL_TYPE_Power, EFFECT_TYPE_Silence, EFFECT_TYPE_Sound, ENCHANTMENT_TYPE_CastOnce, ENCHANTMENT_TYPE_CastOnStrike, ENCHANTMENT_TYPE_CastOnUse, ENCHANTMENT_TYPE_ConstantEffect, ActiveEffects, GetSelectedEnchantedItem, GetSelectedSpell =
  core.magic.effects.records,
  core.magic.effects,
  core.magic.spells.records,
  core.stats.Skill.records,
  core.magic.RANGE.Target,
  core.magic.RANGE.Self,
  core.magic.SPELL_TYPE.Spell,
  core.magic.SPELL_TYPE.Power,
  core.magic.EFFECT_TYPE.Silence,
  core.magic.EFFECT_TYPE.Sound,
  core.magic.ENCHANTMENT_TYPE.CastOnce,
  core.magic.ENCHANTMENT_TYPE.CastOnStrike,
  core.magic.ENCHANTMENT_TYPE.CastOnUse,
  core.magic.ENCHANTMENT_TYPE.ConstantEffect,
  types.Actor.activeEffects,
  types.Actor.getSelectedEnchantedItem,
  types.Actor.getSelectedSpell

---@enum EffectCostMethod
local EffectCostMethod = {
  GameSpell = 0,
  PlayerSpell = 1,
  Enchantment = 2,
  Potion = 3,
}

---@class MagicHelper
local Magic = {
  CostMethod = EffectCostMethod,
}

local fEffectCostMult, fFatigueBase, fFatigueMult, iAlchemyMod, iMagicItemChargeConst, iMagicItemChargeOnce, iMagicItemChargeStrike, iMagicItemChargeUse =
  core.getGMST 'fEffectCostMult',
  core.getGMST 'fFatigueBase',
  core.getGMST 'fFatigueMult',
  core.getGMST 'iAlchemyMod',
  core.getGMST 'iMagicItemChargeConst',
  core.getGMST 'iMagicItemChargeOnce',
  core.getGMST 'iMagicItemChargeStrike',
  core.getGMST 'iMagicItemChargeUse'

--- Returns whatever a particular actor's currently selected castable is
---@return openmw.Object|openmw.core.Spell|nil
function Magic.getCastable(actor) return GetSelectedEnchantedItem(actor) or GetSelectedSpell(actor) end

---@param spellEffect openmw.core.MagicEffectWithParams
---@param baseEffect openmw.core.MagicEffect?
---@param costMethod EffectCostMethod
---@return number effectCost
function Magic.getEffectCost(spellEffect, baseEffect, costMethod)
  if not baseEffect then baseEffect = EffectRecords[spellEffect.id] end

  local hasMagnitude, hasDuration, appliedOnce =
    baseEffect.hasMagnitude, baseEffect.hasDuration, baseEffect.isAppliedOnce

  local minMagnitude, maxMagnitude, duration, durationOffset, minArea = 1, 1, 1, 0, 0
  if hasMagnitude then
    if costMethod == EffectCostMethod.GameSpell or costMethod == EffectCostMethod.PlayerSpell then
      minMagnitude, maxMagnitude =
        max(1, spellEffect.magnitudeMin), max(1, spellEffect.magnitudeMax)
    else
      minMagnitude, maxMagnitude = spellEffect.magnitudeMin, spellEffect.magnitudeMax
    end
  end

  if hasDuration then duration = spellEffect.duration end

  if not appliedOnce then duration = max(1, duration) end
  local costMult = fEffectCostMult

  if costMethod == EffectCostMethod.PlayerSpell then
    durationOffset = 1
    minArea = 1
  elseif costMethod == EffectCostMethod.Potion then
    minArea = 1
    costMult = iAlchemyMod
  end

  local x = 0.5 * (minMagnitude + maxMagnitude)
  x = x * 0.1 * baseEffect.baseCost
  x = x * (durationOffset + duration)
  x = x + 0.05 * max(minArea, spellEffect.area) * baseEffect.baseCost

  return x * costMult
end

---@param effectList openmw.core.MagicEffectWithParams[]
---@param costMethod EffectCostMethod?
---@return number effectListCost
function Magic:getEffectListCost(effectList, costMethod)
  if not costMethod then costMethod = EffectCostMethod.GameSpell end

  local cost = 0

  for i = 1, #effectList do
    local effect = effectList[i]
    local effectCost = max(0, self.getEffectCost(effect, nil, costMethod))

    if effect.range == RANGE_Target then effectCost = effectCost * 1.5 end

    cost = cost + effectCost
  end

  return cost
end

---@param spell openmw.core.Spell
---@return number totalCost
function Magic:getSpellCost(spell)
  if not spell.autocalcFlag then return spell.cost end

  return util.round(self:getEffectListCost(spell.effects))
end

---@param spell openmw.core.Spell
---@return number baseCost, string magicSchool spell cost before accounting for factors such as god mode, always succeed, and powers. Also magic school for a given spell
function Magic:getBaseCastChance(spell)
  local y, lowestSkill, magicSchool = huge, 0, nil

  for i = 1, #spell.effects do
    local effect = spell.effects[i]
    local x = effect.duration

    ---@type MagicEffect
    local baseEffect = EffectRecords[effect.id]

    if not baseEffect.isAppliedOnce then x = max(1.0, x) end

    x = x * 0.1 * baseEffect.baseCost
    x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
    x = x + effect.area * 0.05 * baseEffect.baseCost

    if effect.range == RANGE_Target then x = x * 1.5 end

    x = x * fEffectCostMult

    local s = 2.0 * s3lf[baseEffect.school].modified
    local difference = s - x

    if difference < y then
      y = difference
      lowestSkill = s
      magicSchool = baseEffect.school
    end
  end

  if not magicSchool then error('failed to determine a magic school for: ' .. spell.id, 2) end

  local castChance = lowestSkill
    - self:getSpellCost(spell)
    + 0.2 * s3lf.willpower.modified
    + 0.1 * s3lf.luck.modified
  return castChance, magicSchool
end

---@param spell openmw.core.Spell
---@return string?
function Magic:getSpellSchool(spell)
  local _, school = self:getBaseCastChance(spell)
  local schoolSkill = SkillRecords[school]
  return schoolSkill and schoolSkill.id
end

---@param spellId string
---@return string? spellSchool
function Magic:getSpellIdSchool(spellId)
  ---@type openmw.core.Spell?
  local spell = SpellRecords[spellId]
  if not spell then return end

  return self:getSpellSchool(spell)
end

---@param spell openmw.core.Spell
---@return boolean doesIncrease
function Magic.spellIncreasesSkill(spell)
  return spell.type == SPELL_TYPE_Spell and not spell.alwaysSucceedFlag
end

---@param spellId string
function Magic.spellIdIncreasesSkill(spellId)
  local spell = SpellRecords[spellId]
  if not spell then return end

  return Magic.spellIncreasesSkill(spell)
end

function Magic.getFatigueTerm()
  local base, current, normalized = s3lf.fatigue.base, s3lf.fatigue.current, nil

  if floor(base) == 0 then
    normalized = 1
  else
    normalized = max(0., current / max)
  end

  return fFatigueBase - fFatigueMult * (1 - normalized)
end

---@param actor openmw.Object
---@param spell openmw.core.Spell
---@param checkMagicka boolean? whether to actually take caster magicka into account when determining success chance
---@param cap boolean? cap chance between 0-100
function Magic:getSpellCastChance(spell, actor, checkMagicka, cap)
  ---@diagnostic disable-next-line: undefined-field
  if not spell or spell.__type.name ~= 'ESM::Spell' then
    ---@diagnostic disable-next-line: undefined-field
    error('Invalid spell provided to Magic:getSpellCastChance: ' .. spell.__type.name)
  end

  if checkMagicka == nil then checkMagicka = true end

  local baseChance, spellCost = self:getBaseCastChance(spell), self:getSpellCost(spell)

  if spell.type == SPELL_TYPE_Power then
    return actor.type.spells(actor):canUsePower(spell) and 100 or 0
  end

  if isPlayer and IsGodMode() then return 100 end

  local activeEffects = ActiveEffects(actor)
  if activeEffects:getEffect(EFFECT_TYPE_Silence).magnitude > 0 then return 0 end

  if spell.type ~= SPELL_TYPE_Spell then return 100 end

  if (checkMagicka and spellCost > 0) and s3lf.magicka.current < spellCost then return 0 end

  if spell.alwaysSucceedFlag then return 100 end

  local castBonus = -activeEffects:getEffect(EFFECT_TYPE_Sound).magnitude
  local castChance = baseChance + castBonus
  castChance = castChance * Magic.getFatigueTerm()

  if cap then return util.clamp(castChance, 0.0, 100.0) end

  return max(castChance, 0.0)
end

--- Given an enchantment record, return its total charge *capacity*.
--- This is *not* how much charge is used on a cast or usage of an enchantment.
---@param enchantment openmw.core.Enchantment
---@return number totalCharge
function Magic.getEnchantmentCharge(enchantment)
  if not enchantment.autocalcFlag then return enchantment.cost end

  local baseCharge =
    util.round(Magic:getEffectListCost(enchantment.effects, EffectCostMethod.Enchantment))
  local enchantType = enchantment.type

  if enchantType == ENCHANTMENT_TYPE_CastOnce then
    return baseCharge * iMagicItemChargeOnce
  elseif enchantType == ENCHANTMENT_TYPE_CastOnStrike then
    return baseCharge * iMagicItemChargeStrike
  elseif enchantType == ENCHANTMENT_TYPE_CastOnUse then
    return baseCharge * iMagicItemChargeUse
  elseif enchantType == ENCHANTMENT_TYPE_ConstantEffect then
    return baseCharge * iMagicItemChargeConst
  end

  error('Invalid enchantment type detected! ' .. enchantType)
end

---@param actor GameObject
---@return string? iconPath
function Magic.getCastableIcon(actor)
  local enchantedItem = actor.type.getSelectedEnchantedItem(actor)
  if enchantedItem then return enchantedItem.type.records[enchantedItem.recordId].icon end

  local selectedSpell = actor.type.getSelectedSpell(actor)
  if not selectedSpell then return end

  return selectedSpell.effects[1].effect.icon
end

---@param castCost number
---@param actor openmw.LObject | openmw.GObject
function Magic.getEnchantmentBaseCost(castCost, actor)
  if not types.NPC.objectIsInstance(actor) then
    error(('Non-NPC types may not cast enchantments: %s !'):format(actor.type))
  end

  ---@type openmw.types.NPC
  local actorType = actor.type

  local enchantSkill = actorType.stats.skills.enchant(actor).modified

  local result = castCost - (castCost / 100) * (enchantSkill - 10)

  return result < 1 and 1 or result
end

---@param enchantment openmw.core.Enchantment
---@param actor openmw.LObject | openmw.GObject
---@return number enchantEffectiveCost
function Magic.getEffectiveEnchantCost(enchantment, actor)
  local castCost = enchantment.cost

  if enchantment.autocalcFlag then
    castCost = Magic:getEffectListCost(enchantment.effects, EffectCostMethod.Enchantment)
  end

  return Magic.getEnchantmentBaseCost(castCost, actor)
end

function Magic.getPotionValue(potionRecord)
  if not potionRecord.autocalcFlag then return potionRecord.value end

  return util.round(Magic:getEffectListCost(potionRecord.effects, EffectCostMethod.Potion))
end

function Magic.rollIngredientEffect(caster, ingredientRecord, index)
  if index > 4 then error('Ingredient effect index out of range: ' .. tostring(index), 2) end

  local selectedEffect = ingredientRecord.effects[index]
  local effect = {
    effectId = selectedEffect.id,
    affectedSkill = selectedEffect.affectedSkill,
    affectedAttribute = selectedEffect.affectedAttribute,
    range = RANGE_Self,
    area = 0,
  }

  -- There's supposed to be a case here where if mEffectId is < 0, we bail early
  -- But I'm not really sure what the idea is there.

  local casterStats = caster.type.stats
  local casterAttributes = casterStats.attributes
  local x = casterStats.skills.alchemy(caster).base
    + (0.2 * casterAttributes.strength(caster).modified)
    + (0.1 * casterAttributes.luck(caster).modified)

  local roll = random(0, 99)

  if roll > x then return end

  local magnitude, y = 0, roll / min(x, 100.)
  y = y * 0.25 * x

  ---@type MagicEffect
  local baseEffect = MagicEffects[selectedEffect.id]

  if baseEffect.hasDuration then
    effect.duration = y
  else
    effect.duration = 1
  end

  if baseEffect.hasMagnitude then
    if baseEffect.hasDuration then
      magnitude = floor((0.05 * y) / (0.1 * baseEffect.baseCost))
    else
      magnitude = floor(y / (0.1 * baseEffect.baseCost))
    end
    magnitude = max(1., magnitude)
  end

  effect.magnitudeMin, effect.magnitudeMax = magnitude, magnitude
  return effect
end

return Magic
