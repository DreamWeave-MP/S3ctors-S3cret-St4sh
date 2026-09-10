local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_state_scope%.lua$' or '.'

package.path = table.concat({
  root .. '/content/s3maphore/00 Core/?.lua',
  package.path,
}, ';')

local presenceCallback
local storedPresence
local events = {}
local musicSettings = { ScanAdjacentExteriorCells = true }
local presenceSection = {}

function presenceSection:get() return storedPresence end
function presenceSection:subscribe(callback) presenceCallback = callback end

local gameSelf = {
  id = 'player',
  cell = { id = 'exterior', isExterior = true },
}
function gameSelf:sendEvent(name, data) events[#events + 1] = { name = name, data = data } end

package.preload['openmw.self'] = function() return gameSelf end
package.preload['openmw.async'] = function()
  local async = {}
  function async:callback(callback) return callback end
  return async
end
package.preload['openmw.storage'] = function()
  return { globalSection = function() return presenceSection end }
end
package.preload['scripts.s3.music.musicSettings'] = function() return musicSettings end

local PlaylistState = require 'scripts.s3.music.playlistState'

local function readOnlyMap(values)
  return setmetatable({}, {
    __newindex = function() error 'read-only storage proxy' end,
    __pairs = function() return next, values, nil end,
  })
end

local aggregate = {
  byRecord = { ['neighbor/object'] = 2 },
  byType = readOnlyMap { Static = 2 },
  byContentFile = { ['neighbor.esm'] = 2 },
  staticContentFiles = { 'neighbor.esm' },
}
local center = {
  byRecord = { ['center/object'] = 1 },
  byType = readOnlyMap { Static = 1 },
  byContentFile = { ['center.esm'] = 1 },
  staticContentFiles = { 'center.esm' },
}

storedPresence = {
  cellId = 'exterior',
  generation = 7,
  byRecord = aggregate.byRecord,
  byType = aggregate.byType,
  byContentFile = aggregate.byContentFile,
  staticContentFiles = aggregate.staticContentFiles,
  currentExteriorCellObjects = center,
  cellHasHostileActors = false,
  areaHasHostileActors = true,
}

presenceCallback(nil, 'player')
assert(
  PlaylistState.objectsByRecord == aggregate.byRecord,
  'default scope must use aggregate records'
)
assert(PlaylistState.objectsByType == aggregate.byType, 'default scope must use aggregate types')
assert(
  PlaylistState.objectsByContentFile == aggregate.byContentFile,
  'default scope must use aggregate files'
)
assert(
  PlaylistState.staticObjectContentFiles == aggregate.staticContentFiles,
  'default scope must use aggregate statics'
)
assert(PlaylistState.objectCount == 2, 'default scope object count')
assert(#events == 1 and events[1].name == 'S3maphoreCellPresenceUpdated', 'presence event')

PlaylistState.refreshObjectPresenceScope(false)
assert(PlaylistState.objectsByRecord == center.byRecord, 'current-cell scope records')
assert(PlaylistState.objectsByType == center.byType, 'current-cell scope types')
assert(PlaylistState.objectsByContentFile == center.byContentFile, 'current-cell scope files')
assert(
  PlaylistState.staticObjectContentFiles == center.staticContentFiles,
  'current-cell scope statics'
)
assert(PlaylistState.objectCount == 1, 'current-cell scope object count')

PlaylistState.refreshObjectPresenceScope(true)
assert(PlaylistState.objectsByRecord == aggregate.byRecord, 're-enabled aggregate records')
assert(PlaylistState.objectCount == 2, 're-enabled aggregate object count')

musicSettings.ScanAdjacentExteriorCells = false
gameSelf.cell = { id = 'exterior', isExterior = true }
presenceCallback(nil, 'player')
assert(PlaylistState.objectsByRecord == center.byRecord, 'live setting disables adjacent scan')
assert(PlaylistState.objectCount == 1, 'live setting center object count')

musicSettings.ScanAdjacentExteriorCells = true
presenceCallback(nil, 'player')
assert(PlaylistState.objectsByRecord == aggregate.byRecord, 'live setting enables adjacent scan')
assert(PlaylistState.objectCount == 2, 'live setting aggregate object count')

gameSelf.cell = { id = 'interior', isExterior = false }
PlaylistState.refreshObjectPresenceScope(false)
assert(
  PlaylistState.objectsByRecord == aggregate.byRecord,
  'interior scope remains current-cell aggregate'
)
assert(PlaylistState.objectCount == 2, 'interior object count')

storedPresence.cellId = 'stale'
local eventCount = #events
presenceCallback(nil, 'player')
assert(PlaylistState.objectsByRecord == aggregate.byRecord, 'stale presence must be ignored')
assert(#events == eventCount, 'stale presence must not emit an update event')

print 'S3maphore playlist state scope tests passed'
