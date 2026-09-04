---@meta
---@omw-context all

---Defines functions and types that are available in local, global, menu, and load scripts.
---@class openmw.core
local core = {}

---@class openmw.core.All
---@field API_REVISION number
---@field contentFiles openmw.core.ContentFiles
---@field getFormId fun(contentFile: string, index: number): string
---@field getGameDifficulty fun(): number
---@field l10n fun(context: string, fallbackLocale?: string): fun(...): any

---@class openmw.core.Runtime: openmw.core.All
---@field dialogue openmw.core.Dialogue
---@field factions openmw.core.Factions
---@field getGMST fun(setting: string): any
---@field getGameTime fun(): number
---@field getGameTimeScale fun(): number
---@field getRealTime fun(): number
---@field getSimulationTime fun(): number
---@field getSimulationTimeScale fun(): number
---@field isWorldPaused fun(): boolean
---@field land openmw.core.Land
---@field magic openmw.core.Magic
---@field mwscripts openmw.core.MWScripts
---@field quit fun()
---@field regions openmw.core.Regions
---@field sendGlobalEvent fun(eventName: string, eventData: any)
---@field sound openmw.core.Sound
---@field stats openmw.core.Stats
---@field weather openmw.core.Weather

---@class openmw.core.FrameRuntime: openmw.core.Runtime
---@field getRealFrameDuration fun(): number

---@class openmw.core.Load: openmw.core.All
---@class openmw.core.Global: openmw.core.Runtime
---@class openmw.core.Local: openmw.core.FrameRuntime
---@class openmw.core.Player: openmw.core.FrameRuntime
---@class openmw.core.Menu: openmw.core.FrameRuntime

---@class openmw.core.Dialogue
local Dialogue = {}

---@class openmw.core.DialogueRecords
local DialogueRecords = {}

---@class openmw.core.Effects
local Effects = {}

---@class openmw.core.Enchantments
local Enchantments = {}

---@class openmw.core.Factions
local Factions = {}

---@class openmw.core.Land
local Land = {}

---@class openmw.core.MWScripts
local MWScripts = {}

---@class openmw.core.Magic
local Magic = {}

---@class openmw.core.Regions
local Regions = {}

---@class openmw.core.Sound
local Sound = {}

---@class openmw.core.Spells
local Spells = {}

---@class openmw.core.Stats
local Stats = {}

---@class openmw.core.Weather
local Weather = {}

---@alias openmw.core.MoonPhaseFull 0
---@alias openmw.core.MoonPhaseWaningGibbous 1
---@alias openmw.core.MoonPhaseThirdQuarter 2
---@alias openmw.core.MoonPhaseWaningCrescent 3
---@alias openmw.core.MoonPhaseNew 4
---@alias openmw.core.MoonPhaseWaxingCrescent 5
---@alias openmw.core.MoonPhaseFirstQuarter 6
---@alias openmw.core.MoonPhaseWaxingGibbous 7
---@alias openmw.core.MoonPhase openmw.core.MoonPhaseFull|openmw.core.MoonPhaseWaningGibbous|openmw.core.MoonPhaseThirdQuarter|openmw.core.MoonPhaseWaningCrescent|openmw.core.MoonPhaseNew|openmw.core.MoonPhaseWaxingCrescent|openmw.core.MoonPhaseFirstQuarter|openmw.core.MoonPhaseWaxingGibbous
---@class openmw.core.MOON_PHASE
---@field Full openmw.core.MoonPhaseFull
---@field WaningGibbous openmw.core.MoonPhaseWaningGibbous
---@field ThirdQuarter openmw.core.MoonPhaseThirdQuarter
---@field WaningCrescent openmw.core.MoonPhaseWaningCrescent
---@field New openmw.core.MoonPhaseNew
---@field WaxingCrescent openmw.core.MoonPhaseWaxingCrescent
---@field FirstQuarter openmw.core.MoonPhaseFirstQuarter
---@field WaxingGibbous openmw.core.MoonPhaseWaxingGibbous
local MOON_PHASE = {}

---@class openmw.core.Moon
---@field name string The moon's name. For Morrowind, "Masser" or "Secunda".
---@field phase openmw.core.MoonPhase One of openmw.core.MOON_PHASE.
---@field phaseValue number MWScript-compatible phase value: 0 new, 1 crescent, 2 quarter, 3 gibbous, or 4 full.
---@field alpha number The alpha of the moon between 0 and 1. 0 when the moon is not visible in the sky.
local Moon = {}

---Functions working with the list of currently loaded content files.
---@class openmw.core.ContentFiles
---@field list string[] The current load order (list of content file names).
local ContentFiles = {}

---A cell of the game world.
---@class openmw.core.Cell
---@field name string Name of the cell (can be empty string).
---@field displayName string Human-readable cell name (takes into account *.cel file localizations). Can be an empty string.
---@field id string Unique record ID of the cell, based on cell name for interiors and the worldspace for exteriors, or the formID of the cell for ESM4 cells.
---@field region string|nil Region of the cell (can be nil).
---@field isExterior boolean Whether the cell is an exterior cell. "Exterior" means grid of cells where the player can seamless walk from one cell to another without teleports. QuasiExterior (interior with sky) is not an exterior.
---@field isQuasiExterior boolean (DEPRECATED, use `hasTag("QuasiExterior")`) Whether the cell is a quasi exterior (like interior but with the sky and the weather).
---@field gridX number|nil Index of the cell by X (only for exteriors).
---@field gridY number|nil Index of the cell by Y (only for exteriors).
---@field worldSpaceId string|nil Id of the world space (can be nil).
---@field hasWater boolean True if the cell contains water.
---@field waterLevel number|nil The water level of the cell. (nil if cell has no water).
---@field hasSky boolean True if in this cell sky should be rendered.
---@field pathGrid openmw.core.PathGrid|nil The cell's PathGrid if it has one.
local Cell = {}

---@class openmw.core.LCell: openmw.core.Cell
local LCell = {}

---@class openmw.core.GCell: openmw.core.Cell
local GCell = {}

---A cell's path grid marking traversable paths.
---@class openmw.core.PathGrid
local PathGrid = {}

---A point in a cell's path grid.
---@class openmw.core.PathGridPoint
---@field autoGenerated boolean True if this node was automatically generated in the editor.
---@field relativePosition openmw.util.Vector3 The point's position relative to the cell's origin. An exterior cell's origin is its southwest corner.
---@field connections openmw.core.PathGridPoint[] A list of points connected to this point.
local PathGridPoint = {}

---@class openmw.core.ActiveSpell
---@field name string The spell or item display name
---@field id string Record id of the spell or item used to cast the spell
---@field item openmw.Object|nil The enchanted item used to cast the spell, or nil if the spell was not cast from an enchanted item. Note that if the spell was cast for a single-use enchantment such as a scroll, this will be nil.
---@field caster openmw.Object|nil The caster object, or nil if the spell has no defined caster
---@field fromEquipment boolean If set, this spell is tied to an equipped item and can only be ended by unequipping the item.
---@field temporary boolean If set, this spell effect is temporary and should end on its own. Either after a single application or after its duration has run out.
---@field affectsBaseValues boolean If set, this spell affects the base values of affected stats, rather than modifying current values.
---@field stackable boolean If set, this spell can be applied multiple times. If not set, the same spell can only be applied once from the same source (where source is determined by caster + item). In vanilla rules, consumables are stackable while spells and enchantments are not.
---@field activeSpellId string Uniquely identifies this active spell within the affected actor's list of active spells.
---@field effects openmw.core.ActiveSpellEffect[] The active effects (ActiveSpellEffect) of this spell.
local ActiveSpell = {}

---@class openmw.core.ActiveSpellEffect
---@field index number Index of this effect within the original list of MagicEffectWithParams of the spell/enchantment/potion this effect came from.
---@field affectedSkill string|nil Optional skill ID
---@field affectedAttribute string|nil Optional attribute ID
---@field id string Magic effect id
---@field name string Localized name of the effect
---@field magnitudeThisFrame number|nil The magnitude of the effect in the current frame. This will be a new random number between minMagnitude and maxMagnitude every frame. Or nil if the effect has no magnitude.
---@field minMagnitude number|nil The minimum magnitude of this effect, or nil if the effect has no magnitude.
---@field maxMagnitude number|nil The maximum magnitude of this effect, or nil if the effect has no magnitude.
---@field duration number|nil Total duration in seconds of this spell effect, should not be confused with remaining duration. Or nil if the effect is not temporary.
---@field durationLeft number|nil Remaining duration in seconds of this spell effect, or nil if the effect is not temporary.
local ActiveSpellEffect = {}

---`core.magic.ENCHANTMENT_TYPE`
---@alias openmw.core.EnchantmentTypeCastOnce 0
---@alias openmw.core.EnchantmentTypeCastOnStrike 1
---@alias openmw.core.EnchantmentTypeCastOnUse 2
---@alias openmw.core.EnchantmentTypeConstantEffect 3
---@alias openmw.core.EnchantmentType openmw.core.EnchantmentTypeCastOnce|openmw.core.EnchantmentTypeCastOnStrike|openmw.core.EnchantmentTypeCastOnUse|openmw.core.EnchantmentTypeConstantEffect

