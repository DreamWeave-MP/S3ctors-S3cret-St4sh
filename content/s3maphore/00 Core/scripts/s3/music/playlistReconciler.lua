---@module 'doc.s3maphoreTypes'
---@omw-context player
local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local PlaylistPriority = require 'doc.playlistPriority'
local PlaylistReconciler = {}

local function copy(value, seen)
  if type(value) ~= 'table' then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}
  seen[value] = out
  for k, v in pairs(value) do
    out[k] = copy(v, seen)
  end
  return out
end

PlaylistReconciler.copy = copy
PlaylistReconciler.properties = {
  'priority',
  'randomize',
  'cycleTracks',
  'playOneTrack',
  'deactivateAfterEnd',
  'interruptMode',
  'fadeOut',
  'tracks',
}

local propertySet = {}
for i = 1, #PlaylistReconciler.properties do
  propertySet[PlaylistReconciler.properties[i]] = true
end

local function finite(n) return type(n) == 'number' and n == n and math.abs(n) ~= math.huge end

local function deck(priority)
  return priority <= PlaylistPriority.Special and 1
    or priority <= PlaylistPriority.BattleVanilla and 2
    or 3
end

local function equal(a, b, seen)
  if type(a) ~= type(b) then return false end
  if type(a) ~= 'table' then return a == b end
  seen = seen or {}
  if seen[a] == b then return true end
  seen[a] = b
  for k, v in pairs(a) do
    if not equal(v, b[k], seen) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

PlaylistReconciler.equals = equal

