---@meta

---Allows to extend or override built-in skill progression mechanics.
----- Make jail time hurt sneak skill instead of benefitting it
---I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
---end)
----- Forbid increasing destruction skill past 50
---I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
---end)
----- Scale sneak skill progression based on active invisibility effects
---I.SkillProgression.addSkillUsedHandler(function(skillid, params)
---end)
---@class openmw.interfaces.SkillProgression
---@field version number
---@field SKILL_USE_TYPES openmw.interfaces.SkillProgression.SkillUseType Available skill usage types
---@field SKILL_INCREASE_SOURCES openmw.interfaces.SkillProgression.SkillLevelUpSource
local SkillProgression = {}

---Table of all existing sources for skill increases. Any sources not listed below will be treated as equal to Trainer.
---If there are no handlers, then there won't be any effect, so skip calculations
---Make a copy so we don't change the caller's table
---Compute use value if it was not supplied directly
---If there are no handlers, then there won't be any effect, so skip calculations
---@alias openmw.interfaces.SkillProgression.SkillLevelUpSourceBook "book"
---@alias openmw.interfaces.SkillProgression.SkillLevelUpSourceJail "jail"
---@alias openmw.interfaces.SkillProgression.SkillLevelUpSourceTrainer "trainer"
---@alias openmw.interfaces.SkillProgression.SkillLevelUpSourceUsage "usage"
---@alias openmw.interfaces.SkillProgression.SkillLevelUpSource openmw.interfaces.SkillProgression.SkillLevelUpSourceBook|openmw.interfaces.SkillProgression.SkillLevelUpSourceJail|openmw.interfaces.SkillProgression.SkillLevelUpSourceTrainer|openmw.interfaces.SkillProgression.SkillLevelUpSourceUsage

---@class openmw.interfaces.SkillProgression.SkillLevelUpSourceValues
---@field Book openmw.interfaces.SkillProgression.SkillLevelUpSourceBook
---@field Jail openmw.interfaces.SkillProgression.SkillLevelUpSourceJail
---@field Trainer openmw.interfaces.SkillProgression.SkillLevelUpSourceTrainer
---@field Usage openmw.interfaces.SkillProgression.SkillLevelUpSourceUsage
local SkillLevelUpSource = {}

---Table of skill use types defined by Morrowind.
---Each entry corresponds to an index into the available skill gain values
---of a openmw.core.SkillRecord
---@alias openmw.interfaces.SkillProgression.SkillUseTypeZero 0
---@alias openmw.interfaces.SkillProgression.SkillUseTypeOne 1
---@alias openmw.interfaces.SkillProgression.SkillUseTypeTwo 2
---@alias openmw.interfaces.SkillProgression.SkillUseTypeThree 3
---@alias openmw.interfaces.SkillProgression.SkillUseType openmw.interfaces.SkillProgression.SkillUseTypeZero|openmw.interfaces.SkillProgression.SkillUseTypeOne|openmw.interfaces.SkillProgression.SkillUseTypeTwo|openmw.interfaces.SkillProgression.SkillUseTypeThree

---@class openmw.interfaces.SkillProgression.SkillUseTypeValues
---@field Armor_HitByOpponent openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Block_Success openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Spellcast_Success openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Weapon_SuccessfulHit openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Alchemy_CreatePotion openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Alchemy_UseIngredient openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Enchant_Recharge openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Enchant_UseMagicItem openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Enchant_CreateMagicItem openmw.interfaces.SkillProgression.SkillUseTypeTwo
---@field Enchant_CastOnStrike openmw.interfaces.SkillProgression.SkillUseTypeThree
---@field Acrobatics_Jump openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Acrobatics_Fall openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Mercantile_Success openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Mercantile_Bribe openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Security_DisarmTrap openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Security_PickLock openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Sneak_AvoidNotice openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Sneak_PickPocket openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Speechcraft_Success openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Speechcraft_Fail openmw.interfaces.SkillProgression.SkillUseTypeOne
---@field Armorer_Repair openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Athletics_RunOneSecond openmw.interfaces.SkillProgression.SkillUseTypeZero
---@field Athletics_SwimOneSecond openmw.interfaces.SkillProgression.SkillUseTypeOne
local SkillUseType = {}

---Interface version
---@type number
SkillProgression.version = nil