---@class openmw.core.EnchantmentTypeValues
---@field CastOnce openmw.core.EnchantmentTypeCastOnce Enchantment can be cast once, destroying the enchanted item.
---@field CastOnStrike openmw.core.EnchantmentTypeCastOnStrike Enchantment is cast on strike, if there is enough charge.
---@field CastOnUse openmw.core.EnchantmentTypeCastOnUse Enchantment is cast when used, if there is enough charge.
---@field ConstantEffect openmw.core.EnchantmentTypeConstantEffect Enchantment is always active when equipped.
local EnchantmentTypeValues = {}

---local function getRecord(item)
---end
---local function getEnchantment(item)
---end
---@class openmw.core.Enchantment
---@field id string Enchantment id
---@field type openmw.core.EnchantmentType
---@field autocalcFlag boolean (DEPRECATED, use isAutocalc) If set, the casting cost should be computed based on the effect list rather than read from the cost field
---@field isAutocalc boolean If set, the casting cost should be computed based on the effect list rather than read from the cost field
---@field cost number
---@field charge number Charge capacity. Should not be confused with current charge.
---@field effects openmw.core.MagicEffectWithParams[] The effects (MagicEffectWithParams) of the enchantment
local Enchantment = {}

---Inventory of a player/NPC or a content of a container.
---@class openmw.core.Inventory
local Inventory = {}

---`core.magic.RANGE`
---@alias openmw.core.SpellRangeSelf 0
---@alias openmw.core.SpellRangeTouch 1
---@alias openmw.core.SpellRangeTarget 2
---@alias openmw.core.SpellRange openmw.core.SpellRangeSelf|openmw.core.SpellRangeTouch|openmw.core.SpellRangeTarget

---@class openmw.core.SpellRangeValues
---@field Self openmw.core.SpellRangeSelf Applied on self.
---@field Touch openmw.core.SpellRangeTouch On touch.
---@field Target openmw.core.SpellRangeTarget Ranged spell.
local SpellRangeValues = {}

---`core.magic.EFFECT_TYPE`
---@class openmw.core.MagicEffectId
---@field WaterBreathing string "waterbreathing"
---@field SwiftSwim string "swiftswim"
---@field WaterWalking string "waterwalking"
---@field Shield string "shield"
---@field FireShield string "fireshield"
---@field LightningShield string "lightningshield"
---@field FrostShield string "frostshield"
---@field Burden string "burden"
---@field Feather string "feather"
---@field Jump string "jump"
---@field Levitate string "levitate"
---@field SlowFall string "slowfall"
---@field Lock string "lock"
---@field Open string "open"
---@field FireDamage string "firedamage"
---@field ShockDamage string "shockdamage"
---@field FrostDamage string "frostdamage"
---@field DrainAttribute string "drainattribute"
---@field DrainHealth string "drainhealth"
---@field DrainMagicka string "drainmagicka"
---@field DrainFatigue string "drainfatigue"
---@field DrainSkill string "drainskill"
---@field DamageAttribute string "damageattribute"
---@field DamageHealth string "damagehealth"
---@field DamageMagicka string "damagemagicka"
---@field DamageFatigue string "damagefatigue"
---@field DamageSkill string "damageskill"
---@field Poison string "poison"
---@field WeaknessToFire string "weaknesstofire"
---@field WeaknessToFrost string "weaknesstofrost"
---@field WeaknessToShock string "weaknesstoshock"
---@field WeaknessToMagicka string "weaknesstomagicka"
---@field WeaknessToCommonDisease string "weaknesstocommondisease"
---@field WeaknessToBlightDisease string "weaknesstoblightdisease"
---@field WeaknessToCorprusDisease string "weaknesstocorprusdisease"
---@field WeaknessToPoison string "weaknesstopoison"
---@field WeaknessToNormalWeapons string "weaknesstonormalweapons"
---@field DisintegrateWeapon string "disintegrateweapon"
---@field DisintegrateArmor string "disintegratearmor"
---@field Invisibility string "invisibility"
---@field Chameleon string "chameleon"
---@field Light string "light"
---@field Sanctuary string "sanctuary"
---@field NightEye string "nighteye"
---@field Charm string "charm"
---@field Paralyze string "paralyze"
---@field Silence string "silence"
---@field Blind string "blind"
---@field Sound string "sound"
---@field CalmHumanoid string "calmhumanoid"
---@field CalmCreature string "calmcreature"
---@field FrenzyHumanoid string "frenzyhumanoid"
---@field FrenzyCreature string "frenzycreature"
---@field DemoralizeHumanoid string "demoralizehumanoid"
---@field DemoralizeCreature string "demoralizecreature"
---@field RallyHumanoid string "rallyhumanoid"
---@field RallyCreature string "rallycreature"
---@field Dispel string "dispel"
---@field Soultrap string "soultrap"
---@field Telekinesis string "telekinesis"
---@field Mark string "mark"
---@field Recall string "recall"
---@field DivineIntervention string "divineintervention"
---@field AlmsiviIntervention string "almsiviintervention"
---@field DetectAnimal string "detectanimal"
---@field DetectEnchantment string "detectenchantment"
---@field DetectKey string "detectkey"
---@field SpellAbsorption string "spellabsorption"
---@field Reflect string "reflect"
---@field CureCommonDisease string "curecommondisease"
---@field CureBlightDisease string "cureblightdisease"
---@field CureCorprusDisease string "curecorprusdisease"
---@field CurePoison string "curepoison"
---@field CureParalyzation string "cureparalyzation"
---@field RestoreAttribute string "restoreattribute"
---@field RestoreHealth string "restorehealth"
---@field RestoreMagicka string "restoremagicka"
---@field RestoreFatigue string "restorefatigue"
---@field RestoreSkill string "restoreskill"
---@field FortifyAttribute string "fortifyattribute"
---@field FortifyHealth string "fortifyhealth"
---@field FortifyMagicka string "fortifymagicka"
---@field FortifyFatigue string "fortifyfatigue"
---@field FortifySkill string "fortifyskill"
---@field FortifyMaximumMagicka string "fortifymaximummagicka"
---@field AbsorbAttribute string "absorbattribute"
---@field AbsorbHealth string "absorbhealth"
---@field AbsorbMagicka string "absorbmagicka"
---@field AbsorbFatigue string "absorbfatigue"
---@field AbsorbSkill string "absorbskill"
---@field ResistFire string "resistfire"
---@field ResistFrost string "resistfrost"
---@field ResistShock string "resistshock"
---@field ResistMagicka string "resistmagicka"
---@field ResistCommonDisease string "resistcommondisease"
---@field ResistBlightDisease string "resistblightdisease"
---@field ResistCorprusDisease string "resistcorprusdisease"
---@field ResistPoison string "resistpoison"
---@field ResistNormalWeapons string "resistnormalweapons"
---@field ResistParalysis string "resistparalysis"
---@field RemoveCurse string "removecurse"
---@field TurnUndead string "turnundead"
---@field SummonScamp string "summonscamp"
---@field SummonClannfear string "summonclannfear"
---@field SummonDaedroth string "summondaedroth"
---@field SummonDremora string "summondremora"
---@field SummonAncestralGhost string "summonancestralghost"
---@field SummonSkeletalMinion string "summonskeletalminion"
---@field SummonBonewalker string "summonbonewalker"
---@field SummonGreaterBonewalker string "summongreaterbonewalker"
---@field SummonBonelord string "summonbonelord"
---@field SummonWingedTwilight string "summonwingedtwilight"
---@field SummonHunger string "summonhunger"
---@field SummonGoldenSaint string "summongoldensaint"
---@field SummonFlameAtronach string "summonflameatronach"
---@field SummonFrostAtronach string "summonfrostatronach"
---@field SummonStormAtronach string "summonstormatronach"
---@field FortifyAttack string "fortifyattack"
---@field CommandCreature string "commandcreature"
---@field CommandHumanoid string "commandhumanoid"
---@field BoundDagger string "bounddagger"
---@field BoundLongsword string "boundlongsword"
---@field BoundMace string "boundmace"
---@field BoundBattleAxe string "boundbattleaxe"
---@field BoundSpear string "boundspear"
---@field BoundLongbow string "boundlongbow"
---@field ExtraSpell string "extraspell"
---@field BoundCuirass string "boundcuirass"
---@field BoundHelm string "boundhelm"
---@field BoundBoots string "boundboots"
---@field BoundShield string "boundshield"
---@field BoundGloves string "boundgloves"
---@field Corprus string "corprus"
---@field Vampirism string "vampirism"
---@field SummonCenturionSphere string "summoncenturionsphere"
---@field SunDamage string "sundamage"
---@field StuntedMagicka string "stuntedmagicka"
---@field SummonFabricant string "summonfabricant"
---@field SummonWolf string "summonwolf"
---@field SummonBear string "summonbear"
---@field SummonBonewolf string "summonbonewolf"
---@field SummonCreature04 string "summoncreature04"
---@field SummonCreature05 string "summoncreature05"
local MagicEffectId = {}

