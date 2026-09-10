local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_registration%.lua$' or '.'

package.path = table.concat({
  root .. '/content/h3lp_yours3lf/?.lua',
  root .. '/content/s3maphore/00 Core/?.lua',
  package.path,
}, ';')

local PlaylistPriority = require 'doc.playlistPriority'
local util = require 'scripts.s3.music.util'
local INTERRUPT = {
  Me = 0,
  Other = 1,
  Never = 2,
  Override = 3,
}

local function makePlaylist(priority, interruptMode)
  return {
    id = 'test/' .. tostring(priority),
    priority = priority,
    interruptMode = interruptMode,
    tracks = { 'music/test.mp3' },
    isValidCallback = function() return true end,
  }
end

local function assertDefaultInterruptMode(priority, expected)
  local playlist = makePlaylist(priority)
  assert(util.initMissingPlaylistFields(playlist, INTERRUPT) == nil)
  assert(playlist.interruptMode == expected)
end

local function assertRegistrationError(priority, interruptMode, message)
  local ok, err =
    pcall(util.initMissingPlaylistFields, makePlaylist(priority, interruptMode), INTERRUPT)
  assert(not ok)
  assert(tostring(err):find(message, 1, true), tostring(err))
end

assertDefaultInterruptMode(PlaylistPriority.Special, INTERRUPT.Never)
assertDefaultInterruptMode(PlaylistPriority.BattleVanilla, INTERRUPT.Other)
assertDefaultInterruptMode(PlaylistPriority.Explore, INTERRUPT.Me)

local neverPlaylist = makePlaylist(PlaylistPriority.Never, INTERRUPT.Me)
assert(util.initMissingPlaylistFields(neverPlaylist, INTERRUPT) == nil)
assert(neverPlaylist.interruptMode == INTERRUPT.Me)

assertRegistrationError(PlaylistPriority.Never, nil, 'requires an explicit interruptMode')
assertRegistrationError(
  PlaylistPriority.Explore + 1,
  INTERRUPT.Me,
  'above PlaylistPriority.Explore'
)
assertRegistrationError(PlaylistPriority.Explore, -1, 'invalid interruptMode')
assertRegistrationError(PlaylistPriority.Explore, 4, 'invalid interruptMode')
assertRegistrationError(PlaylistPriority.Explore, 'Me', 'invalid interruptMode')
assertRegistrationError(PlaylistPriority.Explore, {}, 'invalid interruptMode')
assertRegistrationError(PlaylistPriority.Explore, false, 'invalid interruptMode')

assert(
  util.makeTracksSignature({ 'a', 'b' }, false) ~= util.makeTracksSignature({ 'x', 'y' }, false)
)
assert(
  util.makeTracksSignature({ 'a', 'b' }, false) ~= util.makeTracksSignature({ 'b', 'a' }, false)
)
assert(
  util.makeTracksSignature({ 'a', 'b' }, false) ~= util.makeTracksSignature({ 'a', 'b' }, true)
)

local emptyIdPlaylist = makePlaylist(PlaylistPriority.Explore, INTERRUPT.Me)
emptyIdPlaylist.id = ''
local ok, err = pcall(util.initMissingPlaylistFields, emptyIdPlaylist, INTERRUPT)
assert(not ok)
assert(tostring(err):find('must not be empty', 1, true), tostring(err))

print 'S3maphore playlist registration tests passed'