---These are shared by multiple skills
---Skill-specific use types
---@type openmw.interfaces.SkillProgression.SkillUseTypeValues
SkillProgression.SKILL_USE_TYPES = nil

---@type openmw.interfaces.SkillProgression.SkillLevelUpSourceValues
SkillProgression.SKILL_INCREASE_SOURCES = nil

---Add new skill level up handler for this actor.
---For load order consistency, handlers should be added in the body if your script.
---If `handler(skillid, source, options)` returns false, other handlers (including the default skill level up handler)
---will be skipped. Where skillid and source are the parameters passed to openmw.interfaces.SkillProgression.SkillProgression.skillLevelUp, and options is
---a modifiable table of skill level up values, and can be modified to change the behavior of later handlers.
---These values are calculated based on vanilla mechanics. Setting any value to nil will cause that mechanic to be skipped. By default it contains these values:
---  * `skillIncreaseValue` - The numeric amount of skill levels gained. By default this is 1, except when the source is jail in which case it will instead be -1 for all skills except sneak and security.
---  * `levelUpProgress` - The numeric amount of level up progress gained.
---  * `levelUpAttribute` - The string identifying the attribute that should receive points from this skill level up.
---  * `levelUpAttributeIncreaseValue` - The numeric amount of attribute increase points received. This contributes to the amount of each attribute the character receives during a vanilla level up.
---  * `levelUpSpecialization` - The string identifying the specialization that should receive points from this skill level up.
---  * `levelUpSpecializationIncreaseValue` - The numeric amount of specialization increase points received. This contributes to the icon displayed at the level up screen during a vanilla level up.
---@param handler fun(...): any The handler.
function SkillProgression.addSkillLevelUpHandler(handler) end

---Add new skillUsed handler for this actor.
---For load order consistency, handlers should be added in the body of your script.
---If `handler(skillid, options)` returns false, other handlers (including the default skill progress handler)
---will be skipped. Where options is a modifiable table of skill progression values, and can be modified to change the behavior of later handlers.
---Contains a `skillGain` value as well as a shallow copy of the options passed to openmw.interfaces.SkillProgression.SkillProgression.skillUsed.
---@param handler fun(...): any The handler.
function SkillProgression.addSkillUsedHandler(handler) end

---Trigger a skill use, activating relevant handlers
---by handlers to make decisions. See the addSkillUsedHandler example at the top of this page.
---And may contain the following optional parameter:
---Note that a copy of this table is passed to skill used handlers, so any parameters passed to this method will also be passed to the handlers. This can be used to provide additional information to
---custom handlers when making custom skill progressions.
---@param skillid string The ID of the skill that was used
---@param options any A table of parameters. Must contain one of `skillGain` or `useType`. It's best to always include `useType` if applicable, even if you set `skillGain`, as it may be used * `skillGain` - The numeric amount of skill to be gained. * `useType` - #SkillUseType, A number from 0 to 3 (inclusive) representing the way the skill was used, with each use type having a different skill progression rate. Available use types and its effect is skill specific. See openmw.interfaces.SkillProgression.SkillUseType * `scale` - A numeric value used to scale the skill gain. Ignored if the `skillGain` parameter is set.
function SkillProgression.skillUsed(skillid, options) end

---Trigger a skill level up, activating relevant handlers
---@param skillid string The id of the skill to level up.
---@param source openmw.interfaces.SkillProgression.SkillLevelUpSource The source of the skill increase. Note that passing a value of openmw.interfaces.SkillProgression.SkillLevelUpSource.Jail will cause a skill decrease for all skills except sneak and security.
function SkillProgression.skillLevelUp(skillid, source) end

---Construct a table of skill level up options
---@param skillid string The id of the skill to level up
---@param source openmw.interfaces.SkillProgression.SkillLevelUpSource The source of the skill increase
---@return table The options to pass to the skill level up handlers
function SkillProgression.getSkillLevelUpOptions(skillid, source) end

---Compute the total skill gain required to level up a skill based on its current level, and other modifying factors such as major skills and specialization.
---Use the interface in these handlers so any overrides will receive the calls.
---@param skillid string The id of the skill to compute skill progress requirement for
function SkillProgression.getSkillProgressRequirement(skillid) end

return SkillProgression