---`core.magic.SPELL_TYPE`
---@alias openmw.core.SpellTypeSpell 0
---@alias openmw.core.SpellTypeAbility 1
---@alias openmw.core.SpellTypeBlight 2
---@alias openmw.core.SpellTypeDisease 3
---@alias openmw.core.SpellTypeCurse 4
---@alias openmw.core.SpellTypePower 5
---@alias openmw.core.SpellType openmw.core.SpellTypeSpell|openmw.core.SpellTypeAbility|openmw.core.SpellTypeBlight|openmw.core.SpellTypeDisease|openmw.core.SpellTypeCurse|openmw.core.SpellTypePower

---@class openmw.core.SpellTypeValues
---@field Spell openmw.core.SpellTypeSpell Normal spell, must be cast and costs mana.
---@field Ability openmw.core.SpellTypeAbility Innate ability, always in effect.
---@field Blight openmw.core.SpellTypeBlight Blight disease.
---@field Disease openmw.core.SpellTypeDisease Common disease.
---@field Curse openmw.core.SpellTypeCurse Curse.
---@field Power openmw.core.SpellTypePower Power, can be used once a day.
local SpellTypeValues = {}

---@class openmw.core.Spell
---@field id string Spell id
---@field name string Spell name
---@field type openmw.core.SpellType
---@field cost number
---@field effects openmw.core.MagicEffectWithParams[] The effects (MagicEffectWithParams) of the spell
---@field alwaysSucceedFlag boolean If set, the spell should ignore skill checks and always succeed.
---@field starterSpellFlag boolean If set, the spell can be selected as a player's starting spell.
---@field autocalcFlag boolean (DEPRECATED, use isAutocalc) If set, the casting cost should be computed based on the effect list rather than read from the cost field
---@field isAutocalc boolean If set, the casting cost should be computed based on the effect list rather than read from the cost field
local Spell = {}

---@class openmw.core.MagicEffect
---@field id string Effect ID
---@field icon string Effect Icon Path
---@field name string Localized name of the effect
---@field description string Localized description of the effect
---@field school string Skill ID that is this effect's school
---@field baseCost number
---@field color openmw.util.Color
---@field harmful boolean If set, the effect is considered harmful and should elicit a hostile reaction from affected NPCs.
---@field continuousVfx boolean Whether the magic effect's vfx should loop or not
---@field hasDuration boolean If set, the magic effect has a duration. As an example, divine intervention has no duration while fire damage does.
---@field hasMagnitude boolean If set, the magic effect depends on a magnitude. As an example, cure common disease has no magnitude while chameleon does.
---@field hasAttribute boolean True if the effect requires an attribute parameter.
---@field hasSkill boolean True if the effect requires a skill parameter.
---@field isAppliedOnce boolean If set, the magic effect is applied fully on cast, rather than being continuously applied over the effect's duration. For example, chameleon is applied once, while fire damage is continuously applied for the duration.
---@field casterLinked boolean If set, it is implied the magic effect links back to the caster in some way and should end immediately or never be applied if the caster dies or is not an actor.
---@field nonRecastable boolean If set, this effect cannot be re-applied until it has ended. This is used by bound equipment spells.
---@field particle string Identifier of the particle texture
---@field castStatic string Identifier of the vfx static used for casting
---@field hitStatic string Identifier of the vfx static used on hit
---@field areaStatic string Identifier of the vfx static used for AOE spells
---@field bolt string Identifier of the projectile used for ranged spells
---@field castSound string Identifier of the sound used for casting
---@field hitSound string Identifier of the sound used on hit
---@field areaSound string Identifier of the sound used for AOE spells
---@field boltSound string Identifier of the projectile sound used for ranged spells
---@field onSelf boolean True if the effect can be cast on self.
---@field onTouch boolean True if the effect can be cast on touch.
---@field onTarget boolean True if the effect can be cast on target.
---@field unreflectable boolean True if the effect cannot be reflected.
---@field allowsSpellmaking boolean True if the effect is available for spellmaking.
---@field allowsEnchanting boolean True if the effect is available for enchanting.
---@field negativeLight boolean True if the effect casts negative light.
---@field speed number Projectile speed.
local MagicEffect = {}

---@class openmw.core.MagicEffectWithParams
---@field effect openmw.core.MagicEffect MagicEffect
---@field id string ID of the associated MagicEffect
---@field affectedSkill string|nil Optional skill ID
---@field affectedAttribute string|nil Optional attribute ID
---@field range number
---@field area number
---@field magnitudeMin number
---@field magnitudeMax number
---@field duration number
---@field index number Index of this effect within the original list of MagicEffectWithParams of the spell/enchantment/potion this effect came from.
local MagicEffectWithParams = {}

---Magic effect that is currently active on an actor.
---@class openmw.core.ActiveEffect
---@field affectedSkill string|nil Optional skill ID
---@field affectedAttribute string|nil Optional attribute ID
---@field id string Effect id string
---@field name string Localized name of the effect
---@field magnitude number Current magnitude of the effect. Will be set to 0 when the effect is removed or expires.
---@field magnitudeBase number
---@field magnitudeModifier number
local ActiveEffect = {}

---@class openmw.core.SoundRecord
---@field id string Sound id
---@field fileName string Normalized path to sound file in VFS
---@field volume number Raw sound volume, from 0 to 255
---@field minRange number Raw minimal range value, from 0 to 255
---@field maxRange number Raw maximal range value, from 0 to 255
local SoundRecord = {}

