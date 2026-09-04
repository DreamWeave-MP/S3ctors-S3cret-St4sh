---@meta

---@class openmw.interfaces.SpellCastInfo
---@field id string
---@field caster openmw.Object?
---@field target openmw.Object?
---@field item openmw.types.Item?

---@class openmw.interfaces.SpellCasting
---@field version number
local SpellCasting = {}

---@param options any
function SpellCasting.applyMagicEffects(options) end

---@param handler fun(options: any)
function SpellCasting.addApplyMagicEffectsHandler(handler) end

---@param spellCast openmw.interfaces.SpellCastInfo
---@param options table
function SpellCasting.explodeSpell(spellCast, options) end

---@param spellCast openmw.interfaces.SpellCastInfo
---@param target openmw.Object
---@param range openmw.core.SpellRange One of the values from `openmw.core.magic.RANGE`.
function SpellCasting.inflict(spellCast, target, range) end

return SpellCasting
