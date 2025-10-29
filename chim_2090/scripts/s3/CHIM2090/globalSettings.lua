local async = require 'openmw.async'
local core = require 'openmw.core'
local storage = require 'openmw.storage'

local I = require 'openmw.interfaces'

local modInfo = require 'scripts.s3.CHIM2090.modInfo'
local L = core.l10n(modInfo.l10nName)

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

local fFatigueBlockBase = core.getGMST('fFatigueBlockBase')
local fFatigueBlockMult = core.getGMST('fFatigueBlockMult')
local fWeaponFatigueBlockMult = core.getGMST('fWeaponFatigueBlockMult')
I.Settings.registerGroup {
        key = 'SettingsGlobal' .. modInfo.name .. 'Dynamic',
        page = modInfo.name .. 'Dynamic Stats',
        order = 0,
        l10n = modInfo.l10nName,
        name = 'SettingsDynamicGroupName',
        permanentStorage = true,
        settings = {
                setting('DebugEnable',
                        'checkbox',
                        {},
                        'DynamicDebugEnableName',
                        'DynamicDebugEnableDesc',
                        false
                ),
                setting('UseVanillaFatigueFormula',
                        'checkbox',
                        {},
                        'UseVanillaFatigueName',
                        'UseVanillaFatigueDesc',
                        false
                ),
                setting(
                        'FatiguePerSecond',
                        'number',
                        { integer = true, min = -500, max = 500 },
                        'FatiguePerSecondName',
                        'FatiguePerSecondDesc',
                        3
                ),
                setting(
                        'FatigueReturnMult',
                        'number',
                        { integer = false, min = 0.001, max = 10.0 },
                        'FatigueReturnMultName',
                        'FatigueReturnMultDesc',
                        0.02
                ),
                -- This setting is only used for sleeping, which is disabled
                -- setting(
                --         'FatigueEndMult',
                --         'number',
                --         { integer = false, min = 0.001, max = 10.0 },
                --         'Resting Endurance Multiplier',
                --         fatigueEndMultDesc,
                --         0.04
                -- ),
                setting(
                        'MaxFatigueStrMult',
                        'number',
                        { integer = true, min = 0, max = 1000 },
                        'MaxFatigueStrMultName',
                        'MaxFatigueStrMultDesc',
                        125
                ),
                setting(
                        'MaxFatigueWilMult',
                        'number',
                        { integer = true, min = 0, max = 1000 },
                        'MaxFatigueWilMultName',
                        'MaxFatigueWilMultDesc',
                        50
                ),
                setting(
                        'MaxFatigueAgiMult',
                        'number',
                        { integer = true, min = 0, max = 1000 },
                        'MaxFatigueAgiMultName',
                        'MaxFatigueAgiMultDesc',
                        25
                ),
                setting(
                        'MaxFatigueEndMult',
                        'number',
                        { integer = true, min = 0, max = 1000 },
                        'MaxFatigueEndMultName',
                        'MaxFatigueEndMultDesc',
                        75
                ),
                setting(
                        'FortifyMagickaMultiplier',
                        'number',
                        { integer = true, min = 0, max = 1000 },
                        'FortifyMagickaMultiplierName',
                        'FortifyMagickaMultiplierDesc',
                        10
                ),
                setting(
                        'PCbaseMagickaMultiplier',
                        'number',
                        { integer = false, min = 0., max = 1000., },
                        'MagickaMultiplierPCbaseName',
                        'MagickaMultiplierPCbaseDesc',
                        1.
                ),
                setting(
                        'NPCbaseMagickaMultiplier',
                        'number',
                        { integer = false, min = 0., max = 1000., },
                        'MagickaMultiplierNPCbaseName',
                        'MagickaMultiplierNPCbaseDesc',
                        2.
                ),
                setting(
                        'FatigueBlockBase',
                        'number',
                        { integer = false, min = 0.0, max = 1000.0, },
                        'FatigueBlockBaseName',
                        L('FatigueBlockBaseDesc', { value = fFatigueBlockBase }),
                        fFatigueBlockBase
                ),
                setting(
                        'FatigueBlockMult',
                        'number',
                        { integer = false, min = 0.0, max = 1000.0, },
                        'FatigueBlockMultName',
                        L('FatigueBlockMultDesc', { value = fFatigueBlockMult }),
                        fFatigueBlockMult
                ),
                setting(
                        'WeaponFatigueBlockMult',
                        'number',
                        { integer = false, min = 0.0, max = 1000.0, },
                        'WeaponFatigueBlockMultName',
                        L('WeaponFatigueBlockMultDesc', { value = fWeaponFatigueBlockMult }),
                        fWeaponFatigueBlockMult
                ),
                setting(
                        'BaseHealth',
                        'number',
                        { integer = true, min = 10, max = 1000, },
                        'BaseHealthName',
                        'BaseHealthDesc',
                        30
                ),
                setting(
                        'HealthLinearMult',
                        'number',
                        { integer = false, min = 0.0, max = 10.0, },
                        'HealthLinearMultName',
                        'HealthLinearMultDesc',
                        2.0
                ),
                setting(
                        'HealthDiminishingExponent',
                        'number',
                        { integer = false, min = 0.6, max = 1.5, },
                        'HealthDiminishingExponentName',
                        'HealthDiminishingExponentDesc',
                        1.2
                ),
                setting(
                        'HealthVitalityMult',
                        'number',
                        { integer = false, min = 0.0, max = 10.0, },
                        'HealthVitalityMultName',
                        'HealthVitalityMultDesc',
                        0.8
                )
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

local LightAnimSpeed, MediumAnimSpeed, HeavyAnimSpeed, OverloadedAnimSpeed = 1.25, 0.9, 0.65, 0.5
local CoreGroupName = 'SettingsGlobal' .. modInfo.name .. 'Core'
I.Settings.registerGroup {
        key = CoreGroupName,
        page = modInfo.name,
        order = 0,
        l10n = modInfo.l10nName,
        name = 'SettingsCoreGroupName',
        permanentStorage = true,
        settings = {
                setting(
                        'DebugEnable',
                        'checkbox',
                        {},
                        'DebugEnableChimCoreName',
                        'DebugEnableChimCoreDesc',
                        false
                ),
                setting(
                        'GlobalDamageScaling',
                        'number',
                        { integer = false, min = 0.0, max = 100.0, },
                        'GlobalDamageScalingName',
                        'GlobalDamageScalingDesc',
                        1.0
                ),
                setting(
                        'AgilityHitChancePct',
                        'number',
                        { integer = false, min = 0.001, max = 1.0 },
                        'AgilityHitChancePctName',
                        'AgilityHitChancePctDesc',
                        0.20
                ),
                setting(
                        'LuckHitChancePct',
                        'number',
                        { integer = false, min = 0.001, max = 1.0 },
                        'LuckHitChancePctName',
                        'LuckHitChancePctDesc',
                        0.10
                ),
                setting(
                        'MaxDamageMultiplier',
                        'number',
                        { integer = false, min = 0.01, max = 10. },
                        'MaxDamageMultName',
                        'MaxDamageMultDesc',
                        1.5
                ),
                setting(
                        'EnableCritFumble',
                        'checkbox',
                        {},
                        'CritFumbleEnableName',
                        'CritFumbleEnableDesc',
                        true
                ),
                setting(
                        'CritChancePercent',
                        'number',
                        { integer = true, min = 0, max = 100 },
                        'CritChancePercentName',
                        'CritChancePercentDesc',
                        4
                ),
                setting(
                        'CritLuckPercent',
                        'number',
                        { integer = true, min = 0, max = 1000 },
                        'CritLuckPercentName',
                        'CritLuckPercentDesc',
                        10
                ),
                setting(
                        'CritDamageMultiplier',
                        'number',
                        { integer = false, min = 1.0, max = 10.0 },
                        'CritMultName',
                        'CritMultDesc',
                        4.0
                ),
                setting(
                        'FumbleBaseChance',
                        'number',
                        { integer = true, min = 0, max = 100 },
                        'FumbleBaseChanceName',
                        'FumbleBaseChanceDesc',
                        3
                ),
                setting(
                        'FumbleChanceScale',
                        'number',
                        { integer = true, min = 0, max = 100 },
                        'FumbleChanceScaleName',
                        'FumbleChanceScaleDesc',
                        10
                ),
                setting(
                        'FumbleDamagePercent',
                        'number',
                        { integer = true, min = 0, max = 100 },
                        'FumbleDamagePercentName',
                        'FumbleDamagePercentDesc',
                        25
                ),
                setting(
                        'LightAnimSpeed',
                        'number',
                        { integer = false, min = MediumAnimSpeed + 0.1, max = 10.0, },
                        'AnimSpeedLightName',
                        'AnimSpeedLightDesc',
                        LightAnimSpeed
                ),
                setting(
                        'MediumAnimSpeed',
                        'number',
                        { integer = false, min = HeavyAnimSpeed + 0.1, max = LightAnimSpeed - 0.1, },
                        'AnimSpeedMediumName',
                        'AnimSpeedMediumDesc',
                        MediumAnimSpeed
                ),
                setting(
                        'HeavyAnimSpeed',
                        'number',
                        { integer = false, min = OverloadedAnimSpeed + 0.1, max = MediumAnimSpeed - 0.1, },
                        'AnimSpeedHeavyName',
                        'AnimSpeedHeavyDesc',
                        HeavyAnimSpeed
                ),
                setting(
                        'OverloadedAnimSpeed',
                        'number',
                        { integer = false, min = 0.0, max = HeavyAnimSpeed - 0.1, },
                        'AnimSpeedOverloadedName',
                        'AnimSpeedOverloadedDesc',
                        OverloadedAnimSpeed
                ),
        },
}

local CoreGroup = storage.globalSection(CoreGroupName)
CoreGroup:subscribe(
        async:callback(
                function(group, key)
                        local settingValue = CoreGroup:get(key)

                        if key == 'LightAnimSpeed' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MediumAnimSpeed',
                                        { max = settingValue - 1 }
                                )
                        elseif key == 'MediumAnimSpeed' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'LightAnimSpeed',
                                        { min = settingValue + 0.1 }
                                )
                                I.Settings.updateRendererArgument(
                                        group,
                                        'HeavyAnimSpeed',
                                        { max = settingValue - 0.1 }
                                )
                        elseif key == 'HeavyAnimSpeed' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MediumAnimSpeed',
                                        { min = settingValue + 0.1 }
                                )
                                I.Settings.updateRendererArgument(
                                        group,
                                        'OverloadedAnimSpeed',
                                        { max = settingValue - 0.1, }
                                )
                        elseif key == 'OverloadedAnimSpeed' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'HeavyAnimSpeed',
                                        { min = settingValue + 0.1 }
                                )
                        end
                end
        )
)