---`core.stats.Attribute`
---Implements [iterables#List](iterables.html#List) of #AttributeRecord.
---@class openmw.core.Attribute
---@field records openmw.core.AttributeRecord[] A read-only list of all AttributeRecords in the world database, may be indexed by recordId.
local Attribute = {}

---`core.stats.Skill`
---Implements [iterables#List](iterables.html#List) of #SkillRecord.
---@class openmw.core.Skill
---@field records openmw.core.SkillRecord[] A read-only list of all SkillRecords in the world database, may be indexed by recordId.
local Skill = {}

---@class openmw.core.AttributeRecord
---@field id string Record id
---@field name string Human-readable name
---@field description string Human-readable description
---@field icon string VFS path to the icon
---@field werewolfValue number Value for werewolf players
local AttributeRecord = {}

---@class openmw.core.SkillRecord
---@field id string Record id
---@field name string Human-readable name
---@field description string Human-readable description
---@field icon string VFS path to the icon
---@field specialization string Skill specialization. Either combat, magic, or stealth.
---@field school openmw.core.MagicSchoolData Optional magic school
---@field attribute string The id of the skill's governing attribute
---@field skillGain table Table of the 4 possible skill gain values. See [SkillProgression#SkillUseType](interface_skill_progression.html#SkillUseType).
---@field werewolfValue number Value for werewolf players
local SkillRecord = {}

---@class openmw.core.MagicSchoolData
---@field name string Human-readable name
---@field areaSound string VFS path to the area sound
---@field boltSound string VFS path to the bolt sound
---@field castSound string VFS path to the cast sound
---@field failureSound string VFS path to the failure sound
---@field hitSound string VFS path to the hit sound
---@field autoCalcMax number Maximum number of spells of this school to auto calculate
local MagicSchoolData = {}

---Depending on which store this read-only dialogue record is from, it may either be a journal, topic, greeting, persuasion or voice.
---@class openmw.core.DialogueRecord
---@field id string Record identifier
---@field name string Same as id, but with upper cases preserved.
---@field questName string Non-nil only for journal records with available value. Holds the quest name for this journal entry. Same info may be available under `infos[1].text` as well, but this variable is made for convenience.
---@field infos openmw.core.DialogueRecordInfo[] A read-only list containing all DialogueRecordInfos for this record, in order.
local DialogueRecord = {}

---Holds the read-only data for one of many info entries inside a dialogue record. Depending on the type of the dialogue record (journal, topic, greeting, persuasion or voice), it could be, for example, a single journal entry or a NPC dialogue line.
---local aa = core.dialogue.topic.records['advancement'].infos[100].text
---local bb = core.dialogue.voice.records['flee'].infos[149].sound
---@class openmw.core.DialogueRecordInfo
---@field id string Identifier for this info entry. Is unique only within the DialogueRecord it belongs to.
---@field text string Text associated with this info entry.
local DialogueRecordInfo = {}

---@class openmw.core.DialogueInfoCondition
---@field operator openmw.core.DialogueConditionOperator The openmw.core.DialogueConditionOperator to use in the comparison.
---@field type openmw.core.DialogueConditionType The condition's DialogueConditionType.
---@field value number The value to compare to
---@field recordId string The record ID to use in the comparison
---@field variableName string The name of the global or local mwscript variable to compare to
---@field cellName string The cell name to compare to
local DialogueInfoCondition = {}

---`core.dialogue.CONDITION_OPERATOR`
---@alias openmw.core.DialogueConditionOperatorEqual 48
---@alias openmw.core.DialogueConditionOperatorNotEqual 49
---@alias openmw.core.DialogueConditionOperatorGreater 50
---@alias openmw.core.DialogueConditionOperatorGreaterEqual 51
---@alias openmw.core.DialogueConditionOperatorLess 52
---@alias openmw.core.DialogueConditionOperatorLessEqual 53
---@alias openmw.core.DialogueConditionOperator openmw.core.DialogueConditionOperatorEqual|openmw.core.DialogueConditionOperatorNotEqual|openmw.core.DialogueConditionOperatorGreater|openmw.core.DialogueConditionOperatorGreaterEqual|openmw.core.DialogueConditionOperatorLess|openmw.core.DialogueConditionOperatorLessEqual

---@class openmw.core.DialogueConditionOperatorValues
---@field Equal openmw.core.DialogueConditionOperatorEqual ==
---@field NotEqual openmw.core.DialogueConditionOperatorNotEqual !=
---@field Greater openmw.core.DialogueConditionOperatorGreater Greater-than comparison operator
---@field GreaterEqual openmw.core.DialogueConditionOperatorGreaterEqual Greater-than-or-equal comparison operator
---@field Less openmw.core.DialogueConditionOperatorLess Less-than comparison operator
---@field LessEqual openmw.core.DialogueConditionOperatorLessEqual Less-than-or-equal comparison operator
local DialogueConditionOperator = {}

---`core.dialogue.CONDITION_TYPE`
---@alias openmw.core.DialogueConditionTypeFacReactionLowest 0
---@alias openmw.core.DialogueConditionTypeFacReactionHighest 1
---@alias openmw.core.DialogueConditionTypeRankRequirement 2
---@alias openmw.core.DialogueConditionTypeReputation 3
---@alias openmw.core.DialogueConditionTypeHealthPercent 4
---@alias openmw.core.DialogueConditionTypePcReputation 5
---@alias openmw.core.DialogueConditionTypePcLevel 6
---@alias openmw.core.DialogueConditionTypePcHealthPercent 7
---@alias openmw.core.DialogueConditionTypePcMagicka 8
---@alias openmw.core.DialogueConditionTypePcFatigue 9
---@alias openmw.core.DialogueConditionTypePcStrength 10
---@alias openmw.core.DialogueConditionTypePcBlock 11
---@alias openmw.core.DialogueConditionTypePcArmorer 12
---@alias openmw.core.DialogueConditionTypePcMediumArmor 13
---@alias openmw.core.DialogueConditionTypePcHeavyArmor 14
---@alias openmw.core.DialogueConditionTypePcBluntWeapon 15
---@alias openmw.core.DialogueConditionTypePcLongBlade 16
---@alias openmw.core.DialogueConditionTypePcAxe 17
---@alias openmw.core.DialogueConditionTypePcSpear 18
---@alias openmw.core.DialogueConditionTypePcAthletics 19
---@alias openmw.core.DialogueConditionTypePcEnchant 20
---@alias openmw.core.DialogueConditionTypePcDestruction 21
---@alias openmw.core.DialogueConditionTypePcAlteration 22
---@alias openmw.core.DialogueConditionTypePcIllusion 23
---@alias openmw.core.DialogueConditionTypePcConjuration 24
---@alias openmw.core.DialogueConditionTypePcMysticism 25
---@alias openmw.core.DialogueConditionTypePcRestoration 26
---@alias openmw.core.DialogueConditionTypePcAlchemy 27
---@alias openmw.core.DialogueConditionTypePcUnarmored 28
---@alias openmw.core.DialogueConditionTypePcSecurity 29
---@alias openmw.core.DialogueConditionTypePcSneak 30
---@alias openmw.core.DialogueConditionTypePcAcrobatics 31
---@alias openmw.core.DialogueConditionTypePcLightArmor 32
---@alias openmw.core.DialogueConditionTypePcShortBlade 33
---@alias openmw.core.DialogueConditionTypePcMarksman 34
---@alias openmw.core.DialogueConditionTypePcMercantile 35
---@alias openmw.core.DialogueConditionTypePcSpeechcraft 36
---@alias openmw.core.DialogueConditionTypePcHandToHand 37
---@alias openmw.core.DialogueConditionTypePcGender 38
---@alias openmw.core.DialogueConditionTypePcExpelled 39
---@alias openmw.core.DialogueConditionTypePcCommonDisease 40
---@alias openmw.core.DialogueConditionTypePcBlightDisease 41
---@alias openmw.core.DialogueConditionTypePcClothingModifier 42
---@alias openmw.core.DialogueConditionTypePcCrimeLevel 43
---@alias openmw.core.DialogueConditionTypeSameGender 44
---@alias openmw.core.DialogueConditionTypeSameRace 45
---@alias openmw.core.DialogueConditionTypeSameFaction 46
---@alias openmw.core.DialogueConditionTypeFactionRankDifference 47
---@alias openmw.core.DialogueConditionTypeDetected 48
---@alias openmw.core.DialogueConditionTypeAlarmed 49
---@alias openmw.core.DialogueConditionTypeChoice 50
---@alias openmw.core.DialogueConditionTypePcIntelligence 51
---@alias openmw.core.DialogueConditionTypePcWillpower 52
---@alias openmw.core.DialogueConditionTypePcAgility 53
---@alias openmw.core.DialogueConditionTypePcSpeed 54
---@alias openmw.core.DialogueConditionTypePcEndurance 55
---@alias openmw.core.DialogueConditionTypePcPersonality 56
---@alias openmw.core.DialogueConditionTypePcLuck 57
---@alias openmw.core.DialogueConditionTypePcCorprus 58
---@alias openmw.core.DialogueConditionTypeWeather 59
---@alias openmw.core.DialogueConditionTypePcVampire 60
---@alias openmw.core.DialogueConditionTypeLevel 61
---@alias openmw.core.DialogueConditionTypeAttacked 62
---@alias openmw.core.DialogueConditionTypeTalkedToPc 63
---@alias openmw.core.DialogueConditionTypePcHealth 64
---@alias openmw.core.DialogueConditionTypeCreatureTarget 65
---@alias openmw.core.DialogueConditionTypeFriendHit 66
---@alias openmw.core.DialogueConditionTypeFight 67
---@alias openmw.core.DialogueConditionTypeHello 68
---@alias openmw.core.DialogueConditionTypeAlarm 69
---@alias openmw.core.DialogueConditionTypeFlee 70
---@alias openmw.core.DialogueConditionTypeShouldAttack 71
---@alias openmw.core.DialogueConditionTypeWerewolf 72
---@alias openmw.core.DialogueConditionTypePcWerewolfKills 73
---@alias openmw.core.DialogueConditionTypeGlobal 74
---@alias openmw.core.DialogueConditionTypeLocal 75
---@alias openmw.core.DialogueConditionTypeJournal 76
---@alias openmw.core.DialogueConditionTypeItem 77
---@alias openmw.core.DialogueConditionTypeDead 78
---@alias openmw.core.DialogueConditionTypeNotId 79
---@alias openmw.core.DialogueConditionTypeNotFaction 80
---@alias openmw.core.DialogueConditionTypeNotClass 81
---@alias openmw.core.DialogueConditionTypeNotRace 82
---@alias openmw.core.DialogueConditionTypeNotCell 83
---@alias openmw.core.DialogueConditionTypeNotLocal 84
---@alias openmw.core.DialogueConditionType openmw.core.DialogueConditionTypeFacReactionLowest|openmw.core.DialogueConditionTypeFacReactionHighest|openmw.core.DialogueConditionTypeRankRequirement|openmw.core.DialogueConditionTypeReputation|openmw.core.DialogueConditionTypeHealthPercent|openmw.core.DialogueConditionTypePcReputation|openmw.core.DialogueConditionTypePcLevel|openmw.core.DialogueConditionTypePcHealthPercent|openmw.core.DialogueConditionTypePcMagicka|openmw.core.DialogueConditionTypePcFatigue|openmw.core.DialogueConditionTypePcStrength|openmw.core.DialogueConditionTypePcBlock|openmw.core.DialogueConditionTypePcArmorer|openmw.core.DialogueConditionTypePcMediumArmor|openmw.core.DialogueConditionTypePcHeavyArmor|openmw.core.DialogueConditionTypePcBluntWeapon|openmw.core.DialogueConditionTypePcLongBlade|openmw.core.DialogueConditionTypePcAxe|openmw.core.DialogueConditionTypePcSpear|openmw.core.DialogueConditionTypePcAthletics|openmw.core.DialogueConditionTypePcEnchant|openmw.core.DialogueConditionTypePcDestruction|openmw.core.DialogueConditionTypePcAlteration|openmw.core.DialogueConditionTypePcIllusion|openmw.core.DialogueConditionTypePcConjuration|openmw.core.DialogueConditionTypePcMysticism|openmw.core.DialogueConditionTypePcRestoration|openmw.core.DialogueConditionTypePcAlchemy|openmw.core.DialogueConditionTypePcUnarmored|openmw.core.DialogueConditionTypePcSecurity|openmw.core.DialogueConditionTypePcSneak|openmw.core.DialogueConditionTypePcAcrobatics|openmw.core.DialogueConditionTypePcLightArmor|openmw.core.DialogueConditionTypePcShortBlade|openmw.core.DialogueConditionTypePcMarksman|openmw.core.DialogueConditionTypePcMercantile|openmw.core.DialogueConditionTypePcSpeechcraft|openmw.core.DialogueConditionTypePcHandToHand|openmw.core.DialogueConditionTypePcGender|openmw.core.DialogueConditionTypePcExpelled|openmw.core.DialogueConditionTypePcCommonDisease|openmw.core.DialogueConditionTypePcBlightDisease|openmw.core.DialogueConditionTypePcClothingModifier|openmw.core.DialogueConditionTypePcCrimeLevel|openmw.core.DialogueConditionTypeSameGender|openmw.core.DialogueConditionTypeSameRace|openmw.core.DialogueConditionTypeSameFaction|openmw.core.DialogueConditionTypeFactionRankDifference|openmw.core.DialogueConditionTypeDetected|openmw.core.DialogueConditionTypeAlarmed|openmw.core.DialogueConditionTypeChoice|openmw.core.DialogueConditionTypePcIntelligence|openmw.core.DialogueConditionTypePcWillpower|openmw.core.DialogueConditionTypePcAgility|openmw.core.DialogueConditionTypePcSpeed|openmw.core.DialogueConditionTypePcEndurance|openmw.core.DialogueConditionTypePcPersonality|openmw.core.DialogueConditionTypePcLuck|openmw.core.DialogueConditionTypePcCorprus|openmw.core.DialogueConditionTypeWeather|openmw.core.DialogueConditionTypePcVampire|openmw.core.DialogueConditionTypeLevel|openmw.core.DialogueConditionTypeAttacked|openmw.core.DialogueConditionTypeTalkedToPc|openmw.core.DialogueConditionTypePcHealth|openmw.core.DialogueConditionTypeCreatureTarget|openmw.core.DialogueConditionTypeFriendHit|openmw.core.DialogueConditionTypeFight|openmw.core.DialogueConditionTypeHello|openmw.core.DialogueConditionTypeAlarm|openmw.core.DialogueConditionTypeFlee|openmw.core.DialogueConditionTypeShouldAttack|openmw.core.DialogueConditionTypeWerewolf|openmw.core.DialogueConditionTypePcWerewolfKills|openmw.core.DialogueConditionTypeGlobal|openmw.core.DialogueConditionTypeLocal|openmw.core.DialogueConditionTypeJournal|openmw.core.DialogueConditionTypeItem|openmw.core.DialogueConditionTypeDead|openmw.core.DialogueConditionTypeNotId|openmw.core.DialogueConditionTypeNotFaction|openmw.core.DialogueConditionTypeNotClass|openmw.core.DialogueConditionTypeNotRace|openmw.core.DialogueConditionTypeNotCell|openmw.core.DialogueConditionTypeNotLocal

---@class openmw.core.DialogueConditionTypeValues
---@field FacReactionLowest openmw.core.DialogueConditionTypeFacReactionLowest Lowest faction reaction from the speaker's primary faction to the player's factions
---@field FacReactionHighest openmw.core.DialogueConditionTypeFacReactionHighest Highest faction reaction from the speaker's primary faction to the player's factions
---@field RankRequirement openmw.core.DialogueConditionTypeRankRequirement Check whether the player can advance in the speaker's primary faction
---@field Reputation openmw.core.DialogueConditionTypeReputation The speaker's reputation
---@field HealthPercent openmw.core.DialogueConditionTypeHealthPercent The speaker's health percentage
---@field PcReputation openmw.core.DialogueConditionTypePcReputation The player's reputation
---@field PcLevel openmw.core.DialogueConditionTypePcLevel The player's level
---@field PcHealthPercent openmw.core.DialogueConditionTypePcHealthPercent The player's health percentage
---@field PcMagicka openmw.core.DialogueConditionTypePcMagicka The player's current magicka
---@field PcFatigue openmw.core.DialogueConditionTypePcFatigue The player's current fatigue
---@field PcStrength openmw.core.DialogueConditionTypePcStrength The player's current strength
---@field PcBlock openmw.core.DialogueConditionTypePcBlock The player's current block
---@field PcArmorer openmw.core.DialogueConditionTypePcArmorer The player's current armorer
---@field PcMediumArmor openmw.core.DialogueConditionTypePcMediumArmor The player's current medium armor
---@field PcHeavyArmor openmw.core.DialogueConditionTypePcHeavyArmor The player's current heavy armor
---@field PcBluntWeapon openmw.core.DialogueConditionTypePcBluntWeapon The player's current blunt weapon
---@field PcLongBlade openmw.core.DialogueConditionTypePcLongBlade The player's current long blade
---@field PcAxe openmw.core.DialogueConditionTypePcAxe The player's current axe
---@field PcSpear openmw.core.DialogueConditionTypePcSpear The player's current spear
---@field PcAthletics openmw.core.DialogueConditionTypePcAthletics The player's current athletics
---@field PcEnchant openmw.core.DialogueConditionTypePcEnchant The player's current enchant
---@field PcDestruction openmw.core.DialogueConditionTypePcDestruction The player's current destruction
---@field PcAlteration openmw.core.DialogueConditionTypePcAlteration The player's current alteration
---@field PcIllusion openmw.core.DialogueConditionTypePcIllusion The player's current illusion
---@field PcConjuration openmw.core.DialogueConditionTypePcConjuration The player's current conjuration
---@field PcMysticism openmw.core.DialogueConditionTypePcMysticism The player's current mysticism
---@field PcRestoration openmw.core.DialogueConditionTypePcRestoration The player's current restoration
---@field PcAlchemy openmw.core.DialogueConditionTypePcAlchemy The player's current alchemy
---@field PcUnarmored openmw.core.DialogueConditionTypePcUnarmored The player's current unarmored
---@field PcSecurity openmw.core.DialogueConditionTypePcSecurity The player's current security
---@field PcSneak openmw.core.DialogueConditionTypePcSneak The player's current sneak
---@field PcAcrobatics openmw.core.DialogueConditionTypePcAcrobatics The player's current acrobatics
---@field PcLightArmor openmw.core.DialogueConditionTypePcLightArmor The player's current light armor
---@field PcShortBlade openmw.core.DialogueConditionTypePcShortBlade The player's current short blade
---@field PcMarksman openmw.core.DialogueConditionTypePcMarksman The player's current marksman
---@field PcMercantile openmw.core.DialogueConditionTypePcMercantile The player's current mercantile
---@field PcSpeechcraft openmw.core.DialogueConditionTypePcSpeechcraft The player's current speechcraft
---@field PcHandToHand openmw.core.DialogueConditionTypePcHandToHand The player's current hand to hand
---@field PcGender openmw.core.DialogueConditionTypePcGender The player's gender
---@field PcExpelled openmw.core.DialogueConditionTypePcExpelled Check whether the player has been expelled from the speaker's primary faction
---@field PcCommonDisease openmw.core.DialogueConditionTypePcCommonDisease Check if the player has a common disease
---@field PcBlightDisease openmw.core.DialogueConditionTypePcBlightDisease Check if the player has a blight disease
---@field PcClothingModifier openmw.core.DialogueConditionTypePcClothingModifier Check the combined value of the player's outfit
---@field PcCrimeLevel openmw.core.DialogueConditionTypePcCrimeLevel The player's bounty
---@field SameGender openmw.core.DialogueConditionTypeSameGender Check if the speaker's gender matches the player's
---@field SameRace openmw.core.DialogueConditionTypeSameRace Check if the speaker's race matches the player's
---@field SameFaction openmw.core.DialogueConditionTypeSameFaction Check if the player is a member of the speaker's primary faction
---@field FactionRankDifference openmw.core.DialogueConditionTypeFactionRankDifference The difference between the player's rank in the speaker's primary faction and the speaker's
---@field Detected openmw.core.DialogueConditionTypeDetected Whether the speaker has detected the player
---@field Alarmed openmw.core.DialogueConditionTypeAlarmed Whether the speaker was alarmed by the player's crime
---@field Choice openmw.core.DialogueConditionTypeChoice The choice index
---@field PcIntelligence openmw.core.DialogueConditionTypePcIntelligence The player's current intelligence
---@field PcWillpower openmw.core.DialogueConditionTypePcWillpower The player's current willpower
---@field PcAgility openmw.core.DialogueConditionTypePcAgility The player's current agility
---@field PcSpeed openmw.core.DialogueConditionTypePcSpeed The player's current speed
---@field PcEndurance openmw.core.DialogueConditionTypePcEndurance The player's current endurance
---@field PcPersonality openmw.core.DialogueConditionTypePcPersonality The player's current personality
---@field PcLuck openmw.core.DialogueConditionTypePcLuck The player's current luck
---@field PcCorprus openmw.core.DialogueConditionTypePcCorprus Whether the player is affected by the Corprus magic effect
---@field Weather openmw.core.DialogueConditionTypeWeather Checks the scriptId of the weather in the player's cell
---@field PcVampire openmw.core.DialogueConditionTypePcVampire Whether the player is affected by the Vampirism magic effect
---@field Level openmw.core.DialogueConditionTypeLevel The speaker's level
---@field Attacked openmw.core.DialogueConditionTypeAttacked Whether the speaker was attacked
---@field TalkedToPc openmw.core.DialogueConditionTypeTalkedToPc Whether the speaker has talked to the player before
---@field PcHealth openmw.core.DialogueConditionTypePcHealth The player's current health
---@field CreatureTarget openmw.core.DialogueConditionTypeCreatureTarget Whether the speaker is targeting a creature
---@field FriendHit openmw.core.DialogueConditionTypeFriendHit The number of times the player has hit the speaker follower
---@field Fight openmw.core.DialogueConditionTypeFight The speaker's current fight
---@field Hello openmw.core.DialogueConditionTypeHello The speaker's current hello
---@field Alarm openmw.core.DialogueConditionTypeAlarm The speaker's current alarm
---@field Flee openmw.core.DialogueConditionTypeFlee The speaker's current flee
---@field ShouldAttack openmw.core.DialogueConditionTypeShouldAttack Whether the speaker would start combat with the player
---@field Werewolf openmw.core.DialogueConditionTypeWerewolf Whether the speaker is in werewolf form
---@field PcWerewolfKills openmw.core.DialogueConditionTypePcWerewolfKills The number of werewolves killed by the player
---@field Global openmw.core.DialogueConditionTypeGlobal A comparison to the DialogueInfoCondition.variableName global variable
---@field Local openmw.core.DialogueConditionTypeLocal A comparison to the speaker's DialogueInfoCondition.variableName local variable
---@field Journal openmw.core.DialogueConditionTypeJournal A comparison to the player's DialogueInfoCondition.recordId journal index
---@field Item openmw.core.DialogueConditionTypeItem The number of copies of DialogueInfoCondition.recordId the player is carrying
---@field Dead openmw.core.DialogueConditionTypeDead The number of dead actors of the given DialogueInfoCondition.recordId
---@field NotId openmw.core.DialogueConditionTypeNotId The speaker's recordId should not match DialogueInfoCondition.recordId
---@field NotFaction openmw.core.DialogueConditionTypeNotFaction The speaker's faction ID should not match DialogueInfoCondition.recordId
---@field NotClass openmw.core.DialogueConditionTypeNotClass The speaker's class should not match DialogueInfoCondition.recordId
---@field NotRace openmw.core.DialogueConditionTypeNotRace The speaker's race should not match DialogueInfoCondition.recordId
---@field NotCell openmw.core.DialogueConditionTypeNotCell The player's cell name should not start with DialogueInfoCondition.cellName
---@field NotLocal openmw.core.DialogueConditionTypeNotLocal A comparison to the speaker's DialogueInfoCondition.variableName local variable
local DialogueConditionType = {}

---Region data record
---Each reference includes a chance and a resolved link to the full sound record.
---Valid weather ids include:
---@class openmw.core.RegionRecord
---@field id string Region ID
---@field name string Region display name
---@field mapColor openmw.util.Color Editor map color for this region.
---@field sleepList string A leveled creature list used when sleeping outdoors in this region
---@field sounds openmw.core.RegionSoundRef[] A read-only list of ambient sound references for this region.
---@field weatherProbabilities table A table mapping WeatherRecord.recordIds to their probability (0–100), should sum to 100. `"clear"`, `"cloudy"`, `"foggy"`, `"overcast"`, `"rain"`, `"thunderstorm"`, `"ashstorm"`, `"blight"`, `"snow"`, `"blizzard"`
local RegionRecord = {}

---Set one weather probability entry for this region at runtime.
---@param weatherId string Weather id to modify.
---@param value number New probability value.
function RegionRecord:setProbability(weatherId, value) end

---Reset this region's runtime weather probabilities to defaults from the loaded records.
function RegionRecord:resetProbability() end

---Region sound reference
---@class openmw.core.RegionSoundRef
---@field soundId string Sound record ID
---@field chance number Multiplicative percentage used to determine whether to play the sound
local RegionSoundRef = {}

---Faction data record
---@class openmw.core.FactionRecord
---@field id string Faction id
---@field name string Faction name
---@field ranks openmw.core.FactionRank[] A read-only list containing data for all ranks in the faction, in order.
---@field reactions table<string, number> A read-only map containing reactions of other factions to this faction.
---@field attributes string[] A read-only list containing IDs of attributes to advance ranks in the faction.
---@field skills string[] A read-only list containing IDs of skills to advance ranks in the faction.
---@field hidden boolean If true, the faction won't show in the player's skills menu
local FactionRecord = {}

---Faction rank data record
---@class openmw.core.FactionRank
---@field name string Faction name Rank display name
---@field attributeValues number[] Attributes values required to get this rank.
---@field primarySkillValue number Primary skill value required to get this rank.
---@field favouredSkillValue number Secondary skill value required to get this rank.
---@field factionReputation number Required amount of faction reputation to reach this rank.
---@field factionReaction number (DEPRECATED) Returns the same as factionReputation.
local FactionRank = {}

---MWScript data record
---@class openmw.core.MWScriptRecord
---@field id string MWScript id
---@field text string MWScript content
local MWScriptRecord = {}

---Weather data
---@class openmw.core.WeatherRecord
---@field recordId string
---@field scriptId number Read-only ID used in mwscript and dialogue
---@field name string Read-only weather name
---@field windSpeed number Affects the angle of falling rain
---@field cloudSpeed number
---@field cloudTexture string
---@field cloudsMaximumPercent number Affects the speed of weather transitions (0, 1]
---@field isStorm boolean Controls whether the weather is considered a storm for animation and movement purposes
---@field stormDirection openmw.util.Vector3
---@field glareView number Strength of the sun glare [0, 1]
---@field rainSpeed number The speed at which rain falls
---@field rainEntranceSpeed number The number of seconds between rain particle batches being created
---@field rainEffect string|nil Will return nil if weather has no rainEffect
---@field rainMaxRaindrops number The maximum number of rain particle batches to create every rainEntranceSpeed
---@field rainDiameter number The area around the player to spawn rain in
---@field rainThreshold number The minimum height of rain particles relative to the player
---@field rainMaxHeight number The maximum height relative to the player to spawn rain at
---@field rainMinHeight number The minimum height relative to the player to spawn rain at
---@field rainLoopSoundID string|nil
---@field thunderSoundID table A read-only array containing the recordIds of the thunder sounds
---@field ambientLoopSoundID string|nil
---@field particleEffect string|nil Will return nil if weather has no particleEffect
---@field distantLandFogFactor number
---@field distantLandFogOffset number
---@field sunDiscSunsetColor openmw.util.Color
---@field landFogDepth openmw.core.TimeOfDayInterpolatorFloat
---@field skyColor openmw.core.TimeOfDayInterpolatorColor
---@field ambientColor openmw.core.TimeOfDayInterpolatorColor
---@field fogColor openmw.core.TimeOfDayInterpolatorColor
---@field sunColor openmw.core.TimeOfDayInterpolatorColor
local WeatherRecord = {}

---Interpolates numbers for weathers based on time of day
---@class openmw.core.TimeOfDayInterpolatorFloat
---@field sunrise number
---@field sunset number
---@field day number
---@field night number
local TimeOfDayInterpolatorFloat = {}

---Interpolates colors for weathers based on time of day
---@class openmw.core.TimeOfDayInterpolatorColor
---@field sunrise openmw.util.Color
---@field sunset openmw.util.Color
---@field day openmw.util.Color
---@field night openmw.util.Color
local TimeOfDayInterpolatorColor = {}

---The revision of OpenMW's Lua API. It is an integer that is incremented every time the API is changed. See the actual value at the top of the page.
---@type number
core.API_REVISION = nil

---Terminates the game and quits to the OS. Should be used only for testing purposes. Not available in load scripts.
function core.quit() end

---Send an event to global scripts. Note: in menu scripts, errors if the game is not running (check openmw.menu.menu.getState.) Not available in load scripts.
---@param eventName string
---@param eventData any
function core.sendGlobalEvent(eventName, eventData) end

---Simulation time in seconds.
---The number of simulation seconds passed in the game world since starting a new game. Not available in load scripts.
---@return number
function core.getSimulationTime() end

---The scale of simulation time relative to real time. Not available in load scripts.
---@return number
function core.getSimulationTimeScale() end

---Game time in seconds. Not available in load scripts.
---@return number
function core.getGameTime() end

---The scale of game time relative to simulation time. Not available in load scripts.
---@return number
function core.getGameTimeScale() end

---Whether the world is paused. Not available in load scripts.
---@return boolean
function core.isWorldPaused() end

---Real time in seconds; starting point is not fixed (can be time since last reboot), use only for measuring intervals. For Unix time use `os.time()`. Not available in load scripts.
---@return number
function core.getRealTime() end

---Frame duration in seconds. Not available in global or load scripts.
---@return number
function core.getRealFrameDuration() end

---Get a game setting with given name (from GMST ESM records or from openmw.cfg). Not available in load scripts.
---@param setting string Setting name
---@return any
function core.getGMST(setting) end

---The game's difficulty setting.
---@return number
function core.getGameDifficulty() end

---Return l10n formatting function for the given context.
---Localisation files (containing the message names and translations) should be stored in
---VFS as files of the form `l10n/<ContextName>/<Locale>.yaml`.
---See [Localisation](../modding/localisation.html) for details of the localisation file structure.
---When calling the l10n formatting function, if no localisation can be found for any of the requested locales then
---the message key will be returned instead (and formatted, if possible).
---This makes it possible to use the source strings as message identifiers.
---If you do not use the source string as a message identifier you should instead make certain to include
---a fallback locale with a complete set of messages.
---# DataFiles/l10n/MyMod/en.yaml
---good_morning: 'Good morning.'
---you_have_arrows: |-
---# DataFiles/l10n/MyMod/de.yaml
---good_morning: "Guten Morgen."
---you_have_arrows: |-
---"Hello {name}!": "Hallo {name}!"
----- Usage in Lua
---local myMsg = core.l10n('MyMod', 'en')
---print( myMsg('good_morning') )
---print( myMsg('you_have_arrows', {count=5}) )
---print( myMsg('Hello {name}!', {name='World'}) )
---@param context string l10n context; recommended to use the name of the mod. This must match the <ContextName> directory in the VFS which stores the localisation files.
---@param fallbackLocale string The source locale containing the default messages If omitted defaults to "en".
---@return fun(...): any
function core.l10n(context, fallbackLocale) end

---@type openmw.core.ContentFiles
core.contentFiles = nil

---Return the index of a specific content file in the load order (or `nil` if there is no such content file).
---@param contentFile string
---@return number
function ContentFiles.indexOf(contentFile) end

---Check if the content file with given name present in the load order.
---@param contentFile string
---@return boolean
function ContentFiles.has(contentFile) end

---Construct FormId string from content file name and the index in the file.
---In ESM3 games (e.g. Morrowind) FormIds are used to reference game objects.
---In ESM4 games (e.g. Skyrim) FormIds are used both for game objects and as record ids.
---obj.owner.factionId = 'blades'
----- In ESM4 (e.g. Skyrim) ids should be constructed using `core.getFormId`:
---obj.owner.factionId = core.getFormId('Skyrim.esm', 0x72834)
---local obj = nearby.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))
---local obj = world.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))
---@param contentFile string
---@param index number
---@return string
function core.getFormId(contentFile, index) end

