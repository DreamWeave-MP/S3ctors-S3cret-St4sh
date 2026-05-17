---@meta

---@class MagicSchoolData
---@field name string Human-readable name
---@field areaSound string VFS path to the area sound
---@field boltSound string VFS path to the bolt sound
---@field castSound string VFS path to the cast sound
---@field failureSound string VFS path to the failure sound
---@field hitSound string VFS path to the hit sound

---@alias EnchantmentType
---| "CastOnce" # Enchantment can be cast once, destroying the enchanted item.
---| "CastOnStrike" # Enchantment is cast on strike, if there is enough charge.
---| "CastOnUse" # Enchantment is cast when used, if there is enough charge.
---| "ConstantEffect" # Enchantment is always active when equipped.

---@enum MagicEffectId
local MAGIC_EFFECT = {
    WaterBreathing = "waterbreathing",
    SwiftSwim = "swiftswim",
    WaterWalking = "waterwalking",
    Shield = "shield",
    FireShield = "fireshield",
    LightningShield = "lightningshield",
    FrostShield = "frostshield",
    Burden = "burden",
    Feather = "feather",
    Jump = "jump",
    Levitate = "levitate",
    SlowFall = "slowfall",
    Lock = "lock",
    Open = "open",
    FireDamage = "firedamage",
    ShockDamage = "shockdamage",
    FrostDamage = "frostdamage",
    DrainAttribute = "drainattribute",
    DrainHealth = "drainhealth",
    DrainMagicka = "drainmagicka",
    DrainFatigue = "drainfatigue",
    DrainSkill = "drainskill",
    DamageAttribute = "damageattribute",
    DamageHealth = "damagehealth",
    DamageMagicka = "damagemagicka",
    DamageFatigue = "damagefatigue",
    DamageSkill = "damageskill",
    Poison = "poison",
    WeaknessToFire = "weaknesstofire",
    WeaknessToFrost = "weaknesstofrost",
    WeaknessToShock = "weaknesstoshock",
    WeaknessToMagicka = "weaknesstomagicka",
    WeaknessToCommonDisease = "weaknesstocommondisease",
    WeaknessToBlightDisease = "weaknesstoblightdisease",
    WeaknessToCorprusDisease = "weaknesstocorprusdisease",
    WeaknessToPoison = "weaknesstopoison",
    WeaknessToNormalWeapons = "weaknesstonormalweapons",
    DisintegrateWeapon = "disintegrateweapon",
    DisintegrateArmor = "disintegratearmor",
    Invisibility = "invisibility",
    Chameleon = "chameleon",
    Light = "light",
    Sanctuary = "sanctuary",
    NightEye = "nighteye",
    Charm = "charm",
    Paralyze = "paralyze",
    Silence = "silence",
    Blind = "blind",
    Sound = "sound",
    CalmHumanoid = "calmhumanoid",
    CalmCreature = "calmcreature",
    FrenzyHumanoid = "frenzyhumanoid",
    FrenzyCreature = "frenzycreature",
    DemoralizeHumanoid = "demoralizehumanoid",
    DemoralizeCreature = "demoralizecreature",
    RallyHumanoid = "rallyhumanoid",
    RallyCreature = "rallycreature",
    Dispel = "dispel",
    Soultrap = "soultrap",
    Telekinesis = "telekinesis",
    Mark = "mark",
    Recall = "recall",
    DivineIntervention = "divineintervention",
    AlmsiviIntervention = "almsiviintervention",
    DetectAnimal = "detectanimal",
    DetectEnchantment = "detectenchantment",
    DetectKey = "detectkey",
    SpellAbsorption = "spellabsorption",
    Reflect = "reflect",
    CureCommonDisease = "curecommondisease",
    CureBlightDisease = "cureblightdisease",
    CureCorprusDisease = "curecorprusdisease",
    CurePoison = "curepoison",
    CureParalyzation = "cureparalyzation",
    RestoreAttribute = "restoreattribute",
    RestoreHealth = "restorehealth",
    RestoreMagicka = "restoremagicka",
    RestoreFatigue = "restorefatigue",
    RestoreSkill = "restoreskill",
    FortifyAttribute = "fortifyattribute",
    FortifyHealth = "fortifyhealth",
    FortifyMagicka = "fortifymagicka",
    FortifyFatigue = "fortifyfatigue",
    FortifySkill = "fortifyskill",
    FortifyMaximumMagicka = "fortifymaximummagicka",
    AbsorbAttribute = "absorbattribute",
    AbsorbHealth = "absorbhealth",
    AbsorbMagicka = "absorbmagicka",
    AbsorbFatigue = "absorbfatigue",
    AbsorbSkill = "absorbskill",
    ResistFire = "resistfire",
    ResistFrost = "resistfrost",
    ResistShock = "resistshock",
    ResistMagicka = "resistmagicka",
    ResistCommonDisease = "resistcommondisease",
    ResistBlightDisease = "resistblightdisease",
    ResistCorprusDisease = "resistcorprusdisease",
    ResistPoison = "resistpoison",
    ResistNormalWeapons = "resistnormalweapons",
    ResistParalysis = "resistparalysis",
    RemoveCurse = "removecurse",
    TurnUndead = "turnundead",
    SummonScamp = "summonscamp",
    SummonClannfear = "summonclannfear",
    SummonDaedroth = "summondaedroth",
    SummonDremora = "summondremora",
    SummonAncestralGhost = "summonancestralghost",
    SummonSkeletalMinion = "summonskeletalminion",
    SummonBonewalker = "summonbonewalker",
    SummonGreaterBonewalker = "summongreaterbonewalker",
    SummonBonelord = "summonbonelord",
    SummonWingedTwilight = "summonwingedtwilight",
    SummonHunger = "summonhunger",
    SummonGoldenSaint = "summongoldensaint",
    SummonFlameAtronach = "summonflameatronach",
    SummonFrostAtronach = "summonfrostatronach",
    SummonStormAtronach = "summonstormatronach",
    FortifyAttack = "fortifyattack",
    CommandCreature = "commandcreature",
    CommandHumanoid = "commandhumanoid",
    BoundDagger = "bounddagger",
    BoundLongsword = "boundlongsword",
    BoundMace = "boundmace",
    BoundBattleAxe = "boundbattleaxe",
    BoundSpear = "boundspear",
    BoundLongbow = "boundlongbow",
    ExtraSpell = "extraspell",
    BoundCuirass = "boundcuirass",
    BoundHelm = "boundhelm",
    BoundBoots = "boundboots",
    BoundShield = "boundshield",
    BoundGloves = "boundgloves",
    Corprus = "corprus",
    Vampirism = "vampirism",
    SummonCenturionSphere = "summoncenturionsphere",
    SunDamage = "sundamage",
    StuntedMagicka = "stuntedmagicka",
    SummonFabricant = "summonfabricant",
    SummonWolf = "summonwolf",
    SummonBear = "summonbear",
    SummonBonewolf = "summonbonewolf",
    SummonCreature04 = "summoncreature04",
    SummonCreature05 = "summoncreature05",
}

