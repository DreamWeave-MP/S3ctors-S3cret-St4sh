local async = require 'openmw.async'
local storage = require 'openmw.storage'

local I = require 'openmw.interfaces'

local modInfo = require 'scripts.s3.CHIM2090.modInfo'

local agilityHitChancePctDesc =
'Percentage of agility that is added to hit chance, vanilla is 20%. Related damage scaling is capped by the Max Strength Multiplier setting.'
local luckHitChancePctDesc =
'Percentage of luck that is added to hit chance, vanilla is 10%. Related damage scaling is capped by the Max Strength Multiplier setting.'
local useVanillaFatigueDesc =
'Use the original fatigue regeneration formula instead of CHIM 2090\'s internal one. This still uses below regen settings, but omits advanced functionality related to fatigue.'
local fatiguePerSecondDesc =
'Fatigue restored per second when using either formula. Replaces the vanilla GMST (2.5) \'fFatigueReturnBase\''
local fatigueReturnMultDesc =
'Percentage of endurance regained as fatigue, per second, with either formula. Replaces the vanilla GMST (0.02) \'fFatigueReturnMult\''
local fatigueEndMultDesc =
'Percentage of endurance regained as fatigue, per second, with either formula, while sleeping. Replaces the vanilla GMST (0.04) \'fEndFatigueMult\''

-- Sleep settings description(s)
-- local pillowEnableDesc = 'Enable the pillow modifier. This adds a bonus to attributes restored while sleeping or waiting.'
-- local pillowMultDesc = 'Restoration bonus from carrying a pillow while sleeping.'
-- local saveOnRestDesc = 'Save the game when resting. This will save the game when the player rests, but not when they wait.'
-- local noSleepOnGroundDesc = 'Prevent sleeping on the ground. This will enforce only sleeping in some kind of bed (including bedrolls).'
-- local restMagicMultDesc = 'Multiplier for magicka restored while resting. Replaces the vanilla GMST (0.15) \'fRestMagicMult\'.'
-- local sleepFatigueMultDesc = 'Multiplier for fatigue restored while sleeping. Does not replace a vanilla GMST.'
-- local groundSleepMultDesc = 'Percentage of fatigue restored while sleeping on the ground. Does not replace a vanilla GMST.'
-- local bedrollSleepMultDesc = 'Multiplier for fatigue restored while sleeping on the ground. Does not replace a vanilla GMST.'
-- local bedSleepMultDesc = 'Multiplier for fatigue restored while sleeping on the ground. Does not replace a vanilla GMST, only applies indoors.'
-- local ownedSleepMultDesc = 'Multiplier for fatigue restored while sleeping in an owned bed. Does not replace a vanilla GMST, only applies indoors.'
-- local outdoorSleepMultDesc = 'Multiplier for fatigue restored while sleeping outdoors, in a bed. Does not replace a vanilla GMST.'
-- local outdoorWaitMultDesc = 'Multiplier for fatigue restored while sleeping on the ground or waiting, while outdoors. Does not replace a vanilla GMST.'
-- local indoorWaitMultDesc = 'Multiplier for fatigue restored while waiting indoors. Does not replace a vanilla GMST.'
local maxFatigueStrMultDesc = 'Percentage of strength factored into max fatigue. Vanilla is 100.'
local maxFatigueWilMultDesc = 'Percentage of willpower factored into max fatigue. Vanilla is 100.'
local maxFatigueAgiMultDesc = 'Percentage of agility factored into max fatigue. Vanilla is 100.'
local maxFatigueEndMultDesc = 'Percentage of endurance factored into max fatigue. Vanilla is 100.'
-- Critical hit settings description(s)
local critFumbleEnableDesc =
'Enable the critical hit and fumble module. This module adds a chance to deal extra damage on a critical hit, and less on a fumble. Requires the strength module to work.'
local critChancePercentDesc = 'Base chance of a critical hit'
local critLuckPercentDesc = 'Influence of luck on critical hit chance and fumble as a percentage'
local critMultDesc = 'Critical hit damage multiplier. Only applies in melee combat.'
local fumbleChancePercentDesc = 'Base chance of a fumble. Increse this to fumble more with lower skill.'
local fumbleChanceScaleDesc = 'Scale of fumble chance with skill. Increase this to fumble more regardless of skill.'
local fumbleDamagePercentDesc = 'Percentage of damage dealt to the target on a fumble'
-- Strength settings description(s)
local maxDamageMultDesc =
'Limit for the amount of damage done, based on chance the vanilla hit chance formula. 1.5 means 150% maximum damage from agility, skill, and luck.'

