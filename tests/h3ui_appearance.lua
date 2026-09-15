local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_appearance%.lua$' or '.'

package.path = root .. '/content/h3lp_yours3lf/?.lua;' .. package.path

local contentFiles = { ['StarwindRemasteredV1.15.esm'] = true }
local values = {}
local customValues = {}
local subscriber
local timers = {}
local requestedSections = {}

package.preload['openmw.async'] = function()
  return {
    callback = function(_, callback) return callback end,
    newUnsavableSimulationTimer = function(_, _, callback) timers[#timers + 1] = callback end,
  }
end

package.preload['openmw.core'] = function()
  return {
    contentFiles = {
      has = function(name) return contentFiles[name] == true end,
    },
  }
end

package.preload['openmw.storage'] = function()
  local function newSection(data, onSet)
    local section = {
      get = function(_, key) return data[key] end,
      asTable = function()
        local copy = {}
        for key, value in next, data do
          copy[key] = value
        end
        return copy
      end,
      set = function(_, key, value)
        data[key] = value
        if onSet then onSet(section, key) end
      end,
      subscribe = function(_, callback)
        if onSet then subscriber = callback end
      end,
    }
    return section
  end

  local section = newSection(values, function(section, key)
    if subscriber then subscriber(section, key) end
  end)
  local customSection = newSection(customValues)

  return {
    playerSection = function(name)
      requestedSections[name] = true
      if name == 'SettingsPlayerH3UICustom' then return customSection end
      return section
    end,
  }
end

package.preload['openmw.util'] = function()
  return {
    color = {
      hex = function(hex)
        local color = newproxy(true)
        getmetatable(color).__index = { asHex = function() return hex end }
        return color
      end,
    },
  }
end

local appearance = require 'scripts.s3.ui.appearance'
local themeModule = require 'scripts.s3.ui.theme'

local function flushTimers()
  while #timers > 0 do
    local callback = table.remove(timers, 1)
    callback()
  end
end

local registry = {}
local morrowind = themeModule.new({
  name = 'Morrowind',
  tokens = {
    color = {
      text = 'caa560',
      active = '6070ca',
      header = 'dfc99f',
      misc = '00cdcd',
      bigAnswerPressed = 'f3ed16',
    },
  },
}, registry)
local starwind = themeModule.new({
  name = 'Starwind',
  tokens = { color = { text = '22affb', header = '80fff5', active = '22affb', misc = '22affb' } },
}, registry, morrowind)

appearance.initialize(registry, {
  { id = 'morrowind', spec = { name = 'Morrowind' }, theme = morrowind },
  { id = 'starwind', spec = { name = 'Starwind' }, theme = starwind },
})

assert(requestedSections.SettingsPlayerH3UI)
assert(requestedSections.SettingsPlayerH3UICustom)
assert(appearance.currentThemeId() == 'starwind')
assert(values.theme == 'starwind')
assert(values.text == '22affb')
assert(appearance.activeTheme().token('color.text'):asHex() == '22affb')
assert(appearance.activeTheme().token('color.active'):asHex() == '22affb')
assert(appearance.activeTheme().token('color.misc'):asHex() == '22affb')
assert(values.menuTransparency == 0.84)
assert(appearance.activeTheme().token 'transparency.menu' == 0.84)
assert(values.textSizeNormal == 16)
assert(values.textSizeHeader == 18)
assert(appearance.activeTheme().token 'textSize.normal' == 16)
assert(appearance.activeTheme().token 'textSize.header' == 18)

appearance.selectTheme 'custom'
assert(values.theme == 'custom')
assert(values.text == 'caa560')
assert(values.header == 'dfc99f')
assert(customValues.text == 'caa560')

appearance.setColor('text', '123456')
assert(values.theme == 'custom')
assert(appearance.activeTheme().token('color.text'):asHex() == '123456')
assert(appearance.activeTheme().token('color.header'):asHex() == 'dfc99f')

appearance.selectTheme 'starwind'
flushTimers()
assert(values.theme == 'starwind')
assert(values.text == '22affb')
assert(customValues.text == '123456')

appearance.selectTheme 'custom'
assert(values.theme == 'custom')
assert(values.text == '123456')
assert(values.header == 'dfc99f')

values.menuTransparency = 1.5
subscriber(nil, 'menuTransparency')
assert(appearance.activeTheme().token 'transparency.menu' == 1)
values.textSizeNormal = 24
subscriber(nil, 'textSizeNormal')
assert(appearance.activeTheme().token 'textSize.normal' == 24)

appearance.reset()
assert(values.theme == 'morrowind')
assert(values.text == 'caa560')
assert(values.menuTransparency == 0.84)
assert(values.textSizeNormal == 16)
assert(values.textSizeHeader == 18)
assert(customValues.text == '123456')

values.theme = 'starwind'
subscriber(nil, 'theme')
values.text = '22affb'
subscriber(nil, 'text')
flushTimers()
assert(values.theme == 'starwind')
assert(values.text == '22affb')
assert(customValues.text == '123456')

appearance.selectTheme 'custom'
assert(values.theme == 'custom')
assert(values.text == '123456')

values.theme = 'morrowind'
subscriber(nil, 'theme')
assert(values.text == '123456')
flushTimers()
assert(values.text == 'caa560')
assert(values.header == 'dfc99f')
assert(appearance.activeTheme().token('color.active'):asHex() == '6070ca')
assert(appearance.activeTheme().token('color.misc'):asHex() == '00cdcd')
assert(appearance.activeTheme().token('color.bigAnswerPressed'):asHex() == 'f3ed16')

appearance.selectTheme 'starwind'
flushTimers()
assert(values.theme == 'starwind')
assert(values.text == '22affb')

values.theme = 'missing-theme'
subscriber(nil, 'theme')
assert(appearance.currentThemeId() == 'starwind')
assert(values.theme == 'missing-theme')

appearance.registerTheme {
  id = 'example:night',
  name = 'Night',
  extends = 'starwind',
  tokens = { color = { text = '010203' } },
}
assert(#appearance.themeEntries() == 3)

print 'H3UI appearance tests passed'
