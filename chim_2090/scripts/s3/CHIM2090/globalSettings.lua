local I = require("openmw.interfaces")

local modInfo = require("scripts.s3.CHIM2090.modInfo")

-- Global settings description(s)
local combatMessageDescription = "Toggle messageboxes for fumbles and crits"
local useRangedBonusDesc = "Apply the hit chance and strength bonuses to ranged weapons as well as melee weapons."
-- Hit Chance settings description(s)
local hitChanceEnableDescription = "Enable the hit chance module. This module increases hit chance according to how charged an attack is, with fully charged attacks being guaranteed to hit."
local maxAttackBonusDesc = "Max magnitude of fortify attack bonus on the player"
local agilityHitChancePctDesc = "Percentage of agility that is added to hit chance, vanilla is 20%. Related damage scaling is capped by the Max Strength Multiplier setting."
local luckHitChancePctDesc = "Percentage of luck that is added to hit chance, vanilla is 10%. Related damage scaling is capped by the Max Strength Multiplier setting."
-- Fatigue settings description(s)
local useVanillaFatigueDesc = "Use the original fatigue regeneration formula instead of CHIM 2090's internal one. This still uses below regen settings, but omits advanced functionality related to fatigue."
local fatiguePerSecondDesc = "Fatigue restored per second when using either formula. Replaces the vanilla GMST (2.5) \"fFatigueReturnBase\""
local fatigueReturnMultDesc = "Percentage of endurance regained as fatigue, per second, with either formula. Replaces the vanilla GMST (0.02) \"fFatigueReturnMult\""
local fatigueEndMultDesc = "Percentage of endurance regained as fatigue, per second, with either formula, while sleeping. Replaces the vanilla GMST (0.04) \"fEndFatigueMult\""
-- Sleep settings description(s)
local pillowEnableDesc = "Enable the pillow modifier. This adds a bonus to attributes restored while sleeping or waiting."
local pillowMultDesc = "Restoration bonus from carrying a pillow while sleeping."
local saveOnRestDesc = 'Save the game when resting. This will save the game when the player rests, but not when they wait.'
local noSleepOnGroundDesc = "Prevent sleeping on the ground. This will enforce only sleeping in some kind of bed (including bedrolls)."
local restMagicMultDesc = "Multiplier for magicka restored while resting. Replaces the vanilla GMST (0.15) \"fRestMagicMult\"."
local sleepFatigueMultDesc = "Multiplier for fatigue restored while sleeping. Does not replace a vanilla GMST."
local groundSleepMultDesc = "Percentage of fatigue restored while sleeping on the ground. Does not replace a vanilla GMST."
local bedrollSleepMultDesc = "Multiplier for fatigue restored while sleeping on the ground. Does not replace a vanilla GMST."
local bedSleepMultDesc = "Multiplier for fatigue restored while sleeping on the ground. Does not replace a vanilla GMST, only applies indoors."
local ownedSleepMultDesc = "Multiplier for fatigue restored while sleeping in an owned bed. Does not replace a vanilla GMST, only applies indoors."
local outdoorSleepMultDesc = "Multiplier for fatigue restored while sleeping outdoors, in a bed. Does not replace a vanilla GMST."
local outdoorWaitMultDesc = "Multiplier for fatigue restored while sleeping on the ground or waiting, while outdoors. Does not replace a vanilla GMST."
local indoorWaitMultDesc = "Multiplier for fatigue restored while waiting indoors. Does not replace a vanilla GMST."
local maxFatigueStrMultDesc = "Percentage of strength factored into max fatigue. Vanilla is 100."
local maxFatigueWilMultDesc = "Percentage of willpower factored into max fatigue. Vanilla is 100."
local maxFatigueAgiMultDesc = "Percentage of agility factored into max fatigue. Vanilla is 100."
local maxFatigueEndMultDesc = "Percentage of endurance factored into max fatigue. Vanilla is 100."
-- Critical hit settings description(s)
local critFumbleEnableDesc = "Enable the critical hit and fumble module. This module adds a chance to deal extra damage on a critical hit, and less on a fumble. Requires the strength module to work."
local critChancePercentDesc = "Base chance of a critical hit"
local critLuckPercentDesc = "Influence of luck on critical hit chance and fumble as a percentage"
local critMultDesc = "Critical hit damage multiplier. Only applies in melee combat."
local fumbleChancePercentDesc = "Base chance of a fumble. Increse this to fumble more with lower skill."
local fumbleChanceScaleDesc = "Scale of fumble chance with skill. Increase this to fumble more regardless of skill."
local fumbleDamagePercentDesc = "Percentage of damage dealt to the target on a fumble"
-- Strength settings description(s)
local strWghtEnableDesc = "Enable the strength and weight module. This module scales damage based on the player's hit chance as calculated by vanilla Morrowind."
local maxStrMultDesc = "Limit for the amount of damage done, based on chance the vanilla hit chance formula. 1.5 means 150% maximum damage from agility, skill, and luck."