---@param key string
---@param renderer DefaultSettingRenderer
---@param argument SettingRendererOptions
---@param name string
---@param description string
---@param default string|number|boolean
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
        key = 'SettingsGlobal' .. modInfo.name .. 'Dynamic',
        page = modInfo.name,
        order = 0,
        l10n = modInfo.l10nName,
        name = 'Health, Fatigue, Magicka',
        permanentStorage = true,
        settings = {
                setting('UseVanillaFatigueFormula', 'checkbox', {}, 'Use Vanilla Fatigue Formula', useVanillaFatigueDesc, false),
                setting('FatiguePerSecond', 'number', { integer = true, min = -500, max = 500 },
                        'Fatigue Per Second', fatiguePerSecondDesc, 3),
                setting('FatigueReturnMult', 'number', { integer = false, min = 0.001, max = 10.0 },
                        'Fatigue Endurance Multiplier', fatigueReturnMultDesc, 0.02),
                setting('FatigueEndMult', 'number', { integer = false, min = 0.001, max = 10.0 },
                        'Resting Endurance Multiplier', fatigueEndMultDesc, 0.04),
                setting('MaxFatigueStrMult', 'number', { integer = true, min = 0, max = 1000 },
                        'Fatigue Strength Multiplier', maxFatigueStrMultDesc, 125),
                setting('MaxFatigueWilMult', 'number', { integer = true, min = 0, max = 1000 },
                        'Fatigue Willpower Multiplier', maxFatigueWilMultDesc, 50),
                setting('MaxFatigueAgiMult', 'number', { integer = true, min = 0, max = 1000 },
                        'Fatigue Agility Multiplier', maxFatigueAgiMultDesc, 25),
                setting('MaxFatigueEndMult', 'number', { integer = true, min = 0, max = 1000 },
                        'Fatigue Endurance Multiplier', maxFatigueEndMultDesc, 75),
                setting('FortifyMagickaMultiplier', 'number', { integer = true, min = 0, max = 1000 },
                        'Fortify Magicka Multiplier', 'NOT WRITTEN', 10),
                setting('PCbaseMagickaMultiplier', 'number', { integer = false, min = 0., max = 1000., },
                        'Player Base Magicka Multiplier', 'NOT WRITTEN', 1.),
                setting('NPCbaseMagickaMultiplier', 'number', { integer = false, min = 0., max = 1000., },
                        'NPC Base Magicka Multiplier', 'NOT WRITTEN', 2.),
        }
}

-- I.Settings.registerGroup {
-- 	key = 'SettingsGlobal' .. modInfo.name .. 'Sleep',
-- 	page = modInfo.name,
-- 	order = 2,
-- 	l10n = modInfo.l10nName,
-- 	name = 'Sleep Management',
-- 	permanentStorage = true,
-- 	settings = {
--       setting('PillowEnable', 'checkbox', {}, 'Pillow Restoration Multiplier', pillowEnableDesc, true),
--       setting('PillowMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Pillow Multiplier', pillowMultDesc, 0.10),
--       setting('SaveOnRest', 'checkbox', {}, 'Save When Resting', saveOnRestDesc, false),
--       setting('NoSleepOnGround', 'checkbox', {}, 'No Sleep on Ground', noSleepOnGroundDesc, false),
--       setting('SleepFatigueMult', 'number', {integer = true, min = -1000, max = 1000 },
--               'Sleep Restoration Multiplier', sleepFatigueMultDesc, 10),
--       setting('RestMagicMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Resting Magicka Multiplier', restMagicMultDesc, 0.15),
--       setting('RestHealthMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Resting Health Multiplier', restMagicMultDesc, 0.15),
--       setting('GroundSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Ground Resting Multiplier', groundSleepMultDesc, 0.50),
--       setting('BedrollSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Bedroll Resting Multiplier', bedrollSleepMultDesc, 0.75),
--       setting('BedSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Bed Resting Multiplier', bedSleepMultDesc, 1.25),
--       setting('OwnedSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Owned Bed Resting Multiplier', ownedSleepMultDesc, 1.40),
--       setting('OutdoorSleepMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Outdoor Bed Resting Multiplier', outdoorSleepMultDesc, 0.50),
--       setting('OutdoorWaitMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Outdoor Waiting Multiplier', outdoorWaitMultDesc, 0.15),
--       setting('IndoorWaitMult', 'number', {integer = false, min = -10.0, max = 10.0 },
--               'Indoor Waiting Multiplier', indoorWaitMultDesc, 0.50),
-- 	}
-- }

