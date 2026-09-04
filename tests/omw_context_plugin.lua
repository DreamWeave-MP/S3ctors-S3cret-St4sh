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