---Returns true if the cell has given tag.
---@param tag string One of "QuasiExterior", "NoSleep".
---@return boolean
function Cell:hasTag(tag) end

---Returns true either if the cell contains the object or if the cell is an exterior and the object is also in an exterior.
---if obj1.cell:isInSameSpace(obj2) then
---else
---end
---@param object openmw.Object
---@return boolean
function Cell:isInSameSpace(object) end

---Get all objects of given type from the cell.
---local type = require('openmw.types')
---local all = cell:getAll()
---local weapons = cell:getAll(types.Weapon)
---@param type? any (optional) object type (see openmw.types.types)
---@return openmw.ObjectList<openmw.GObject>
function GCell:getAll(type) end

---Get all points in this path grid.
---@return openmw.core.PathGridPoint[] A list of PathGridPoints.
function PathGrid:getPoints() end

---Possible EnchantmentType values
---@type openmw.core.EnchantmentTypeValues
Magic.ENCHANTMENT_TYPE = nil

---The number of items with the given recordId.
---@param recordId string
---@return number
function Inventory:countOf(recordId) end

---Get all items of the given type from the inventory.
---local types = require('openmw.types')
---local self = require('openmw.self')
---local playerInventory = types.Actor.inventory(self.object)
---local all = playerInventory:getAll()
---local weapons = playerInventory:getAll(types.Weapon)
---@param type? any (optional) items type (see openmw.types.types)
---@return openmw.ObjectList<openmw.Object>
function Inventory:getAll(type) end