I.Settings.registerGroup {
        key = 'SettingsGlobal' .. modInfo.name .. 'Core',
        page = modInfo.name,
        order = 1,
        l10n = modInfo.l10nName,
        name = 'Damage, Crit, and Fumble',
        permanentStorage = true,
        settings = {
                setting('DebugEnable', 'checkbox', {}, 'Show Debug Messages', '', false),
                setting('AgilityHitChancePct', 'number', { integer = false, min = 0.001, max = 1.0 },
                        'Agility Hit Chance Influence', agilityHitChancePctDesc, 0.20),
                setting('LuckHitChancePct', 'number', { integer = false, min = 0.001, max = 1.0 },
                        'Luck Hit Chance Influence', luckHitChancePctDesc, 0.10),
                setting('MaxDamageMultiplier', 'number', { integer = false, min = 0.01, max = 10. },
                        'Max Damage Multiplier', maxDamageMultDesc, 1.5),
                setting('EnableCritFumble', 'checkbox', {}, 'Enable Crit and Fumble Module', critFumbleEnableDesc, true),
                setting('CritChancePercent', 'number', { integer = true, min = 0, max = 100 },
                        'Base Critical Hit Chance', critChancePercentDesc, 4),
                setting('CritLuckPercent', 'number', { integer = true, min = 0, max = 1000 },
                        'Critical Luck Influence', critLuckPercentDesc, 10),
                setting('CritDamageMultiplier', 'number', { integer = false, min = 1.0, max = 10.0 },
                        'Melee Critical Damage Multiplier', critMultDesc, 4.0),
                setting('FumbleBaseChance', 'number', { integer = true, min = 0, max = 100 },
                        'Base Fumble Chance', fumbleChancePercentDesc, 3),
                setting('FumbleChanceScale', 'number', { integer = true, min = 0, max = 100 },
                        'Fumble Chance Scale', fumbleChanceScaleDesc, 10),
                setting('FumbleDamagePercent', 'number', { integer = true, min = 0, max = 100 },
                        'Fumble Damage Percentage', fumbleDamagePercentDesc, 25),
        },
}

local ParryGroupName = 'SettingsGlobal' .. modInfo.name .. 'Parry'
local MinParryFramesDefault, MaxParryFramesDefault = 2, 16
local MinDamageMultDefault, MaxDamageMultDefault = 0.25, 1.5
I.Settings.registerGroup {
        key = ParryGroupName,
        page = modInfo.name .. 'Block & Parry',
        order = 1,
        l10n = modInfo.l10nName,
        name = 'ParryGroupName',
        permanentStorage = true,
        settings = {
                setting(
                        'DebugEnable',
                        'checkbox',
                        {},
                        'Show Debug Messages',
                        '',
                        false
                ),
                setting(
                        'BaseParryFrames',
                        'number',
                        { integer = true, min = 0, max = 100, },
                        'BaseParryFramesName',
                        'BaseParryFramesDesc',
                        4
                ),
                setting(
                        'BaseShieldFrames',
                        'number',
                        { integer = true, min = 0, max = 100 },
                        'BaseShieldFramesName',
                        'BaseShieldFramesDesc',
                        8
                ),
                setting(
                        'BlockFrameMult',
                        'number',
                        { integer = true, min = 0, max = 100 },
                        'BlockFrameMultName',
                        'BlockFrameMultDesc',
                        3
                ),
                setting(
                        'MaxParryFrames',
                        'number',
                        { integer = true, min = MinParryFramesDefault + 1, max = 100 },
                        'MaxParryFramesName',
                        'MaxParryFramesDesc',
                        MaxParryFramesDefault
                ),
                setting(
                        'MinParryFrames',
                        'number',
                        { integer = true, min = 0, max = MaxParryFramesDefault - 1 },
                        'MinParryFramesName',
                        'MinParryFramesDesc',
                        MinParryFramesDefault
                ),
                setting(
                        'PerUnitShieldWeightPenalty',
                        'number',
                        { integer = true, min = 0, max = 10 },
                        'PerUnitShieldWeightPenaltyName',
                        'PerUnitShieldWeightPenaltyDesc',
                        3
                ),
                setting(
                        'BaseDamageMultiplier',
                        'number',
                        { integer = false, min = 0., max = 10. },
                        'BaseDamageMultName',
                        'BaseDamageMultDesc',
                        0.25
                ),
                setting(
                        'ShieldSizeInfluence',
                        'number',
                        { integer = false, min = 0., max = 10. },
                        'ShieldSizeInfluenceName',
                        'ShieldSizeInfluenceDesc',
                        0.3
                ),
                setting(
                        'StrengthDamageBonus',
                        'number',
                        { integer = false, min = 0., max = 10. },
                        'StrengthDamageBonusName',
                        'StrengthDamageBonusDesc',
                        0.002
                ),
                setting(
                        'BlockSkillBonus',
                        'number',
                        { integer = false, min = 0., max = 10. },
                        'BlockSkillBonusName',
                        'BlockSkillBonusDesc',
                        0.001
                ),
                setting(
                        'MinDamageMultiplier',
                        'number',
                        { integer = false, min = 0., max = MaxDamageMultDefault - 0.1, },
                        'MinDamageMultName',
                        'MinDamageMultDesc',
                        MinDamageMultDefault
                ),
                setting(
                        'MaxDamageMultiplier',
                        'number',
                        { integer = false, min = MinDamageMultDefault - 0.1, max = 10., },
                        'MaxDamageMultName',
                        'MaxDamageMultDesc',
                        MaxDamageMultDefault
                ),
        },
}

