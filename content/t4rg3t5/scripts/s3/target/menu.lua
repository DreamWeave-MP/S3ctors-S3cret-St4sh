---@omw-context menu

do
  local input = require 'openmw.input'
  local HexColor = require('openmw.util').color.hex

  local I = require 'openmw.interfaces'

  local ModInfo = require 'scripts.s3.target.modInfo'

  local iconNames = {}

  for icon in require('openmw.vfs').pathsWithPrefix 'textures/s3/crosshair/' do
    if icon:find '.dds' then iconNames[#iconNames + 1] = icon:match '.*/(.-)%.' end
  end

  --- Shorthand to generate Setting tables for input into `I.Settings.registerGroup`'s `settings` argument.
  ---@param key string The (table) key of the setting
  ---@param renderer string The type of setting to create
  ---@param argument table<string, any> The options for the setting renderer, specific to the `renderer` type
  ---@param name string The displayed name of the setting in the menu
  ---@param description string The description of the setting in the menu
  ---@param default any The default value of the setting
  ---@return table
  local function Setting(key, renderer, argument, name, description, default)
    return {
      key = key,
      renderer = renderer,
      argument = argument,
      name = name,
      description = description,
      default = default,
    }
  end

  input.registerTrigger {
    key = 'S3TargetLock',
    l10n = ModInfo.l10nName,
    name = 'TargetLockActionName',
    description = 'TargetLockActionDesc',
  }

  I.Settings.registerPage {
    key = ModInfo.name,
    l10n = ModInfo.l10nName,
    name = 'TargetLockPageName',
    description = 'TargetLockPageDescription',
  }

  I.Settings.registerGroup {
    key = ModInfo.groupName,
    page = ModInfo.name,
    l10n = ModInfo.l10nName,
    order = 0,
    name = 'MainPageName',
    permanentStorage = true,
    settings = {
      Setting(
        'S3TargetLockBinding',
        'inputBinding',
        { key = 'S3TargetLock', type = 'trigger' },
        'S3TargetLockBindingName',
        'S3TargetLockBindingDesc',
        'T4TargetLockBindingKey'
      ),

      Setting(
        'TargetLockToggle',
        'checkbox',
        {},
        'TargetLockToggleName',
        'TargetLockToggleDesc',
        true
      ),
      Setting(
        'SwitchOnDeadTarget',
        'checkbox',
        {},
        'SwitchOnDeadTargetName',
        'SwitchOnDeadTargetDesc',
        true
      ),
      Setting('CheckLOS', 'checkbox', {}, 'CheckLOSName', 'CheckLOSDesc', false),
      Setting(
        'EnableFlickSwitch',
        'checkbox',
        {},
        'EnableFlickSwitchName',
        'EnableFlickSwitchDesc',
        true
      ),
      Setting(
        'FlickSwitchDistance',
        'number',
        { integer = true, min = 16, max = 512 },
        'FlickSwitchDistanceName',
        'FlickSwitchDistanceDesc',
        64
      ),
      Setting(
        'EnableHitBounce',
        'checkbox',
        {},
        'EnableHitBounceName',
        'EnableHitBounceDesc',
        true
      ),
      Setting(
        'HitBounceSize',
        'number',
        { integer = true, min = 1, max = 32 },
        'HitBounceSizeName',
        'HitBounceSizeDesc',
        16
      ),
      Setting(
        'DisableLockWhenSheathing',
        'checkbox',
        {},
        'DisableLockWhenSheathingName',
        'DisableLockWhenSheathingDesc',
        false
      ),
      Setting(
        'LockOnCombatStart',
        'checkbox',
        {},
        'LockOnCombatStartName',
        'LockOnCombatStartDesc',
        false
      ),

      Setting(
        'CameraDistance',
        'number',
        { integer = true, min = 50, max = 500 },
        'CameraDistanceName',
        'CameraDistanceDesc',
        120
      ),
      Setting(
        'CameraHeight',
        'number',
        { integer = true, min = -50, max = 100 },
        'CameraHeightName',
        'CameraHeightDesc',
        25
      ),
      Setting(
        'CameraSideOffset',
        'number',
        { integer = true, min = 0, max = 200 },
        'CameraSideOffsetName',
        'CameraSideOffsetDesc',
        90
      ),
      Setting(
        'CameraMinDistance',
        'number',
        { integer = true, min = 15, max = 200 },
        'CameraMinDistanceName',
        'CameraMinDistanceDesc',
        30
      ),
      Setting(
        'CameraResponsiveness',
        'number',
        { integer = true, min = 1, max = 30 },
        'CameraResponsivenessName',
        'CameraResponsivenessDesc',
        6
      ),
      Setting(
        'CameraLookResponsiveness',
        'number',
        { integer = true, min = 1, max = 30 },
        'CameraLookResponsivenessName',
        'CameraLookResponsivenessDesc',
        8
      ),
      Setting(
        'CameraLookBias',
        'number',
        { integer = true, min = 0, max = 100 },
        'CameraLookBiasName',
        'CameraLookBiasDesc',
        80
      ),

      Setting(
        'TargetMinSize',
        'number',
        { min = 0, max = 64, integer = true },
        'TargetMinSizeName',
        'TargetMinSizeDesc',
        32
      ),
      Setting(
        'TargetMinDistance',
        'number',
        { min = 0, max = 512, integer = true },
        'TargetMinDistanceName',
        'TargetMinDistanceDesc',
        256
      ),
      Setting(
        'TargetMaxSize',
        'number',
        { min = 0, max = 128, integer = true },
        'TargetMaxSizeName',
        'TargetMaxSizeDesc',
        128
      ),
      Setting(
        'TargetMaxDistance',
        'number',
        { min = 512, max = 7128, integer = true },
        'TargetMaxDistanceName',
        'TargetMaxDistanceDesc',
        3564
      ),
      Setting(
        'TargetLockIcon',
        'select',
        { items = iconNames, l10n = ModInfo.l10nName },
        'TargetLockIconName',
        'TargetLockIconDesc',
        'starburst'
      ),
      Setting(
        'TargetColorF',
        'color',
        {},
        'TargetColorFName',
        'TargetColorFDesc',
        HexColor '0df8cc'
      ),
      Setting(
        'TargetColorVH',
        'color',
        {},
        'TargetColorVHName',
        'TargetColorVHDesc',
        HexColor '069e00'
      ),
      Setting(
        'TargetColorH',
        'color',
        {},
        'TargetColorHName',
        'TargetColorHDesc',
        HexColor '047a00'
      ),
      Setting(
        'TargetColorW',
        'color',
        {},
        'TargetColorWName',
        'TargetColorWDesc',
        HexColor '9e7100'
      ),
      Setting(
        'TargetColorVW',
        'color',
        {},
        'TargetColorVWName',
        'TargetColorVWDesc',
        HexColor '4c3700'
      ),
      Setting(
        'TargetColorD',
        'color',
        {},
        'TargetColorDName',
        'TargetColorDDesc',
        HexColor '4c0000'
      ),
    },
  }

  local settingNames = {
    'TargetLockIcon',
    'SwitchOnDeadTarget',
    'FlickSwitchDistance',
    'EnableFlickSwitch',
    'TargetColorF',
    'TargetColorVH',
    'TargetColorH',
    'TargetColorW',
    'TargetColorVW',
    'TargetColorD',
    'CameraDistance',
    'CameraHeight',
    'CameraSideOffset',
    'CameraMinDistance',
    'CameraResponsiveness',
    'CameraLookResponsiveness',
    'CameraLookBias',
  }

  local LockOnGroup = require('openmw.storage').playerSection(ModInfo.groupName)
  LockOnGroup:subscribe(require('openmw.async'):callback(function(_, _)
    local minSize, maxSize = LockOnGroup:get 'TargetMinSize', LockOnGroup:get 'TargetMaxSize'

    local minDistance, maxDistance =
      LockOnGroup:get 'TargetMinDistance', LockOnGroup:get 'TargetMaxDistance'

    local disabled = not LockOnGroup:get 'TargetLockToggle'

    I.Settings.updateRendererArgument(
      ModInfo.groupName,
      'TargetMinSize',
      { max = (maxSize - 1), disabled = disabled }
    )

    I.Settings.updateRendererArgument(
      ModInfo.groupName,
      'TargetMaxSize',
      { min = minSize + 1, disabled = disabled }
    )

    I.Settings.updateRendererArgument(
      ModInfo.groupName,
      'TargetMinDistance',
      { max = (maxDistance - 1), disabled = disabled }
    )

    I.Settings.updateRendererArgument(
      ModInfo.groupName,
      'TargetMaxDistance',
      { min = minDistance + 1, disabled = disabled }
    )

    for i = 1, #settingNames do
      local settingName = settingNames[i]

      if settingName == 'TargetLockIcon' then
        I.Settings.updateRendererArgument(
          ModInfo.groupName,
          settingName,
          { disabled = disabled, items = iconNames, l10n = ModInfo.l10nName }
        )
      else
        I.Settings.updateRendererArgument(ModInfo.groupName, settingName, { disabled = disabled })
      end
    end
  end))
end