---Get first item with the given recordId from the inventory. Returns nil if not found.
---@param recordId string
---@return openmw.Object|nil
function Inventory:find(recordId) end

---Will resolve the inventory, filling it with levelled items if applicable, making its contents permanent. Must be used in a global script.
function Inventory:resolve() end

---Checks if the inventory has a resolved item list.
---@return boolean
function Inventory:isResolved() end

---Get all items with the given recordId from the inventory.
---@param recordId string
---@return openmw.ObjectList<openmw.Object>
function Inventory:findAll(recordId) end

---@type openmw.core.Land
core.land = nil

---Get the terrain height at a given location.
---@param position openmw.util.Vector3
---@param cellOrId any cell or cell id in their exterior world space to query
---@return number
function Land.getHeightAt(position, cellOrId) end

---Get the terrain texture at a given location. As textures are blended and
---multiple textures can be at one specific position the texture whose center is
---closest to the position will be returned.
---@param position openmw.util.Vector3
---@param cellOrId any cell or cell id in their exterior world space to query
---@return nil|string Texture path or nil if one isn't defined
---@return nil|string Plugin name or nil if failed to retrieve the texture
function Land.getTextureAt(position, cellOrId) end

---@type openmw.core.Magic
core.magic = nil

---Possible SpellRange values
---@type openmw.core.SpellRangeValues
Magic.RANGE = nil