local ParryGroup = storage.globalSection(ParryGroupName)
ParryGroup:subscribe(
        async:callback(
                function(group, key)
                        local settingValue = ParryGroup:get(key)

                        if key == 'MaxDamageMultiplier' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MinDamageMultiplier',
                                        { max = settingValue - 0.1 }
                                )
                        elseif key == 'MinDamageMultiplier' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MaxDamageMultiplier',
                                        { min = settingValue + 0.1 }
                                )
                        elseif key == 'MaxParryFrames' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MinParryFrames',
                                        { max = settingValue - 1 }
                                )
                        elseif key == 'MinParryFrames' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MaxParryFrames',
                                        { min = settingValue + 1 }
                                )
                        end
                end
        )
)

local BlockGroupName = 'SettingsGlobal' .. modInfo.name .. 'Block'
I.Settings.registerGroup {
        key = BlockGroupName,
        page = modInfo.name .. 'Block & Parry',
        order = 0,
        l10n = modInfo.l10nName,
        name = 'BlockGroupName',
        permanentStorage = true,
        settings = {
                setting(
                        'DebugEnable',
                        'checkbox',
                        {},
                        'Show Debug Messages',
                        '',
                        false
                ),
                setting(
                        'BaseBlockMitigation',
                        'number',
                        { min = 0.0, max = 1.0, integer = false, },
                        'BaseBlockMitigationName',
                        'BaseBlockMitigationDesc',
                        0.15
                ),
                setting(
                        'SkillMitigationFactor',
                        'number',
                        { min = 0.0, max = 1.0, integer = false, },
                        'SkillMitigationFactorName',
                        'SkillMitigationFactorDesc',
                        0.005
                ),
                setting(
                        'AttributeMitigationFactor',
                        'number',
                        { min = 0.0, max = 1.0, integer = false, },
                        'AttributeMitigationFactorName',
                        'AttributeMitigationFactorDesc',
                        0.002
                ),
                setting(
                        'MinimumMitigation',
                        'number',
                        { integer = false, min = 0.0, max = 1.0 },
                        'MinimumMitigationName',
                        'MinimumMitigationDesc',
                        0.1
                ),
                setting(
                        'MaximumMitigation',
                        'number',
                        { integer = false, min = 0.0, max = 1.0 },
                        'MaximumMitigationName',
                        'MaximumMitigationDesc',
                        0.95
                ),
                setting(
                        'MaxArmorBonus',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'MaxArmorBonusName',
                        'MaxArmorBonusDesc',
                        0.18
                ),
                setting(
                        'MaxWeightBonus',
                        'number',
                        { integer = false, min = 0.0, max = 1.0 },
                        'MaxWeightBonusName',
                        'MaxWeightBonusDesc',
                        0.4
                ),
                setting(
                        'BlockSpeedLuckWeight',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'BlockSpeedLuckWeightName',
                        'BlockSpeedLuckWeightDesc',
                        0.15
                ),
                setting(
                        'BlockSpeedAgilityWeight',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'BlockSpeedAgilityWeightName',
                        'BlockSpeedAgilityWeightDesc',
                        0.3
                ),
                setting(
                        'BlockSpeedBase',
                        'number',
                        { integer = false, min = 0.0, max = 10.0, },
                        'BlockSpeedBaseName',
                        'BlockSpeedBaseDesc',
                        0.75
                ),
                setting(
                        'ShieldWeightPenalty',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'ShieldWeightPenaltyName',
                        'ShieldWeightPenaltyDesc',
                        0.005
                ),
                setting(
                        'ShieldWeightPenaltyLimit',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'ShieldWeightPenaltyLimitName',
                        'ShieldWeightPenaltyLimitDesc',
                        0.5
                )
        }
}

local BlockGroup = storage.globalSection(BlockGroupName)
BlockGroup:subscribe(
        async:callback(
                function(group, key)
                        local settingValue = BlockGroup:get(key)

                        if key == 'MinimumMitigation' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MaximumMitigation',
                                        { min = settingValue + 0.01 }
                                )
                        elseif key == 'MaximumMitigation' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MinimumMitigation',
                                        { max = settingValue - 0.01 }
                                )
                        end
                end
        )
)
