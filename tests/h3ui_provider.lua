---@omw-context none

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_provider%.lua$' or '.'

package.path = root .. '/content/h3lp_yours3lf/?.lua;' .. package.path

local H3UI = {}
local settingsLoaded = false
local registerActionsCalls = 0
local registerCalls = 0

local Input = {
  registerActions = function() registerActionsCalls = registerActionsCalls + 1 end,
}

local InputPage = {
  onControllerButtonPress = function() end,
  onKeyPress = function() end,
  onMouseButtonPress = function() end,
  register = function()
    registerCalls = registerCalls + 1
    Input.registerActions()
  end,
}

package.preload['scripts.h3.ui'] = function() return H3UI end
package.preload['scripts.h3.settings'] = function()
  settingsLoaded = true
  return {}
end
package.preload['scripts.h3.input'] = function() return Input end
package.preload['scripts.h3.inputPage'] = function() return InputPage end
package.preload['openmw.menu'] = function() return {} end

local Provider = require 'scripts.h3.provider'
assert(settingsLoaded)
assert(Provider.interfaceName == 'H3UI')
assert(Provider.interface == H3UI)
assert(type(Provider.engineHandlers.onFrame) == 'function')
assert(registerCalls == 1)
assert(registerActionsCalls == 1)
assert(Provider.engineHandlers.onControllerButtonPress == InputPage.onControllerButtonPress)
assert(Provider.engineHandlers.onKeyPress == InputPage.onKeyPress)
assert(Provider.engineHandlers.onMouseButtonPress == InputPage.onMouseButtonPress)

local updateQueue = require 'scripts.h3.ui.updateQueue'
local updates = 0
local Element = { layout = {}, update = function() updates = updates + 1 end }
updateQueue.queue { pending = false, resolveElement = function() return Element end }
Provider.engineHandlers.onFrame()
assert(updates == 1)

package.loaded['scripts.h3.provider'] = nil
package.loaded['scripts.s3.scriptContext'] = nil
package.loaded['openmw.menu'] = nil
package.preload['openmw.menu'] = nil
package.preload['openmw.types'] = function()
  return { Player = { objectIsInstance = function() return true end } }
end
package.preload['openmw.self'] = function() return {} end

settingsLoaded = false
registerActionsCalls = 0
registerCalls = 0
Provider = require 'scripts.h3.provider'
assert(not settingsLoaded)
assert(Provider.interface == H3UI)
assert(type(Provider.engineHandlers.onFrame) == 'function')
assert(registerCalls == 0)
assert(registerActionsCalls == 1)
assert(Provider.engineHandlers.onControllerButtonPress == nil)
assert(Provider.engineHandlers.onKeyPress == nil)
assert(Provider.engineHandlers.onMouseButtonPress == nil)

print 'H3UI provider tests passed'