---Possible MagicEffectId values
---@type openmw.core.MagicEffectId
Magic.EFFECT_TYPE = nil

---Possible SpellType values
---@type openmw.core.SpellTypeValues
Magic.SPELL_TYPE = nil

---@type openmw.core.Spells
Magic.spells = nil

---Creates a Spell without adding it to the world database.
---Use openmw_world.(world).createRecord to add the record to the world.
---@param spell openmw.core.Spell A Lua table with the fields of a Spell, with an optional field `template` that accepts a Spell as a base.
---@return openmw.core.Spell A strongly typed Spell record.
function Spells.createRecordDraft(spell) end

---List of all Spells.
---Implements [iterables#List](iterables.html#List) of #Spell.
---for _, spell in pairs(core.magic.spells.records) do
---end
---@type openmw.core.Spell[]
Spells.records = nil

---@type openmw.core.Effects
Magic.effects = nil

---Map from MagicEffectId to MagicEffect
---for _, effect in pairs(core.magic.effects.records) do
---end
---local mgef = core.magic.effects.records[core.magic.EFFECT_TYPE.Reflect]
---print('Reflect Icon: '..tostring(mgef.icon))
---@type table<string, openmw.core.MagicEffect>
Effects.records = nil

---@type openmw.core.Enchantments
Magic.enchantments = nil

---Creates an Enchantment without adding it to the world database.
---Use openmw_world.(world).createRecord to add the record to the world.
---@param enchantment openmw.core.Enchantment A Lua table with the fields of an Enchantment, with an optional field `template` that accepts an Enchantment as a base.
---@return openmw.core.Enchantment A strongly typed Enchantment record.
function Enchantments.createRecordDraft(enchantment) end

---A read-only list of all Enchantment records in the world database, may be indexed by recordId.
---Implements [iterables#List](iterables.html#List) and [iterables#Map](iterables.html#map-iterable) of #Enchantment.
---for _, ench in pairs(core.magic.enchantments.records) do
---end
---@type openmw.core.Enchantment[]
Enchantments.records = nil

---@type openmw.core.Sound
core.sound = nil

---Checks if sound system is enabled (any functions to play sounds are no-ops when it is disabled).
---It can not be enabled or disabled during runtime.
---@return boolean
function Sound.isEnabled() end

---Play a 3D sound, attached to object
---In local scripts can be used only on self.
---};
---core.sound.playSound3d("shock bolt", object, params)
---@param soundId string ID of Sound record to play
---@param object openmw.GObject|openmw.SelfObject Object to which we attach the sound
---@param options? table An optional table with additional optional arguments. Can contain: * `timeOffset` - a floating point number >= 0, to some time (in second) from beginning of sound file (default: 0); * `volume` - a floating point number >= 0, to set a sound volume (default: 1); * `pitch` - a floating point number >= 0, to set a sound pitch (default: 1); * `loop` - a boolean, to set if sound should be repeated when it ends (default: false);
function Sound.playSound3d(soundId, object, options) end

---Play a 3D sound file, attached to object
---In local scripts can be used only on self.
---};
---core.sound.playSoundFile3d("Sound\\test.mp3", object, params)
---@param fileName string Path to sound file in VFS
---@param object openmw.GObject|openmw.SelfObject Object to which we attach the sound
---@param options? table An optional table with additional optional arguments. Can contain: * `timeOffset` - a floating point number >= 0, to some time (in second) from beginning of sound file (default: 0); * `volume` - a floating point number >= 0, to set a sound volume (default: 1); * `pitch` - a floating point number >= 0, to set a sound pitch (default: 1); * `loop` - a boolean, to set if sound should be repeated when it ends (default: false);
function Sound.playSoundFile3d(fileName, object, options) end

---Stop a 3D sound, attached to object
---In local scripts can be used only on self.
---@param soundId string ID of Sound record to stop
---@param object openmw.GObject|openmw.SelfObject Object on which we want to stop sound
function Sound.stopSound3d(soundId, object) end

---Stop a 3D sound file, attached to object
---In local scripts can be used only on self.
---@param fileName string Path to sound file in VFS
---@param object openmw.GObject|openmw.SelfObject Object on which we want to stop sound
function Sound.stopSoundFile3d(fileName, object) end

---Check if a sound is playing on the given object
---@param soundId string ID of Sound record to check
---@param object openmw.Object Object on which we want to check sound
---@return boolean
function Sound.isSoundPlaying(soundId, object) end

---Check if a sound file is playing on the given object
---@param fileName string Path to sound file in VFS
---@param object openmw.Object Object on which we want to check sound
---@return boolean
function Sound.isSoundFilePlaying(fileName, object) end

