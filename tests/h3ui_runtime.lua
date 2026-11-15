---@omw-context none

local StrFormat = string.format

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_runtime%.lua$' or '.'

package.path = StrFormat('%s/content/h3lp_yours3lf/?.lua;%s', root, package.path)

local Runtime = require 'scripts.h3.runtime'

---@diagnostic disable-next-line: undefined-global
local HasTypeof = typeof ~= nil

assert(Runtime.isLuau == HasTypeof)
assert(Runtime.isLuaJIT == not HasTypeof)

print 'H3UI runtime tests passed'
