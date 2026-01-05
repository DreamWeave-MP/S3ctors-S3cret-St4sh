local core = require 'openmw.core'
local types = require 'openmw.types'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local debug
local isPlayer = types.Player.objectIsInstance(s3lf.gameObject)
if isPlayer then
    debug = require 'openmw.debug'
end

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

local fEffectCostMult,
fFatigueBase,
fFatigueMult,
iAlchemyMod,
iMagicItemChargeConst,
iMagicItemChargeOnce,
iMagicItemChargeStrike,
iMagicItemChargeUse =
    core.getGMST('fEffectCostMult'),
    core.getGMST('fFatigueBase'),
    core.getGMST('fFatigueMult'),
    core.getGMST('iAlchemyMod'),
    core.getGMST('iMagicItemChargeConst'),
    core.getGMST('iMagicItemChargeOnce'),
    core.getGMST('iMagicItemChargeStrike'),
    core.getGMST('iMagicItemChargeUse')

--- Returns whatever a particular actor's currently selected castable is
---@return GameObject|Spell|nil
function Magic.getCastable(actor)
    return actor.type.getSelectedEnchantedItem(actor) or actor.type.getSelectedSpell(actor)
end

---@param spellEffect MagicEffectWithParams
---@param baseEffect MagicEffect?
---@param costMethod EffectCostMethod
---@return number effectCost
function Magic.getEffectCost(spellEffect, baseEffect, costMethod)
    if not baseEffect then
        baseEffect = core.magic.effects.records[spellEffect.id]
    end

    local hasMagnitude,
    hasDuration,
    appliedOnce =
        baseEffect.hasMagnitude,
        baseEffect.hasDuration,
        baseEffect.isAppliedOnce

    local minMagnitude, maxMagnitude, duration, durationOffset, minArea = 1, 1, 1, 0, 0
    if hasMagnitude then
        if costMethod == EffectCostMethod.GameSpell or costMethod == EffectCostMethod.PlayerSpell then
            minMagnitude, maxMagnitude = math.max(1, spellEffect.magnitudeMin), math.max(1, spellEffect.magnitudeMax)
        else
            minMagnitude, maxMagnitude = spellEffect.magnitudeMin, spellEffect.magnitudeMax
        end
    end

    if hasDuration then duration = spellEffect.duration end

    if not appliedOnce then duration = math.max(1, duration) end
    local costMult = fEffectCostMult

    if costMethod == EffectCostMethod.PlayerSpell then
        durationOffset = 1
        minArea = 1
    elseif costMethod == EffectCostMethod.Potion then
        minArea = 1
        costMult = iAlchemyMod
    end

    local x = .5 * (minMagnitude + maxMagnitude)
    x = x * .1 * baseEffect.baseCost
    x = x * (durationOffset + duration)
    x = x + .05 * math.max(minArea, spellEffect.area) * baseEffect.baseCost

    return x * costMult
end

---@param effectList MagicEffectWithParams[]
---@param costMethod EffectCostMethod?
---@return number effectListCost
function Magic:getEffectListCost(effectList, costMethod)
    if not costMethod then costMethod = EffectCostMethod.GameSpell end

    local cost = 0

    for _, effect in ipairs(effectList) do
        local effectCost = math.max(0, self.getEffectCost(effect, nil, costMethod))

        if effect.range == core.magic.RANGE.Target then
            effectCost = effectCost * 1.5
        end

        cost = cost + effectCost
    end

    return cost
end

---@param spell Spell
---@return number totalCost
function Magic:getSpellCost(spell)
    if not spell.autocalcFlag then
        return spell.cost
    end

    return util.round(self:getEffectListCost(spell.effects))
end

---@param spell Spell
---@return number baseCost, string magicSchool spell cost before accounting for factors such as god mode, always succeed, and powers. Also magic school for a given spell
function Magic:getBaseCastChance(spell)
    local y, lowestSkill, magicSchool = math.huge, 0, nil

    for _, effect in ipairs(spell.effects) do
        local x = effect.duration

        ---@type MagicEffect
        local baseEffect = core.magic.effects.records[effect.id]

        if not baseEffect.isAppliedOnce then
            x = math.max(1.0, x)
        end

        x = x * .1 * baseEffect.baseCost
        x = x * .5 * (effect.magnitudeMin + effect.magnitudeMax)
        x = x + effect.area * .05 * baseEffect.baseCost

        if effect.range == core.magic.RANGE.Target then
            x = x * 1.5
        end

        x = x * fEffectCostMult

        local s = 2.0 * s3lf[baseEffect.school].modified
        local difference = s - x

        if difference < y then
            y = difference
            lowestSkill = s
            magicSchool = baseEffect.school
        end
    end

    assert(magicSchool, 'failed to determine a magic school for: ' .. spell.id)

    local castChance = lowestSkill - self:getSpellCost(spell) + .2 * s3lf.willpower.modified + .1 * s3lf.luck.modified
    return castChance, magicSchool
end

---@param spell Spell
function Magic:getSpellSchool(spell)
    local _, school = self:getBaseCastChance(spell)
    return core.stats.Skill.records[school]
end

