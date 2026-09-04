local function loadPlugin()
  dofile 'content/cod3x/omw_context_plugin.lua'
end

local function diffs(text)
  return OnSetText('file:///tmp/omw-context-plugin-test.lua', text) or {}
end

local function assertDiffCount(text, expected)
  local result = diffs(text)
  assert(#result == expected, ('expected %d diffs, got %d'):format(expected, #result))
  return result
end

loadPlugin()

local result = assertDiffCount([=[---@omw-context local
local quoted = "require('openmw.camera')"
local actual = require 'openmw.camera'
]=], 1)
assert(result[1].text:find '__OMW_CONTEXT_ERROR_local_cannot_require_openmw_camera__', 1, true)

assertDiffCount([=[---@omw-context local
local quoted = [[require 'openmw.camera']]
]=], 0)

assertDiffCount([=[---@omw-context local
--[[
local commented = require 'openmw.camera'
]]
]=], 0)

result = assertDiffCount([=[local quoted = "---@omw-context none"
local actual = require 'openmw.camera'
]=], 2)
assert(result[1].start > 1)
assert(result[2].start == 1 and result[2].finish == 0)

result = assertDiffCount([=[---@omw-context global
local storage = require 'openmw.storage'
local quoted = "storage.playerSection"
local actual = storage.playerSection()
]=], 2)
assert(result[2].text:find 'cannot_use_openmw_storage_playerSection', 1, true)

result = OnSetText(
  'file:///tmp/omw-context-interface/global.lua',
  [=[---@omw-context global
local I = require 'openmw.interfaces'
]=]
)
assert(result[1].text:find '---@cast I openmw.interfaces.Global', 1, true)

result = OnSetText(
  'file:///tmp/omw-context-interface/local.lua',
  [=[---@omw-context local
local I = require 'openmw.interfaces'
]=]
)
assert(result[1].text:find '---@cast I openmw.interfaces.Local', 1, true)

result = OnSetText(
  'file:///tmp/omw-context-interface/player.lua',
  [=[---@omw-context player
local I = require 'openmw.interfaces'
]=]
)
assert(result[1].text:find '---@cast I openmw.interfaces.Player', 1, true)

local function assertOnlyCast(context, expected)
  local diffs = OnSetText(
    'file:///tmp/omw-context-interface/' .. context .. '-cast.lua',
    '---@omw-context ' .. context .. '\nlocal interfaces = require \'openmw.interfaces\'\n'
  )
  assert(#diffs == 1, ('expected one cast for %s, got %d'):format(context, #diffs))
  assert(diffs[1].text == '---@cast interfaces ' .. expected .. '\n')
end

assertOnlyCast('global', 'openmw.interfaces.Global')
assertOnlyCast('local', 'openmw.interfaces.Local')
assertOnlyCast('player', 'openmw.interfaces.Player')
assertOnlyCast('menu', 'openmw.interfaces.Menu')
assertOnlyCast('global|player', 'openmw.interfaces.Global|openmw.interfaces.Player')
assertOnlyCast('runtime', 'openmw.interfaces.Global|openmw.interfaces.Local|openmw.interfaces.Player|openmw.interfaces.Menu')

result = OnSetText(
  'file:///tmp/omw-context-interface/all.lua',
  '---@omw-context all\nlocal interfaces = require \'openmw.interfaces\'\n'
)
assert(#result == 1)
assert(result[1].text:find 'all_cannot_require_openmw_interfaces', 1, true)

result = OnSetText(
  'file:///tmp/omw-context-interface/direct.lua',
  [=[---@omw-context global
local activation = require('openmw.interfaces').Activation
local camera = require 'openmw.interfaces'.Camera
]=]
)
assert(#result == 1)
assert(result[1].text:find 'global_cannot_use_openmw_interfaces_Camera', 1, true)

local cachedUri = 'file:///tmp/omw-context-interface/cache.lua'
OnSetText(cachedUri, '---@omw-context global\nlocal camera = require \'openmw.camera\'\n')
local resolution = ResolveRequire(nil, 'openmw.camera', cachedUri)
assert(resolution ~= nil and next(resolution) == nil)
OnSetText(cachedUri, '---@omw-context player\nlocal camera = require \'openmw.camera\'\n')
assert(ResolveRequire(nil, 'openmw.camera', cachedUri) == nil)
assert(ResolveRequire(nil, 'openmw/camera', cachedUri) == nil)

local metaUri = 'file:///tmp/omw-context-interface/meta.lua'
OnSetText(metaUri, '---@meta\nlocal camera = require \'openmw.camera\'\n')
assert(ResolveRequire(nil, 'openmw.camera', metaUri) == nil)

local cod3xUri = 'file:///tmp/content/cod3x/internal.lua'
OnSetText(cod3xUri, 'local camera = require \'openmw.camera\'\n')
assert(ResolveRequire(nil, 'openmw.camera', cod3xUri) == nil)