local function validateProperties(p)
  assert(type(p) == 'table', 'Playlist properties must be a table')
  for k, v in pairs(p) do
    assert(propertySet[k], 'Unknown editable property: ' .. tostring(k))
    if k == 'tracks' then
      assert(type(v) == 'table', 'Tracks must be an array')
      local count = 0
      for index, path in pairs(v) do
        count = count + 1
        assert(type(index) == 'number' and index >= 1 and index % 1 == 0, 'Invalid track index')
        assert(type(path) == 'string' and path ~= '' and #path <= 16384, 'Invalid track path')
      end
      assert(count <= 10000, 'Too many tracks')
      for i = 1, count do
        assert(v[i] ~= nil, 'Sparse track array')
      end
    elseif k == 'priority' then
      assert((finite(v) and v <= 1000) or v == math.huge, 'Priority must be <= 1000, or Never')
    elseif k == 'fadeOut' then
      assert(finite(v) and v >= 0, 'Fade out must be finite and nonnegative')
    elseif k == 'interruptMode' then
      assert(v == 0 or v == 1 or v == 2 or v == 3, 'Invalid interrupt mode')
    else
      assert(type(v) == 'boolean', k .. ' must be boolean')
    end
  end
end

local function validateEntry(id, entry)
  assert(type(id) == 'string' and id ~= '' and id ~= 'Special', 'Invalid or reserved playlist ID')
  assert(type(entry) == 'table', 'Editor entry must be a table')
  for k in pairs(entry) do
    assert(
      k == 'kind' or k == 'source' or k == 'properties' or k == 'condition',
      'Unknown editor entry field: ' .. tostring(k)
    )
  end
  assert(entry.kind == 'user' or entry.kind == 'override', 'Unknown playlist ownership kind')
  if entry.kind == 'override' then
    assert(
      type(entry.source) == 'string' and entry.source ~= '',
      'Override requires source provenance'
    )
  else
    assert(entry.source == nil, 'User playlist cannot have external source')
  end
  validateProperties(entry.properties)
  if entry.condition ~= nil then PlaylistConditions.deserialize(entry.condition) end
  if entry.kind == 'user' then
    assert(entry.condition ~= nil, 'User playlist requires a condition')
    assert(
      entry.properties.priority ~= nil and entry.properties.tracks ~= nil,
      'User playlist requires priority and tracks'
    )
  end
end

PlaylistReconciler.validateEntry = validateEntry

function PlaylistReconciler.new(adapter)
  local sources, entries, diagnostics, transients = {}, {}, {}, {}
  local rejectedDocument
  local reconciler = {}

  local function diagnose(id, message)
    diagnostics[id] = tostring(message)
    if adapter.report then adapter.report(tostring(id) .. ': ' .. tostring(message)) end
  end

  local function materialize(id, entry)
    validateEntry(id, entry)
    local source = sources[id]
    if entry.kind == 'override' then
      assert(source, 'Source missing; saved edits retained but inactive')
      assert(source.owner == entry.source, 'Source conflict; saved edits retained but inactive')
    else
      assert(not source, 'User playlist ID conflicts with a source playlist')
    end
    local playlist = source and copy(source.playlist) or { id = id }
    for k, v in pairs(entry.properties) do
      playlist[k] = copy(v)
    end
    if source then
      assert(
        deck(playlist.priority) == deck(source.playlist.priority),
        'Changing playlist category is not supported'
      )
    end
    if entry.condition then
      playlist.isValidCallback = PlaylistConditions.compile(
        PlaylistConditions.deserialize(entry.condition),
        adapter.playback,
        adapter.loadCode
      )
    end
    if adapter.prepare then adapter.prepare(playlist) end
    assert(type(playlist.isValidCallback) == 'function', 'Effective playlist requires callback')
    return playlist
  end

  local function publish(playlist)
    adapter.register(playlist)
    if adapter.changed then adapter.changed() end
  end

  local function unpublish(id)
    if adapter.remove then adapter.remove(id) end
    if adapter.changed then adapter.changed() end
  end

  function reconciler.reconcile(id)
    diagnostics[id] = nil
    local source, entry = sources[id], entries[id]
    local transient = transients[id]

    if entry then
      local ok, playlist = pcall(materialize, id, entry)
      if not ok then
        diagnose(id, playlist)
      elseif not transient then
        publish(playlist)
        return
      end
    end

    if transient then return end

    if source then
      publish(copy(source.playlist))
    else
      unpublish(id)
    end
  end

  function reconciler.registerSource(playlist, owner)
    assert(type(owner) == 'string' and owner ~= '', 'Source owner required')
    assert(playlist.id ~= 'Special', 'Special is reserved for runtime playback')
    local source = copy(playlist)
    if adapter.prepare then adapter.prepare(source) end
    sources[source.id] = { owner = owner, playlist = source }
    reconciler.reconcile(source.id)
  end

  function reconciler.removeSource(id)
    sources[id] = nil
    reconciler.reconcile(id)
  end

  function reconciler.registerTransient(playlist)
    transients[playlist.id] = copy(playlist)
    publish(copy(playlist))
  end

  function reconciler.load(document)
    entries, diagnostics, rejectedDocument = {}, {}, nil
    if document == nil then return end
    if type(document) ~= 'table' or document.version ~= 1 or type(document.entries) ~= 'table' then
      rejectedDocument = document
      diagnose('$document', 'Unsupported or malformed editor document; editing disabled')
      return
    end
    for k in pairs(document) do
      if k ~= 'version' and k ~= 'entries' then
        rejectedDocument = document
        diagnose('$document', 'Unexpected editor document field; editing disabled')
        return
      end
    end
    entries = copy(document.entries)
    for id, entry in pairs(entries) do
      local ok, err = pcall(validateEntry, id, entry)
      if not ok then diagnose(id, err) end
    end
  end

  function reconciler.finishLoading()
    local ids = {}
    for id in pairs(entries) do
      if type(id) == 'string' then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for i = 1, #ids do
      reconciler.reconcile(ids[i])
    end
  end

  function reconciler.save()
    if rejectedDocument ~= nil then return copy(rejectedDocument) end
    return { version = 1, entries = copy(entries) }
  end

  function reconciler.commit(id, entry)
    assert(rejectedDocument == nil, 'Cannot edit an unsupported editor document')
    validateEntry(id, entry)
    local previous = entries[id]
    local previousPriority = previous
        and previous.kind == 'user'
        and previous.properties
        and previous.properties.priority
      or nil
    local nextPriority = entry.kind == 'user' and entry.properties.priority or nil
    local categoryChanged = previousPriority
      and nextPriority
      and deck(previousPriority) ~= deck(nextPriority)
    local playlist = materialize(id, entry)
    local previousEntry, previousDiagnostic = entries[id], diagnostics[id]
    local previousPlaylist
    if categoryChanged and not transients[id] then
      previousPlaylist = previousEntry and materialize(id, previousEntry)
        or sources[id] and copy(sources[id].playlist)
    end
    if categoryChanged and adapter.remove and not transients[id] then adapter.remove(id) end
    entries[id], diagnostics[id] = copy(entry), nil
    local ok, failure = pcall(function()
      if not transients[id] then publish(playlist) end
    end)
    if not ok then
      entries[id], diagnostics[id] = previousEntry, previousDiagnostic
      if previousPlaylist then
        local restored, restoreFailure = pcall(publish, previousPlaylist)
        if not restored then error(restoreFailure, 0) end
      end
      error(failure, 0)
    end
  end

  function reconciler.delete(id)
    assert(rejectedDocument == nil, 'Cannot edit an unsupported editor document')
    local previousEntry, previousDiagnostic = entries[id], diagnostics[id]
    entries[id], diagnostics[id] = nil, nil
    local ok, failure = pcall(function()
      if transients[id] then
        return
      elseif sources[id] then
        publish(copy(sources[id].playlist))
      else
        unpublish(id)
      end
    end)
    if not ok then
      entries[id], diagnostics[id] = previousEntry, previousDiagnostic
      error(failure, 0)
    end
  end

  function reconciler.draft(id)
    assert(rejectedDocument == nil, 'Cannot edit an unsupported editor document')
    assert(not diagnostics[id], diagnostics[id])
    local source, entry = sources[id], entries[id]
    assert(source or entry, 'Runtime-only playlist has no persistent source identity')
    local effective = entry and materialize(id, entry) or copy(source.playlist)
    local properties = {}
    for i = 1, #PlaylistReconciler.properties do
      local key = PlaylistReconciler.properties[i]
      properties[key] = copy(effective[key])
    end
    return {
      kind = source and 'override' or 'user',
      source = source and source.owner,
      properties = properties,
      condition = entry and copy(entry.condition),
    }
  end

  function reconciler.delta(id, draft)
    local result = copy(draft)
    local source = sources[id]
    if source then
      for k, v in pairs(result.properties) do
        if equal(v, source.playlist[k]) then result.properties[k] = nil end
      end
      if next(result.properties) == nil and result.condition == nil then return end
    end
    return result
  end

  function reconciler.status() return copy(diagnostics) end

  function reconciler.documentDiagnostic() return diagnostics['$document'] end

  function reconciler.source(id) return sources[id] and copy(sources[id]) end

  function reconciler.entry(id) return entries[id] and copy(entries[id]) end

  function reconciler.info(id)
    local source, entry = sources[id], entries[id]
    if not source and not entry and not transients[id] then return end
    return {
      id = id,
      source = source and copy(source),
      entry = entry and copy(entry),
      diagnostic = diagnostics[id],
      transient = transients[id] ~= nil,
      transientPlaylist = transients[id] and copy(transients[id]),
    }
  end

  function reconciler.list()
    local ids, seen = {}, {}
    for id in pairs(sources) do
      ids[#ids + 1], seen[id] = id, true
    end
    for id in pairs(entries) do
      if not seen[id] then
        ids[#ids + 1], seen[id] = id, true
      end
    end
    for id in pairs(transients) do
      if not seen[id] then
        ids[#ids + 1], seen[id] = id, true
      end
    end
    table.sort(ids)
    local result = {}
    for i = 1, #ids do
      result[i] = reconciler.info(ids[i])
    end
    return result
  end
  return reconciler
end
return PlaylistReconciler
