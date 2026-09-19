local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_provider%.lua$' or '.'

package.path = root .. '/content/h3lp_yours3lf/?.lua;' .. package.path

local H3UI = {}
local settingsLoaded = false

package.preload['scripts.s3.ui'] = function() return H3UI end
package.preload['scripts.s3.h3uiSettings'] = function()
  settingsLoaded = true
  return {}
end
package.preload['openmw.menu'] = function() return {} end

local provider = require 'scripts.s3.h3uiProvider'
assert(settingsLoaded)
assert(provider.interfaceName == 'H3UI')
assert(provider.interface == H3UI)
assert(type(provider.engineHandlers.onFrame) == 'function')

local updateQueue = require 'scripts.s3.ui.updateQueue'
local updates = 0
local element = { layout = {}, update = function() updates = updates + 1 end }
updateQueue.queue { pending = false, resolveElement = function() return element end }
provider.engineHandlers.onFrame()
assert(updates == 1)

package.loaded['scripts.s3.h3uiProvider'] = nil
package.loaded['scripts.s3.scriptContext'] = nil
package.loaded['openmw.menu'] = nil
package.preload['openmw.menu'] = nil
package.preload['openmw.types'] = function()
  return { Player = { objectIsInstance = function() return true end } }
end
package.preload['openmw.self'] = function() return {} end

settingsLoaded = false
provider = require 'scripts.s3.h3uiProvider'
assert(not settingsLoaded)
assert(provider.interface == H3UI)
assert(type(provider.engineHandlers.onFrame) == 'function')

print 'H3UI provider tests passed'
