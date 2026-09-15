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

print 'H3UI provider tests passed'