local function setting(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name,
	page = modInfo.name,
	order = 0,
	l10n = modInfo.l10nName,
	name = "General",
	permanentStorage = false,
	settings = {
      setting("DebugEnable", "checkbox", {}, "Show Debug Messages", '', false),
      setting("MessageEnable", "checkbox", {}, "Show Combat Messages", combatMessageDescription, false),
	}
}

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name .. "Dynamic",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.l10nName,
	name = "Health, Fatigue, Magicka",
	permanentStorage = false,
	settings = {
      setting("UseVanillaFatigueFormula", "checkbox", {}, "Use Vanilla Fatigue Formula", useVanillaFatigueDesc, false),
      setting('FatiguePerSecond', 'number', {integer = true, min = -500, max = 500 },
              "Fatigue Per Second", fatiguePerSecondDesc, 3),
      setting('FatigueReturnMult', 'number', {integer = false, min = 0.001, max = 10.0 },
              "Fatigue Endurance Multiplier", fatigueReturnMultDesc, 0.02),
      setting('FatigueEndMult', 'number', {integer = false, min = 0.001, max = 10.0 },
              "Resting Endurance Multiplier", fatigueEndMultDesc, 0.04),
      setting('MaxFatigueStrMult', 'number', {integer = true, min = 0, max = 1000 },
              "Fatigue Strength Multiplier", maxFatigueStrMultDesc, 125),
      setting('MaxFatigueWilMult', 'number', {integer = true, min = 0, max = 1000 },
              "Fatigue Willpower Multiplier", maxFatigueWilMultDesc, 50),
      setting('MaxFatigueAgiMult', 'number', {integer = true, min = 0, max = 1000 },
              "Fatigue Agility Multiplier", maxFatigueAgiMultDesc, 25),
      setting('MaxFatigueEndMult', 'number', {integer = true, min = 0, max = 1000 },
              "Fatigue Endurance Multiplier", maxFatigueEndMultDesc, 75),
	}
}

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name .. 'Sleep',
	page = modInfo.name,
	order = 2,
	l10n = modInfo.l10nName,
	name = "Sleep Management",
	permanentStorage = false,
	settings = {
      setting("PillowEnable", "checkbox", {}, "Pillow Restoration Multiplier", pillowEnableDesc, true),
      setting('PillowMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Pillow Multiplier", pillowMultDesc, 0.10),
      setting('SaveOnRest', 'checkbox', {}, "Save When Resting", saveOnRestDesc, false),
      setting('NoSleepOnGround', 'checkbox', {}, "No Sleep on Ground", noSleepOnGroundDesc, false),
      setting('SleepFatigueMult', 'number', {integer = true, min = -1000, max = 1000 },
              "Sleep Restoration Multiplier", sleepFatigueMultDesc, 10),
      setting('RestMagicMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Resting Magicka Multiplier", restMagicMultDesc, 0.15),
      setting('RestHealthMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Resting Health Multiplier", restMagicMultDesc, 0.15),
      setting('GroundSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Ground Resting Multiplier", groundSleepMultDesc, 0.50),
      setting('BedrollSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Bedroll Resting Multiplier", bedrollSleepMultDesc, 0.75),
      setting('BedSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Bed Resting Multiplier", bedSleepMultDesc, 1.25),
      setting('OwnedSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Owned Bed Resting Multiplier", ownedSleepMultDesc, 1.40),
      setting('OutdoorSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Outdoor Bed Resting Multiplier", outdoorSleepMultDesc, 0.50),
      setting('OutdoorWaitMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Outdoor Waiting Multiplier", outdoorWaitMultDesc, 0.15),
      setting('IndoorWaitMult', 'number', {integer = false, min = -10.0, max = 10.0 },
              "Indoor Waiting Multiplier", indoorWaitMultDesc, 0.50),
	}
}

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name .. "HitChance",
	page = modInfo.name,
	order = 3,
	l10n = modInfo.l10nName,
	name = "Attack Bonus",
	permanentStorage = false,
	settings = {
      setting("EnableHitChance", "checkbox", {}, "Enable Hit Chance Module", hitChanceEnableDescription, true),
      setting("UseRangedBonus", "checkbox", {}, "Apply to ranged weapons", useRangedBonusDesc, true),
      setting('PlayerMaxAttackBonus', 'number', {integer = true, min = 0, max = 500 },
              "Player Maximum Attack Bonus", maxAttackBonusDesc, 100),
      setting('AgilityHitChancePct', 'number', {integer = false, min = 0.001, max = 1.0 },
              "Agility Hit Chance Influence", agilityHitChancePctDesc, 0.20),
      setting('LuckHitChancePct', 'number', {integer = false, min = 0.001, max = 1.0 },
              "Luck Hit Chance Influence", luckHitChancePctDesc, 0.10),
	}
}

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name .. "Damage",
	page = modInfo.name,
	order = 4,
	l10n = modInfo.l10nName,
	name = "Damage, Crit, and Fumble",
	permanentStorage = false,
	settings = {
      setting("EnableStrWght", "checkbox", {}, "Enable Strength and Weight Module", strWghtEnableDesc, true),
      setting('MaxStrengthMultiplier', 'number', {integer = false, min = 0.01, max = 10. },
              "Max Strength Multiplier", maxStrMultDesc, 1.5),
      setting("EnableCritFumble", "checkbox", {}, "Enable Crit and Fumble Module", critFumbleEnableDesc, true),
      setting('CritChancePercent', 'number', {integer = true, min = 0, max = 100 },
              "Base Critical Hit Chance", critChancePercentDesc, 4),
      setting('CritLuckPercent', 'number', {integer = true, min = 0, max = 100 },
              "Critical Luck Influence", critLuckPercentDesc, 1),
      setting('CritDamageMultiplier', 'number', {integer = false, min = 1.0, max = 10.0 },
              "Melee Critical Damage Multiplier", critMultDesc, 4.0),
      setting('FumbleBaseChance', 'number', {integer = true, min = 0, max = 100 },
              "Base Fumble Chance", fumbleChancePercentDesc, 3),
      setting('FumbleChanceScale', 'number', {integer = true, min = 0, max = 100 },
              "Fumble Chance Scale", fumbleChanceScaleDesc, 10),
      setting('FumbleDamagePercent', 'number', {integer = true, min = 0, max = 100 },
              "Fumble Damage Percentage", fumbleDamagePercentDesc, 25),
	}
}