---@param spellId string
---@return string? spellSchool
function Magic:getSpellIdSchool(spellId)
    ---@type Spell?
    local spell = core.spells.records[spellId]
    if not spell then return end

    return self:getSpellSchool(spell)
end

---@param spell Spell
---@return boolean doesIncrease
function Magic.spellIncreasesSkill(spell)
    return spell.type == core.magic.SPELL_TYPE.Spell and not spell.alwaysSucceedFlag
end

---@param spellId string
function Magic.spellIdIncreasesSkill(spellId)
    local spell = core.spells.records[spellId]
    if not spell then return end

    return Magic.spellIncreasesSkill(spell)
end

function Magic.getFatigueTerm()
    local max, current, normalized = s3lf.fatigue.base, s3lf.fatigue.current, nil

    if math.floor(max) == 0 then normalized = 1 else normalized = math.max(0., current / max) end

    return fFatigueBase - fFatigueMult * (1 - normalized)
end

---@param actor GameObject
---@param spell Spell
---@param checkMagicka boolean? whether to actually take caster magicka into account when determining success chance
---@param cap boolean? cap chance between 0-100
function Magic:getSpellCastChance(spell, actor, checkMagicka, cap)
    ---@diagnostic disable-next-line: undefined-field
    assert(spell and spell.__type.name == 'ESM::Spell', 'Invalid spell provided to Magic:getSpellCastChance: ' .. spell.__type.name)

    if checkMagicka == nil then checkMagicka = true end

    local baseChance, spellCost = self:getBaseCastChance(spell), self:getSpellCost(spell)

    if spell.type == core.magic.SPELL_TYPE.Power then
        return actor.type.spells(actor):canUsePower(spell) and 100 or 0
    end

    if isPlayer and debug.isGodMode() then
        return 100
    end

    local activeEffects = actor.type.activeEffects(actor)
    if activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence).magnitude > 0 then
        return 0
    end

    if spell.type ~= core.magic.SPELL_TYPE.Spell then
        return 100
    end

    if (checkMagicka and spellCost > 0) and s3lf.magicka.current < spellCost then
        return 0
    end

    if spell.alwaysSucceedFlag then
        return 100
    end

    local castBonus = -activeEffects:getEffect(core.magic.EFFECT_TYPE.Sound).magnitude
    local castChance = baseChance + castBonus
    castChance = castChance * Magic.getFatigueTerm()

    if cap then
        return util.clamp(castChance, 0.0, 100.0)
    end

    return math.max(castChance, 0.0)
end

--- Given an enchantment record, return its total charge *capacity*.
--- This is *not* how much charge is used on a cast or usage of an enchantment.
---@param enchantment Enchantment
---@return number totalCharge
function Magic.getEnchantmentCharge(enchantment)
    if not enchantment.autocalcFlag then
        return enchantment.cost
    end

    local baseCharge = util.round(Magic:getEffectListCost(enchantment.effects, EffectCostMethod.Enchantment))
    local enchantType = enchantment.type

    if enchantType == core.magic.ENCHANTMENT_TYPE.CastOnce then
        return baseCharge * iMagicItemChargeOnce
    elseif enchantType == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
        return baseCharge * iMagicItemChargeStrike
    elseif enchantType == core.magic.ENCHANTMENT_TYPE.CastOnUse then
        return baseCharge * iMagicItemChargeUse
    elseif enchantType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
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
---@param actor GameObject
function Magic.getEnchantmentBaseCost(castCost, actor)
    local enchantSkill = s3lf.From(actor).enchant.modified

    local result = castCost - (castCost / 100) * (enchantSkill - 10)

    return result < 1 and 1 or result
end

---@param enchantment Enchantment
---@param actor GameObject
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
    assert(index < 4, 'Ingredient effect index out of range: ' .. tostring(index))

    local selectedEffect = ingredientRecord.effects[index]
    local effect = {
        effectId = selectedEffect.id,
        affectedSkill = selectedEffect.affectedSkill,
        affectedAttribute = selectedEffect.affectedAttribute,
        range = core.magic.RANGE.Self,
        area = 0,
    }

    -- There's supposed to be a case here where if mEffectId is < 0, we bail early
    -- But I'm not really sure what the idea is there.

    local casterStats = caster.type.stats
    local casterAttributes = casterStats.attributes
    local x = casterStats.skills.alchemy(caster).base
        + (.2 * casterAttributes.strength(caster).modified)
        + (.1 * casterAttributes.luck(caster).modified)

    local roll = math.random(0, 99)

    if roll > x then return end

    local magnitude, y = 0, roll / math.min(x, 100.)
    y = y * .25 * x

    ---@type MagicEffect
    local baseEffect = core.magic.effects[selectedEffect.id]

    if baseEffect.hasDuration then
        effect.duration = y
    else
        effect.duration = 1
    end

    if baseEffect.hasMagnitude then
        if baseEffect.hasDuration then
            magnitude = math.floor((.05 * y) / (.1 * baseEffect.baseCost))
        else
            magnitude = math.floor(y / (.1 * baseEffect.baseCost))
        end
        magnitude = math.max(1., magnitude)
    end

    effect.magnitudeMin, effect.magnitudeMax = magnitude, magnitude
    return effect
end

return Magic
