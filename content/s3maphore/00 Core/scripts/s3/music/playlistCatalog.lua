---@module 'doc.s3maphoreTypes'
---@omw-context player
local Manager = require 'scripts.s3.music.musicManager'
local PlaylistPriority = require 'doc.playlistPriority'
local Reconciler = require 'scripts.s3.music.playlistReconciler'
local gameSelf = require 'openmw.self'
local musicUtil = require 'scripts.s3.music.util'
local playback = {
  rules = require('scripts.s3.music.playlistRules').rules,
  state = require 'scripts.s3.music.playlistState',
}
local ready = false
local decks = { Manager.explorePlaylists, Manager.battlePlaylists, Manager.specialPlaylists }
local copy, equals = Reconciler.copy, Reconciler.equals
local catalog = Reconciler.new {
  playback = playback,
  prepare = function(p) musicUtil.initMissingPlaylistFields(p, Manager.INTERRUPT) end,
  register = function(p) Manager.registerPlaylist(p) end,
  remove = Manager.unregisterPlaylist,
  changed = function()
    if not ready then return end
    for i = 1, #decks do
      table.sort(decks[i], Manager.priorityThenRegistration)
    end
    gameSelf:sendEvent('S3maphoreCatalogChanged', {})
  end,
  report = function(message) print('[ S3MAPHORE editor ]: ' .. message) end,
}
local finishLoading, save, draft, info, list, documentDiagnostic =
  catalog.finishLoading,
  catalog.save,
  catalog.draft,
  catalog.info,
  catalog.list,
  catalog.documentDiagnostic
function catalog.finishLoading()
  finishLoading()
  ready = true
end

function catalog.save() return save() end

function catalog.draft(id) return draft(id) end

function catalog.copy(value) return copy(value) end

function catalog.equals(a, b) return equals(a, b) end

function catalog.info(id) return info(id) end

function catalog.documentDiagnostic() return documentDiagnostic() end

function catalog.category(priority)
  if priority <= PlaylistPriority.Special then return 'Special' end
  if priority <= PlaylistPriority.BattleVanilla then return 'Battle' end
  return 'Explore'
end

function catalog.categoryFor(id)
  local record = catalog.info(id)
  if not record then return end

  local transient = record.transientPlaylist
  local source = record.source and record.source.playlist
  local properties = record.entry and record.entry.properties
  local priority = transient and transient.priority
    or source and source.priority
    or type(properties) == 'table' and properties.priority
  return type(priority) == 'number' and catalog.category(priority) or nil
end

function catalog.canEdit(id)
  local info = catalog.info(id)
  return not catalog.documentDiagnostic()
    and info ~= nil
    and not info.transient
    and info.diagnostic == nil
    and (info.source ~= nil or info.entry ~= nil)
end

function catalog.canCreate(id) return not catalog.documentDiagnostic() and catalog.info(id) == nil end

function catalog.rows(category)
  local result = {}
  local records = list()
  for i = 1, #records do
    local record = records[i]
    local source = record.source
    local entry = record.entry
    local transient = record.transientPlaylist
    local orphaned = entry ~= nil and source == nil and transient == nil
    local properties = entry and type(entry) == 'table' and entry.properties
    local priority = transient and transient.priority
      or source and source.playlist.priority
      or type(properties) == 'table' and properties.priority
    local rowCategory
    if orphaned then
      rowCategory = 'Missing'
    elseif type(priority) == 'number' then
      rowCategory = catalog.category(priority)
    end
    if rowCategory == category then
      result[#result + 1] = {
        id = record.id,
        playlist = transient
          or source and source.playlist
          or { id = record.id, priority = priority },
        selectable = source ~= nil or entry ~= nil or transient ~= nil,
        editable = catalog.canEdit(record.id),
        status = catalog.documentDiagnostic() and 'Read-only'
          or orphaned and 'Missing'
          or record.diagnostic and 'Unavailable'
          or record.transient and 'Runtime-only'
          or nil,
      }
    end
  end
  table.sort(result, function(a, b)
    local aPriority = type(a.playlist.priority) == 'number' and a.playlist.priority or math.huge
    local bPriority = type(b.playlist.priority) == 'number' and b.playlist.priority or math.huge
    if aPriority == bPriority then return a.id < b.id end
    return aPriority < bPriority
  end)
  return result
end
return catalog