local ParryGroupName = 'SettingsGlobal' .. modInfo.name .. 'Parry'
local MinParryFramesDefault, MaxParryFramesDefault = 2, 16
local MinDamageMultDefault, MaxDamageMultDefault = 0.25, 1.5
I.Settings.registerGroup {
        key = ParryGroupName,
        page = modInfo.name .. 'Block & Parry',
        order = 0,
        l10n = modInfo.l10nName,
        name = 'SettingsParryGroupName',
        permanentStorage = true,
        settings = {
                setting(
                        'DebugEnable',
                        'checkbox',
                        {},
                        'BlockDebugEnableName',
                        'BlockDebugEnableDesc',
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
                        'MaxParryDamageMultName',
                        'MaxParryDamageMultDesc',
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
        name = 'SettingsBlockGroupName',
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
                        'BlockKeybind',
                        'inputBinding',
                        { key = 'CHIMBlockAction', type = 'action', },
                        'BlockKeybindName',
                        'BlockKeybindDesc',
                        'mouse 2'
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
                        'StandingStillBonus',
                        'number',
                        { integer = false, min = 1.0, max = 10.0, },
                        'StandingStillBonusName',
                        'StandingStillBonusDesc',
                        1.25
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
                ),
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

local PoiseGroupName = 'SettingsGlobal' .. modInfo.name .. 'Poise'
local BasePoiseDefault = 20
I.Settings.registerGroup {
        key = PoiseGroupName,
        page = modInfo.name .. 'Poise',
        order = 0,
        l10n = modInfo.l10nName,
        name = 'SettingsPoiseGroupName',
        permanentStorage = true,
        settings = {
                setting(
                        'DebugEnable',
                        'checkbox',
                        {},
                        'PoiseDebugEnableName',
                        'PoiseDebugEnableDesc',
                        false
                ),
                setting(
                        'Enable',
                        'checkbox',
                        {},
                        'PoiseEnableName',
                        'PoiseEnableDesc',
                        true
                ),
                setting(
                        'ShieldsMitigatePoiseDamage',
                        'checkbox',
                        {},
                        'ShieldsMitigatePoiseDamageName',
                        'ShieldsMitigatePoiseDamageDesc',
                        true
                ),
                setting(
                        'AlwaysScaleHitAnimSpeed',
                        'checkbox',
                        {},
                        'AlwaysScaleHitAnimSpeedName',
                        'AlwaysScaleHitAnimSpeedDesc',
                        true
                ),
                setting(
                        'BasePoise',
                        'number',
                        { integer = true, min = 0, max = 100, },
                        'BasePoiseName',
                        'BasePoiseDesc',
                        BasePoiseDefault
                ),
                setting(
                        'PoisePerWeight',
                        'number',
                        { integer = false, min = 0.0, max = 10.0 },
                        'PoisePerWeightName',
                        'PoisePerWeightDesc',
                        0.8
                ),
                setting(
                        'PoiseBreakAnimSpeed',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'PoiseBreakAnimSpeedName',
                        'PoiseBreakAnimSpeedDesc',
                        0.85
                ),
                setting(
                        'MaxEquipmentPoise',
                        'number',
                        { integer = true, min = BasePoiseDefault + 1, max = 1000 },
                        'MaxEquipmentPoiseName',
                        'MaxEquipmentPoiseDesc',
                        80
                ),
                setting(
                        'MaxTotalPoise',
                        'number',
                        { integer = true, min = BasePoiseDefault + 1, max = 1000, },
                        'MaxTotalPoiseName',
                        'MaxTotalPoiseDesc',
                        120
                ),
                setting(
                        'StrengthPoiseBonus',
                        'number',
                        { inteer = false, min = 0, 0, max = 10.0 },
                        'StrengthPoiseBonusName',
                        'StrengthPoiseBonusDesc',
                        0.1
                ),
                setting(
                        'StrengthPoiseDamageBonus',
                        'number',
                        { inteer = false, min = 0, 0, max = 10.0 },
                        'StrengthPoiseBonusName',
                        'StrengthPoiseBonusDesc',
                        0.01
                ),
                setting(
                        'EndurancePoiseBonus',
                        'number',
                        { inteer = false, min = 0, 0, max = 10.0 },
                        'EndurancePoiseBonusName',
                        'EndurancePoiseBonusDesc',
                        0.15
                ),
                setting(
                        'PoiseRecoveryDuration',
                        'number',
                        { integer = false, min = 0.1, max = 120.0, },
                        'PoiseRecoveryDurationName',
                        'PoiseRecoveryDurationDesc',
                        5.0
                ),
                setting(
                        'PoiseDamageMult',
                        'number',
                        { integer = false, min = 0.1, max = 10.0, },
                        'PoiseDamageMultName',
                        'PoiseDamageMultDesc',
                        2.0
                ),
                setting(
                        'MinPoiseDamage',
                        'number',
                        { integer = true, min = 0, max = 120 },
                        'MinPoiseDamageName',
                        'MinPoiseDamageDesc',
                        5
                ),
                setting(
                        'WeightPoiseFactor',
                        'number',
                        { integer = false, min = 0.0, max = 10.0 },
                        'WeightPoiseFactorName',
                        'WeightPoiseFactorDesc',
                        0.15
                ),
                setting(
                        'WeaponSkillPoiseFactor',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'WeaponSkillPoiseFactorName',
                        'WeaponSkillPoiseFactorDesc',
                        0.1
                ),
                setting(
                        'WeaponPoiseMult',
                        'number',
                        { integer = false, min = 0.0, max = 10.0, },
                        'WeaponPoiseMultName',
                        'WeaponPoiseMultDesc',
                        0.8
                ),
                setting(
                        'TwoHandedMult',
                        'number',
                        { integer = false, min = 0.0, max = 10.0, },
                        'TwoHandedMultName',
                        'TwoHandedMultDesc',
                        1.4
                ),
                setting(
                        'HandToHandSkillPoiseFactor',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'HandToHandSkillPoiseFactorName',
                        'HandToHandSkillPoiseFactorDesc',
                        0.08
                ),
                setting(
                        'AgilityPoiseBonus',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'AgilityPoiseBonusName',
                        'AgilityPoiseBonusDesc',
                        --- Grants 20 poise damage at 100 agility
                        0.2
                ),
                setting(
                        'HandToHandPoiseMult',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'HandToHandPoiseMultName',
                        'HandToHandPoiseMultDesc',
                        1.15
                ),
                setting(
                        'CreatureBasePoiseDamage',
                        'number',
                        { integer = true, min = 0, max = 1000, },
                        'CreatureBasePoiseDamageName',
                        'CreatureBasePoiseDamageDesc',
                        15
                ),
                setting(
                        'CreatureStrengthPoiseFactor',
                        'number',
                        { integer = false, min = 0.0, max = 1.0, },
                        'CreatureStrengthPoiseFactorName',
                        'CreatureStrengthPoiseFactorDesc',
                        0.15
                ),
                setting(
                        'EquipmentSlotTimeReduction',
                        'number',
                        { integer = false, min = 0.0, max = 0.07, },
                        'EquipmentSlotTimeReductionName',
                        'EquipmentSlotTimeReductionDesc',
                        0.03
                ),
                setting(
                        'MinRecoveryDuration',
                        'number',
                        { integer = false, min = 0.0, max = 120.0, },
                        'MinRecoveryDurationName',
                        'MinRecoveryDurationDesc',
                        1.5
                ),
        },
}

local PoiseGroup = storage.globalSection(PoiseGroupName)
PoiseGroup:subscribe(
        async:callback(
                function(group, key)
                        local settingValue = PoiseGroup:get(key)

                        if key == 'BasePoise' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MaxTotalPoise',
                                        { min = settingValue + 1 }
                                )
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MaxEquipmentPoise',
                                        { min = settingValue + 1 }
                                )
                        elseif key == 'MinRecoveryDuration' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'PoiseRecoveryDuration',
                                        { min = settingValue + 0.01, }
                                )
                        elseif key == 'PoiseRecoveryDuration' then
                                I.Settings.updateRendererArgument(
                                        group,
                                        'MinRecoveryDuration',
                                        { max = settingValue - 0.01, }
                                )
                        end
                end
        )
)
