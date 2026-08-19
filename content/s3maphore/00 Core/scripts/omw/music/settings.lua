---@omw-context menu

local async = require 'openmw.async'
local storage = require 'openmw.storage'

local I = require 'openmw.interfaces'

I.Settings.registerPage {
  key = 'S3Music',
  l10n = 'S3Music',
  name = 'Music',
  description = 'settingsPageDescription',
}

I.Settings.registerGroup {
  key = 'SettingsS3Music',
  page = 'S3Music',
  l10n = 'S3Music',
  name = 'musicSettings',
  permanentStorage = true,
  order = 0,
  settings = {
    {
      key = 'DebugEnable',
      renderer = 'checkbox',
      name = 'DebugEnabled',
      description = 'DebugEnabledDescription',
      default = false,
    },
    {
      key = 'MusicEnabled',
      renderer = 'checkbox',
      name = 'MusicEnabled',
      description = 'MusicEnabledDescription',
      default = true,
    },
    {
      key = 'BattleEnabled',
      renderer = 'checkbox',
      name = 'BattleEnabled',
      description = 'BattleEnabledDescription',
      default = true,
    },
    {
      key = 'ExploreEnabled',
      renderer = 'checkbox',
      name = 'ExploreEnabled',
      description = 'ExploreEnabledDescription',
      default = true,
    },
    {
      key = 'BannerEnabled',
      renderer = 'checkbox',
      name = 'BannerEnabled',
      description = 'BannerEnabledDescription',
      default = false,
    },
    {
      key = 'ForceFinishTrack',
      renderer = 'checkbox',
      name = 'NoInterrupt',
      description = 'NoInterruptDescription',
      default = true,
    },
    {
      key = 'ForcePlaylistChangeOnFriendlyExteriorTransition',
      renderer = 'checkbox',
      name = 'ForcePlaylistChangeOnFriendlyExteriorTransition',
      description = 'ForcePlaylistChangeOnFriendlyExteriorTransitionDescription',
      default = false,
    },
    {
      key = 'ForcePlaylistChangeOnHostileExteriorTransition',
      renderer = 'checkbox',
      name = 'ForcePlaylistChangeOnHostileExteriorTransition',
      description = 'ForcePlaylistChangeOnHostileExteriorTransitionDescription',
      default = true,
    },
    {
      key = 'ForcePlaylistChangeOnOverworldTransition',
      renderer = 'checkbox',
      name = 'ForcePlaylistChangeOnOverworldTransition',
      description = 'ForcePlaylistChangeOnOverworldTransitionDescription',
      default = false,
    },
    {
      key = 'FadeOutDuration',
      renderer = 'number',
      name = 'FadeOutDuration',
      description = 'FadeOutDurationDescription',
      argument = { min = 0.0, max = 30.0, integer = false },
      default = 1.0,
    },
    {
      key = 'PlayerTargetedCombatOnly',
      renderer = 'checkbox',
      name = 'PlayerTargetedCombatOnly',
      description = 'PlayerTargetedCombatOnlyDescription',
      default = true,
    },
    {
      key = 'CombatHealthThreshold',
      renderer = 'number',
      name = 'CombatHealthThreshold',
      description = 'CombatHealthThresholdDescription',
      argument = { min = 0.0, max = 1.0, integer = false },
      default = 0.0,
    },
    {
      key = 'CombatLevelGap',
      renderer = 'number',
      name = 'CombatLevelGap',
      description = 'CombatLevelGapDescription',
      argument = { min = 0, max = 1000, integer = true },
      default = 0,
    },
  },
}

local HUGE = math.huge

I.Settings.registerGroup {
  key = 'SettingsS3MusicSilenceConfig',
  page = 'S3Music',
  l10n = 'S3Music',
  name = 'SilenceConfiguration',
  permanentStorage = true,
  order = 1,
  settings = {
    {
      key = 'GlobalSilenceToggle',
      renderer = 'checkbox',
      argument = {},
      name = 'GlobalSilenceToggle',
      description = 'GlobalSilenceToggleDesc',
      default = true,
    },
    {
      key = 'GlobalSilenceChance',
      renderer = 'number',
      argument = { min = 0.0, max = 1.0, integer = false },
      name = 'GlobalSilenceChanceName',
      description = 'GlobalSilenceChanceDesc',
      default = 0.15,
    },
    {
      key = 'ExploreSilenceMin',
      renderer = 'number',
      argument = { min = 0, max = 119, integer = true },
      name = 'ExploreSilenceMinDuration',
      description = 'ExploreSilenceMinDesc',
      default = 0,
    },
    {
      key = 'ExploreSilenceMax',
      renderer = 'number',
      argument = { min = 0, max = HUGE, integer = true },
      name = 'ExploreSilenceMaxDuration',
      description = 'ExploreSilenceMaxDesc',
      default = 120,
    },
    {
      key = 'BattleSilenceMin',
      renderer = 'number',
      argument = { min = 0, max = HUGE, integer = true },
      name = 'BattleSilenceMinDuration',
      description = 'BattleSilenceMinDesc',
      default = 0,
    },
    {
      key = 'BattleSilenceMax',
      renderer = 'number',
      argument = { min = 0, max = HUGE, integer = true },
      name = 'BattleSilenceMaxDuration',
      description = 'BattleSilenceMaxDesc',
      default = 120,
    },
  },
}

local SilenceGroup = storage.playerSection 'SettingsS3MusicSilenceConfig'
SilenceGroup:subscribe(async:callback(function(groupName, _)
  local exploreSilenceMin, exploreSilenceMax =
    SilenceGroup:get 'ExploreSilenceMin', SilenceGroup:get 'ExploreSilenceMax'

  local battleSilenceMin, battleSilenceMax =
    SilenceGroup:get 'BattleSilenceMin', SilenceGroup:get 'BattleSilenceMax'

  local disabled = not SilenceGroup:get 'GlobalSilenceToggle'

  I.Settings.updateRendererArgument(groupName, 'GlobalSilenceChance', {
    disabled = disabled,
  })

  I.Settings.updateRendererArgument(groupName, 'ExploreSilenceMin', {
    max = exploreSilenceMax - 1,
    disabled = disabled,
  })

  I.Settings.updateRendererArgument(groupName, 'ExploreSilenceMax', {
    min = exploreSilenceMin + 1,
    disabled = disabled,
  })

  I.Settings.updateRendererArgument(groupName, 'BattleSilenceMin', {
    max = battleSilenceMax - 1,
    disabled = disabled,
  })

  I.Settings.updateRendererArgument(groupName, 'BattleSilenceMax', {
    min = battleSilenceMin + 1,
    disabled = disabled,
  })
end))
