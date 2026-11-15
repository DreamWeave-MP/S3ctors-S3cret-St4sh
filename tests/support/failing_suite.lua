---@omw-context none

local StrFormat = string.format

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/support/failing_suite%.lua$' or '.'

package.path = StrFormat('%s/content/h3lp_yours3lf/?.lua;%s', root, package.path)

local Runtime = require 'scripts.h3.runtime'

assert(Runtime.isLuau == Runtime.isLuaJIT)
