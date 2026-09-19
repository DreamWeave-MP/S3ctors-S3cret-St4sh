---@omw-context menu
---@module 'scripts.h3.settings'

local I = require 'openmw.interfaces'

require 'scripts.h3.ui'
local appearance = require 'scripts.h3.ui.appearance'

local StrFormat = string.format

local Settings = I.Settings

appearance.currentThemeId()
local Palette = appearance.morrowindPalette()

Settings.registerPage {
  key = 'H3UI',
  l10n = 'H3',
  name = 'H3UIPageName',
  description = 'H3UIPageDescription',
}

local ColorSettings = {}
for index = 1, #appearance.colorKeys do
  local key = appearance.colorKeys[index]

  ColorSettings[#ColorSettings + 1] = {
    key = key,
    renderer = 'H3UIColor',
    argument = { key = key },
    name = StrFormat('H3UIColor_%s_Name', key),
    default = Palette[key],
  }
end

local SettingsList = {
  {
    key = 'theme',
    renderer = 'H3UITheme',
    name = 'H3UIThemeName',
    description = 'H3UIThemeDescription',
    default = 'morrowind',
  },

  {
    key = 'chromeSource',
    renderer = 'H3UIChromeSource',
    name = 'H3UIChromeSourceName',
    description = 'H3UIChromeSourceDescription',
    default = appearance.defaultChromeSource,
  },

  {
    key = 'chromeMaterialFamily',
    renderer = 'H3UIMaterialFamily',
    name = 'H3UIChromeMaterialFamilyName',
    description = 'H3UIChromeMaterialFamilyDescription',
    default = appearance.defaultMaterialFamily,
  },

  {
    key = 'chromeMaterial',
    renderer = 'H3UIMaterial',
    name = 'H3UIChromeMaterialName',
    description = 'H3UIChromeMaterialDescription',
    default = appearance.defaultMaterial,
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
    key = 'chromeTransparency',
    renderer = 'number',
    argument = { min = 0.0, max = 1.0, integer = false },
    name = 'H3UIChromeTransparencyName',
    description = 'H3UIChromeTransparencyDescription',
    default = appearance.defaultChromeTransparency,
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

for index = 1, #ColorSettings do
  SettingsList[#SettingsList + 1] = ColorSettings[index]
end

SettingsList[#SettingsList + 1] = {
  key = 'enableDebugHotkeys',
  renderer = 'checkbox',
  name = 'H3UIDebugHotkeysName',
  description = 'H3UIDebugHotkeysDescription',
  default = false,
}

SettingsList[#SettingsList + 1] = {
  key = 'reset',
  renderer = 'H3UIReset',
  name = 'H3UIResetName',
  description = 'H3UIResetDescription',
  default = false,
}

Settings.registerGroup {
  key = 'SettingsPlayerH3UI',
  page = 'H3UI',
  l10n = 'H3',
  name = 'H3UIAppearanceName',
  description = 'H3UIAppearanceDescription',
  permanentStorage = true,
  settings = SettingsList,
}