---Play an animated voiceover.
---In local scripts can be used only on self.
---core.sound.say("Sound\\Vo\\Misc\\voice.mp3", object, "Subtitle text")
---core.sound.say("Sound\\Vo\\Misc\\voice.mp3", object)
---@param fileName string Path to sound file in VFS
---@param object openmw.GObject|openmw.SelfObject Object on which we want to play an animated voiceover
---@param text? string Subtitle text (optional)
function Sound.say(fileName, object, text) end

---Stop an animated voiceover
---In local scripts can be used only on self.
---@param fileName string Path to sound file in VFS
---@param object openmw.GObject|openmw.SelfObject Object on which we want to stop an animated voiceover
function Sound.stopSay(fileName, object) end

---Check if an animated voiceover is playing
---@param object openmw.Object Object on which we want to check an animated voiceover
---@return boolean
function Sound.isSayActive(object) end

---List of all SoundRecords.
---Implements [iterables#List](iterables.html#List) of #SoundRecord.
---for _, sound in pairs(core.sound.records) do
---end
---@type openmw.core.SoundRecord[]
Sound.records = nil

---@type openmw.core.Stats
core.stats = nil

---@type openmw.core.Attribute
Stats.Attribute = nil

---Returns a read-only AttributeRecord
---@param recordId string
---@return openmw.core.AttributeRecord
function Attribute.record(recordId) end

---@type openmw.core.Skill
Stats.Skill = nil

---Returns a read-only SkillRecord
---@param recordId string
---@return openmw.core.SkillRecord
function Skill.record(recordId) end

---@type openmw.core.Dialogue
core.dialogue = nil

---print(core.dialogue.journal.records["ms_fargothring"].name) -- MS_FargothRing
---for _, journalRecord in pairs(core.dialogue.journal.records) do
---end
---for _, quest in pairs(types.Player.quests(self)) do
---end
---@type any
Dialogue.journal = nil

---for _, topicRecord in pairs(core.dialogue.topic.records) do
---end
---for idx, topicInfo in pairs(core.dialogue.topic.records["vivec"].infos) do
---end
---@type any
Dialogue.topic = nil

---for _, voiceRecord in pairs(core.dialogue.voice.records) do
---end
---for idx, voiceInfo in pairs(core.dialogue.voice.records["flee"].infos) do
---end
---@type any
Dialogue.voice = nil

---for _, greetingRecord in pairs(core.dialogue.greeting.records) do
---end
---for idx, greetingInfo in pairs(core.dialogue.greeting.records["greeting 0"].infos) do
---end
---@type any
Dialogue.greeting = nil

---for _, persuasionRecord in pairs(core.dialogue.persuasion.records) do
---end
---for idx, persuasionInfo in pairs(core.dialogue.persuasion.records["admire success"].infos) do
---end
---@type any
Dialogue.persuasion = nil

---A read-only list of all DialogueRecords in the world database, may be indexed by recordId, which doesn't have to be lowercase.
---Implements [iterables#List](iterables.html#list-iterable) of #DialogueRecord.
---@type openmw.core.DialogueRecord[]
DialogueRecords.records = nil

---Quest stage (same as in openmw_types.PLAYERQuest.stage) this info entry is associated with.
---Non-nil only for journal records.
---@type number
DialogueRecordInfo.questStage = nil

---True if this info entry has the "Finished" flag checked.
---Non-nil only for journal records.
---@type boolean
DialogueRecordInfo.isQuestFinished = nil

---True if this info entry has the "Restart" flag checked.
---Non-nil only for journal records.
---@type boolean
DialogueRecordInfo.isQuestRestart = nil

---True if this info entry has the "Quest Name" flag checked.
---Non-nil only for journal records.
---If true, then the DialogueRecord, to which this info entry belongs, should have this info entry's DialogueRecordInfo.text value available in its DialogueRecord.questName.
---@type boolean
DialogueRecordInfo.isQuestName = nil

---Faction of which the speaker must be a member for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---Can return an empty string - this means that the actor must not be a member of any faction for this filtering to apply.
---@type string
DialogueRecordInfo.filterActorFaction = nil

---Speaker ID allowing for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---@type string
DialogueRecordInfo.filterActorId = nil

---Speaker race allowing for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---@type string
DialogueRecordInfo.filterActorRace = nil

---Speaker class allowing for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---@type string
DialogueRecordInfo.filterActorClass = nil

---Minimum speaker's rank in their faction allowing for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---Rank index starts from 1, matching the value in openmw_types.NPC.getFactionRank
---@type number
DialogueRecordInfo.filterActorFactionRank = nil

---Cell name prefix of location where the player must be for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---"Prefix" means that the cell's name starting with this value shall pass the filtering. For example: `filterPlayerCell` being "Seyda Neen" does apply to the cell "Seyda Neen, Fargoth's House".
---@type string
DialogueRecordInfo.filterPlayerCell = nil

---Minimum speaker disposition allowing for this info entry to appear.
---Always nil for journal records. Otherwise is a nonnegative number, with the zero value representing no conditions, i.e. no filtering applied using these criteria.
---@type number
DialogueRecordInfo.filterActorDisposition = nil

---Speaker gender allowing for this info entry to appear: "male" or "female".
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---@type string
DialogueRecordInfo.filterActorGender = nil

---Faction of which the player must be a member for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---@type string
DialogueRecordInfo.filterPlayerFaction = nil

---Minimum player's rank in their faction allowing for this info entry to appear.
---Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
---Rank index starts from 1, matching the value in openmw_types.NPC.getFactionRank
---@type number
DialogueRecordInfo.filterPlayerFactionRank = nil

---Sound file path for this info entry.
---Always nil for journal records or if there is no sound set.
---@type string
DialogueRecordInfo.sound = nil

---MWScript (full script text) executed when this info is chosen.
---Always nil for journal records or if there is no value set.
---@type string
DialogueRecordInfo.resultScript = nil

---A read-only list of DialogueInfoConditions.
---Always nil for journal records.
---@type openmw.core.DialogueInfoCondition[]
DialogueRecordInfo.conditions = nil

---Possible DialogueConditionOperator values
---@type openmw.core.DialogueConditionOperatorValues
Dialogue.CONDITION_OPERATOR = nil

---Possible DialogueConditionType values
---@type openmw.core.DialogueConditionTypeValues
Dialogue.CONDITION_TYPE = nil

---@type openmw.core.Regions
core.regions = nil

---A read-only list of all RegionRecords in the world database.
---@type openmw.core.RegionRecord[]
Regions.records = nil

---@type openmw.core.Factions
core.factions = nil

---A read-only list of all FactionRecords in the world database.
---@type openmw.core.FactionRecord[]
Factions.records = nil

---@type openmw.core.MWScripts
core.mwscripts = nil

---A read-only list of all MWScriptRecords in the world database.
---@type openmw.core.MWScriptRecord[]
MWScripts.records = nil

---@type openmw.core.Weather
core.weather = nil

---List of all WeatherRecords.
---Implements [iterables#List](iterables.html#List) of #WeatherRecord.
---for _, weather in pairs(core.weather.records) do
---end
---@type openmw.core.WeatherRecord[]
Weather.records = nil

---@type openmw.core.MOON_PHASE
Weather.MOON_PHASE = nil

---Get all moons in the current sky.
---@param cell openmw.core.Cell The cell to get moons for.
---@return openmw.core.Moon[]|nil
function Weather.getCurrentMoons(cell) end

---Get the current weather
---@param cell openmw.core.Cell The cell to get the current weather for
---@return openmw.core.WeatherRecord|nil Can be nil if the cell is inactive or has no weather
function Weather.getCurrent(cell) end

---Get the next weather if any
---@param cell openmw.core.Cell The cell to get the next weather for
---@return openmw.core.WeatherRecord|nil Can be nil
function Weather.getNext(cell) end

---Get current weather transition value
---@param cell openmw.core.Cell The cell to get the transition value for
---@return number|nil Can be nil if the cell is inactive or has no weather
function Weather.getTransition(cell) end

---Change the weather
---@param regionId string
---@param weather openmw.core.WeatherRecord The weather to change to
function Weather.changeWeather(regionId, weather) end

---Get the current direction of the light of the sun.
---@param cell openmw.core.Cell The cell to get the sun direction for
---@return openmw.util.Vector4|nil Can be nil if the cell is inactive
function Weather.getCurrentSunLightDirection(cell) end

---Get the current sun visibility taking weather transition into account.
---@param cell openmw.core.Cell The cell to get the sun visibility for
---@return number|nil Can be nil if the cell is inactive or has no weather
function Weather.getCurrentSunVisibility(cell) end

---Get the current sun percentage taking weather transition into account.
---@param cell openmw.core.Cell The cell to get the sun percentage for
---@return number|nil Can be nil if the cell is inactive or has no weather
function Weather.getCurrentSunPercentage(cell) end

---Get the current wind speed taking weather transition into account.
---@param cell openmw.core.Cell The cell to get the wind speed for
---@return number|nil Can be nil if the cell is inactive or has no weather
function Weather.getCurrentWindSpeed(cell) end

---Get the current storm direction taking weather transition into account.
---@param cell openmw.core.Cell The cell to get the storm direction for
---@return openmw.util.Vector3|nil Can be nil if the cell is inactive or has no weather
function Weather.getCurrentStormDirection(cell) end

return core
