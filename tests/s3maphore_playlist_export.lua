local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_export%.lua$' or '.'
package.path = root
  .. '/content/s3maphore/00 Core/?.lua;'
  .. root
  .. '/content/s3maphore/00 Core/?/init.lua;'
  .. package.path

local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local export = require 'scripts.s3.music.playlistExport'
local condition = PlaylistConditions.serialize(PlaylistConditions.all {
  PlaylistConditions.rule('cellNameExact', { 'Balmora' }),
  PlaylistConditions.not_(PlaylistConditions.state('cellIsExterior', 'eq', true)),
})
local text = export('user/exported', {
  kind = 'user',
  properties = {
    priority = 700,
    tracks = { 'music/one.mp3', 'music/two.mp3' },
    randomize = true,
    deactivateAfterEnd = true,
  },
  condition = condition,
})
assert(text:find('return {', 1, true))
assert(text:find('id = "user/exported"', 1, true))
assert(text:find('isValidCallback = function()', 1, true))
assert(text:find('Playback.rules.cellNameExact', 1, true))
assert(not text:find('editorVersion', 1, true))
assert(not text:find('ast =', 1, true))

local chunk, err = loadstring(text)
assert(chunk, err)
local environment = {
  Playback = {
    state = { cellIsExterior = false, cellName = 'Balmora' },
    rules = { cellNameExact = function(names) return names.balmora == true end },
  },
}
setfenv(chunk, environment)
local playlist = chunk()[1]
assert(playlist.id == 'user/exported')
assert(playlist.tracks[1] == 'music/one.mp3' and playlist.tracks[2] == 'music/two.mp3')
assert(playlist.deactivateAfterEnd == true)
assert(playlist.isValidCallback() == true)

local escapedValue = table.concat {
  'quote " slash \\ comma, newline',
  string.char(10),
  'tab',
  string.char(9),
  'nul',
  string.char(0),
  'controls',
  string.char(1, 31),
}
local escapedExport = export('user/escaped', {
  kind = 'user',
  properties = { priority = 700, tracks = { 'music/escaped.mp3' } },
  condition = PlaylistConditions.serialize(
    PlaylistConditions.rule('cellNameExact', { escapedValue })
  ),
})
local escapedExportChunk, escapedExportError = loadstring(escapedExport)
assert(escapedExportChunk, escapedExportError)
setfenv(escapedExportChunk, {
  Playback = {
    state = {},
    rules = { cellNameExact = function(names) return names[escapedValue] end },
  },
})
assert(escapedExportChunk()[1].isValidCallback() == true, 'escaped export did not execute')

local opaque = {
  kind = 'override',
  source = 'source.lua',
  properties = {},
}
local ok, message = pcall(export, 'source/opaque', opaque, {
  playlist = { id = 'source/opaque', priority = 900, isValidCallback = function() end },
})
assert(not ok and tostring(message):find('opaque', 1, true))

print 'S3maphore playlist export torture tests passed'
