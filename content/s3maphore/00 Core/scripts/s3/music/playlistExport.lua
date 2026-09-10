---@omw-context player
local Conditions = require 'scripts.s3.music.playlistConditions'
local Reconciler = require 'scripts.s3.music.playlistReconciler'
local fields = {
  'id',
  'priority',
  'active',
  'randomize',
  'cycleTracks',
  'playOneTrack',
  'deactivateAfterEnd',
  'interruptMode',
  'fadeOut',
  'tracks',
  'fallback',
  'silenceBetweenTracks',
  'exclusions',
}
return function(id, entry, source)
  Reconciler.validateEntry(id, entry)
  assert(
    entry.condition,
    'Custom Lua callbacks are opaque. Replace the condition before exporting.'
  )
  local playlist = source and Reconciler.copy(source.playlist) or { id = id }
  for k, v in pairs(entry.properties) do
    playlist[k] = v
  end
  local declarations, callback = Conditions.emit(Conditions.deserialize(entry.condition))
  local lines = {
    '-- S3maphore playlist module: place under Playlists/ in an OpenMW data directory.',
    declarations,
    'return {',
    '  {',
  }
  for i = 1, #fields do
    local key = fields[i]
    local value = playlist[key]
    if value ~= nil then
      if key == 'tracks' then
        lines[#lines + 1] = '    tracks = {'
        for i = 1, #value do
          lines[#lines + 1] = '      ' .. Conditions.literal(value[i]) .. ','
        end
        lines[#lines + 1] = '    },'
      else
        local rendered = value == math.huge and 'math.huge' or Conditions.literal(value)
        lines[#lines + 1] = '    ' .. key .. ' = ' .. rendered .. ','
      end
    end
  end
  lines[#lines + 1] = '    isValidCallback = ' .. callback:gsub('\n', '\n    ') .. ','
  lines[#lines + 1] = '  },'
  lines[#lines + 1] = '}'
  return table.concat(lines, '\n')
end
