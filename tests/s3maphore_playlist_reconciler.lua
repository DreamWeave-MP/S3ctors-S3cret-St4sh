local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_reconciler%.lua$' or '.'
package.path = root
  .. '/content/s3maphore/00 Core/?.lua;'
  .. root
  .. '/content/s3maphore/00 Core/?/init.lua;'
  .. package.path

local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local PlaylistReconciler = require 'scripts.s3.music.playlistReconciler'
local registered, removed, changed, reports = {}, {}, 0, {}
local playback = { state = { cellIsExterior = true }, rules = {} }
local function prepare(playlist)
  playlist.interruptMode = playlist.interruptMode or 0
  playlist.active = playlist.active == nil and true or playlist.active
end

local function loadCode(code, environment)
  local chunk, err = loadstring(code)
  assert(chunk, err)
  setfenv(chunk, environment)
  return chunk
end
local catalog = PlaylistReconciler.new {
  playback = playback,
  loadCode = loadCode,
  prepare = prepare,
  register = function(p) registered[p.id] = p end,
  remove = function(id)
    registered[id], removed[id] = nil, (removed[id] or 0) + 1
  end,
  changed = function() changed = changed + 1 end,
  report = function(message) reports[#reports + 1] = message end,
}
local condition =
  PlaylistConditions.serialize(PlaylistConditions.state('cellIsExterior', 'eq', true))
local function sourcePlaylist(id, owner, priority)
  return {
    id = id,
    priority = priority or 900,
    active = true,
    tracks = { 'music/a.mp3' },
    isValidCallback = function() return false end,
  }
end

catalog.registerSource(sourcePlaylist 'mod/a', 'mod.lua')
assert(registered['mod/a'].isValidCallback() == false)
assert(catalog.delta('mod/a', catalog.draft 'mod/a') == nil, 'unchanged source became an override')
local beforeChanged = changed
catalog.commit('mod/a', {
  kind = 'override',
  source = 'mod.lua',
  properties = { tracks = { 'music/b.mp3' } },
  condition = condition,
})
assert(registered['mod/a'].isValidCallback() == true)
assert(registered['mod/a'].tracks[1] == 'music/b.mp3')
assert(changed > beforeChanged)
assert(
  catalog.save().entries['mod/a'].properties.active == nil,
  'active leaked into editor persistence'
)
local saved = catalog.save()
local reloaded = PlaylistReconciler.new {
  playback = playback,
  loadCode = loadCode,
  prepare = prepare,
  register = function(p) registered[p.id] = p end,
  remove = function(id) registered[id] = nil end,
}
reloaded.load(saved)
reloaded.registerSource(sourcePlaylist 'mod/a', 'mod.lua')
assert(registered['mod/a'].isValidCallback() == true, 'saved override did not survive reload')

catalog.removeSource 'mod/a'
assert(registered['mod/a'] == nil, 'orphan override was registered')
assert(catalog.save().entries['mod/a'].kind == 'override', 'orphan override was discarded')
local orphanInfo = catalog.info 'mod/a'
assert(orphanInfo and orphanInfo.source == nil, 'orphan source remained visible')
assert(removed['mod/a'] == 1, 'reconciliation removal was not notified')
catalog.registerSource(sourcePlaylist 'mod/a', 'other.lua')
assert(registered['mod/a'].isValidCallback() == false, 'conflicting source received old override')
assert(#reports > 0, 'source conflict was not reported')
catalog.removeSource 'mod/a'
catalog.registerSource(sourcePlaylist 'mod/a', 'mod.lua')
assert(registered['mod/a'].isValidCallback() == true, 'restored source did not restore override')

catalog.commit('user/a', {
  kind = 'user',
  properties = { priority = 1000, tracks = { 'music/u.mp3' } },
  condition = condition,
})
assert(registered['user/a'].isValidCallback() == true)
catalog.commit('user/a', {
  kind = 'user',
  properties = { priority = 190, tracks = { 'music/u.mp3' } },
  condition = condition,
})
assert(registered['user/a'].priority == 190, 'user playlist did not move decks')
assert(removed['user/a'] and removed['user/a'] > 0, 'deck migration did not unregister first')
catalog.removeSource 'user/a'
assert(registered['user/a'] ~= nil, 'user playlist was treated as source-owned')
catalog.delete 'user/a'
assert(registered['user/a'] == nil and catalog.save().entries['user/a'] == nil)

local rollbackRegistered = {}
local rollbackRemoved = {}
local rollbackCatalog = PlaylistReconciler.new {
  playback = playback,
  loadCode = loadCode,
  prepare = prepare,
  register = function(playlist)
    if playlist.priority == 190 then error 'simulated publication failure' end
    rollbackRegistered[playlist.id] = playlist
  end,
  remove = function(id)
    rollbackRegistered[id], rollbackRemoved[id] = nil, true
  end,
}
rollbackCatalog.commit('user/rollback', {
  kind = 'user',
  properties = { priority = 1000, tracks = { 'music/rollback.mp3' } },
  condition = condition,
})
local rollbackOk = pcall(rollbackCatalog.commit, 'user/rollback', {
  kind = 'user',
  properties = { priority = 190, tracks = { 'music/rollback.mp3' } },
  condition = condition,
})
assert(not rollbackOk, 'publication failure unexpectedly succeeded')
assert(
  rollbackRemoved['user/rollback'],
  'failed deck migration did not remove the old runtime playlist'
)
assert(
  rollbackRegistered['user/rollback'].priority == 1000,
  'failed deck migration did not restore the old runtime playlist'
)
assert(
  rollbackCatalog.entry('user/rollback').properties.priority == 1000,
  'failed deck migration did not restore persisted state'
)

local transientPlaylist = sourcePlaylist('mod/a', nil, 900)
transientPlaylist.tracks = { 'music/transient.mp3' }
transientPlaylist.isValidCallback = function() return 'transient' end
catalog.registerTransient(transientPlaylist)
assert(catalog.info('mod/a').transient == true, 'transient registration was not reported')
assert(
  catalog.source('mod/a').owner == 'mod.lua',
  'transient registration erased source provenance'
)
assert(registered['mod/a'].tracks[1] == 'music/transient.mp3')
catalog.reconcile 'mod/a'
assert(
  registered['mod/a'].isValidCallback() == 'transient',
  'reconcile replaced the higher-precedence transient playlist'
)
catalog.registerSource(sourcePlaylist('mod/a', nil, 900), 'mod.lua')
assert(
  registered['mod/a'].isValidCallback() == 'transient',
  'source registration replaced the higher-precedence transient playlist'
)
catalog.commit('mod/a', {
  kind = 'override',
  source = 'mod.lua',
  properties = { tracks = { 'music/persisted.mp3' } },
  condition = condition,
})
assert(
  registered['mod/a'].isValidCallback() == 'transient',
  'committing persistence replaced the transient playlist'
)
assert(
  catalog.save().entries['mod/a'].properties.tracks[1] == 'music/persisted.mp3',
  'transient commit did not update persistence'
)
catalog.delete 'mod/a'
assert(
  registered['mod/a'].isValidCallback() == 'transient',
  'deleting persistence replaced the transient playlist'
)

local oldChanged = changed
catalog.load {
  version = 1,
  entries = { ['broken'] = { kind = 'override', source = 'x', properties = { active = false } } },
}
catalog.finishLoading()
assert(changed > oldChanged, 'invalid entry reconciliation did not notify')
assert(catalog.status().broken ~= nil)
assert(catalog.save().entries.broken ~= nil)
catalog.load {
  version = 1,
  entries = {
    broken = {
      kind = 'user',
      properties = { priority = 1000, tracks = {} },
      condition = { version = 1, root = { kind = 'rule', id = 'removed', args = {} } },
    },
  },
}
catalog.finishLoading()
assert(catalog.status().broken ~= nil, 'malformed AST was not reported')
catalog.load { version = 99, entries = {} }
assert(catalog.save().version == 99, 'unsupported document was not retained')
assert(catalog.status()['$document'] ~= nil)
assert(catalog.documentDiagnostic() ~= nil, 'unsupported document diagnostic was not exposed')

local function loadCoreData(data) catalog.load(data.playlistEditor) end
loadCoreData {
  playlistStates = { ['mod/a'] = false },
  playlistEditor = { version = 1, entries = {} },
}
catalog.registerSource(sourcePlaylist 'mod/a', 'mod.lua')
assert(registered['mod/a'].active == true, 'legacy ID-only activation state was resurrected')

print 'S3maphore playlist reconciler torture tests passed'
