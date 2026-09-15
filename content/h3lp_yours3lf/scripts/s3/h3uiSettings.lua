---@omw-context menu
---@module 'scripts.s3.h3uiSettings'

require 'scripts.s3.ui'
local appearance = require 'scripts.s3.ui.appearance'

local settings = require('openmw.interfaces').Settings
appearance.currentThemeId()
local palette = appearance.morrowindPalette()

settings.registerPage {
  key = 'H3UI',
  l10n = 'H3',
  name = 'H3UIPageName',
  description = 'H3UIPageDescription',
}

local colorSettings = {}
for index = 1, #appearance.colorKeys do
  local key = appearance.colorKeys[index]
  colorSettings[#colorSettings + 1] = {
    key = key,
    renderer = 'H3UIColor',
    argument = { key = key },
    name = 'H3UIColor_' .. key .. '_Name',
    default = palette[key],
  }
end

local settingsList = {
  {
    key = 'theme',
    renderer = 'H3UITheme',
    name = 'H3UIThemeName',
    description = 'H3UIThemeDescription',
    default = 'morrowind',
  },
  {
    key = 'menuTransparency',
    renderer = 'number',
    argument = { min = 0.0, max = 1.0, integer = false },
    name = 'H3UIMenuTransparencyName',
    description = 'H3UIMenuTransparencyDescription',
    default = appearance.defaultMenuTransparency,
  },
  {
    key = 'textSizeNormal',
    renderer = 'number',
    argument = { min = 1, max = 100, integer = true },
    name = 'H3UITextSizeNormalName',
    description = 'H3UITextSizeNormalDescription',
    default = appearance.defaultNormalTextSize,
  },
  {
    key = 'textSizeHeader',
    renderer = 'number',
    argument = { min = 1, max = 100, integer = true },
    name = 'H3UITextSizeHeaderName',
    description = 'H3UITextSizeHeaderDescription',
    default = appearance.defaultHeaderTextSize,
  },
}

for index = 1, #colorSettings do
  settingsList[#settingsList + 1] = colorSettings[index]
end

settingsList[#settingsList + 1] = {
  key = 'enableDebugHotkeys',
  renderer = 'checkbox',
  name = 'H3UIDebugHotkeysName',
  description = 'H3UIDebugHotkeysDescription',
  default = false,
}

settingsList[#settingsList + 1] = {
  key = 'reset',
  renderer = 'H3UIReset',
  name = 'H3UIResetName',
  description = 'H3UIResetDescription',
  default = false,
}

settings.registerGroup {
  key = 'SettingsPlayerH3UI',
  page = 'H3UI',
  l10n = 'H3',
  name = 'H3UIAppearanceName',
  description = 'H3UIAppearanceDescription',
  permanentStorage = true,
  settings = settingsList,
}