---@class core.magic.RANGE
---@field Self integer # Applied on self
---@field Touch integer # On touch
---@field Target integer # Ranged spell

---@class core.magic.SPELL_TYPE
---@field Spell integer # Normal spell, must be cast and costs mana
---@field Ability integer # Innate ability, always in effect
---@field Blight integer # Blight disease
---@field Disease integer # Common disease
---@field Curse integer # Curse
---@field Power integer # Power, can be used once a day

---@class MagicEffect
---@field id string Effect ID
---@field icon string Effect Icon Path
---@field name string Localized name of the effect
---@field school string Skill ID that is this effect's school
---@field baseCost number
---@field color util.color
---@field harmful boolean If set, the effect is considered harmful and should elicit a hostile reaction from affected NPCs.
---@field continuousVfx boolean Whether the magic effect's vfx should loop or not
---@field hasDuration boolean If set, the magic effect has a duration. As an example, divine intervention has no duration while fire damage does.
---@field hasMagnitude boolean If set, the magic effect depends on a magnitude. As an example, cure common disease has no magnitude while chameleon does.
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

---@class MagicEffectWithParams
---@field effect MagicEffect
---@field id string ID of the associated MagicEffect
---@field affectedSkill string? Optional skill ID
---@field affectedAttribute string? Optional attribute ID
---@field range number
---@field area number
---@field magnitudeMin number
---@field magnitudeMax number
---@field duration number
---@field index number Index of this effect within the original list of MagicEffectWithParams of the spell/enchantment/potion this effect came from.

---@class Enchantment
---@field id string Enchantment id
---@field type EnchantmentType
---@field autocalcFlag boolean If set, the casting cost should be computed based on the effect list rather than read from the cost field
---@field cost number
---@field charge number Charge capacity. Should not be confused with current charge.
---@field effects MagicEffectWithParams[] The effects of the enchantment

---@class Spell
---@field id string Spell id
---@field name string Spell name
---@field type core.magic.SPELL_TYPE
---@field cost number
---@field effects MagicEffectWithParams[] The effects of the spell
---@field alwaysSucceedFlag boolean If set, the spell should ignore skill checks and always succeed.
---@field starterSpellFlag boolean If set, the spell can be selected as a player's starting spell.
---@field autocalcFlag boolean If set, the casting cost should be computed based on the effect list rather than read from the cost field
