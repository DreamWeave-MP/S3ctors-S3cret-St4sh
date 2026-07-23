---@omw-context player

local markup = require 'openmw.markup'

local normalizePath = require 'scripts.s3.normalizePath'

local musicUtil = require 'scripts.s3.music.util'

local error, next, StrFormat, type = error, next, string.format, type

---@type table<string, S3maphoreTrackMetadata>
--- Keys are lowercased VFS paths.
local Tracks = {}

---@type table<string, S3maphorePlaylistMetadata>
--- Keys are lowercased playlist IDs.
local Playlists = {}

--- Normalize a YAML value into a metadata table.
--- String values become { title = value }.
--- Table values are validated and stored as-is.
---@param rawValue string|table
---@return S3maphoreMusicMetadataBase
local function normalizeMetadata(rawValue)
  if type(rawValue) == 'string' then return { title = rawValue } end

  if type(rawValue) ~= 'table' then
    error(StrFormat('Invalid metadata type: expected string or table, got %s', type(rawValue)))
  end

  local title = rawValue.title
  if type(title) ~= 'string' then
    error(StrFormat('Metadata table \'title\' field must be a string, got %s', type(title)))
  end

  return rawValue
end

--- Load a YAML file from Playlists/ and merge its data.
--- Both the "playlists" and "tracks" sections support string-or-table values
--- (string is normalized to { title = string }).
--- Throws on malformed YAML — caller should wrap in pcall.
---
--- Note: duplicate playlist/track keys across multiple YAML files are
--- resolved by last-writer-wins, where the order is alphabetical.
---@param yamlFile string VFS path
local function loadYamlFile(yamlFile)
  ---@type table<string, any>?
  local data = markup.loadYaml(yamlFile)
  if type(data) ~= 'table' then return end

  ---@type table<string, string|table>?
  local playlistSection = data.playlists
  if type(playlistSection) == 'table' then
    for playlistId, rawMetadata in next, playlistSection do
      local meta, key = normalizeMetadata(rawMetadata), normalizePath(playlistId)
      ---@cast meta S3maphorePlaylistMetadata

      if Playlists[key] then
        musicUtil.debugLog('%s Overriding playlist metadata: %s', yamlFile, key)
      end

      Playlists[key] = musicUtil.makeReadOnly(meta, false, false)
    end
  end

  ---@type table<string, string|table>?
  local trackSection = data.tracks
  if type(trackSection) == 'table' then
    for trackPath, rawMetadata in next, trackSection do
      local meta, key = normalizeMetadata(rawMetadata), normalizePath(trackPath)
      ---@cast meta S3maphoreTrackMetadata

      if Tracks[key] then musicUtil.debugLog('%s Overriding track metadata: %s', yamlFile, key) end

      Tracks[key] = musicUtil.makeReadOnly(meta)
    end
  end
end

--- Look up metadata for a single track by VFS path.
---@param vfsPath string Full VFS path to a track (e.g., "music/explore/morrowind title.mp3")
---@return S3maphoreTrackMetadata? Metadata table, or nil if unknown
local function getTrackMetadata(vfsPath) return Tracks[normalizePath(vfsPath)] end

--- Look up metadata for a playlist by playlist ID.
---@param playlistId string Playlist identifier (e.g., "Explore", "Battle")
---@return S3maphorePlaylistMetadata? Metadata table, or nil if unknown
local function getPlaylistMetadata(playlistId) return Playlists[normalizePath(playlistId)] end

--- Return a human-readable display name for a playlist.
--- Extracts the "title" field from playlist metadata,
--- falling back to the playlist ID if no metadata is registered.
---@param playlistId string
---@return string
local function getPlaylistDisplayName(playlistId)
  local metadata = Playlists[normalizePath(playlistId)]
  if metadata then return metadata.title end
  return playlistId
end

--- Iterate over all registered playlists.
--- Each iteration yields (lowercased playlistId, metadata).
---@return fun(state: table<string, S3maphorePlaylistMetadata>, key: string?): string, S3maphorePlaylistMetadata iter
---@return table<string, S3maphorePlaylistMetadata> state
---@return nil initIndex
local function iterPlaylists() return next, Playlists, nil end

--- Iterate over all registered tracks.
--- Each iteration yields (lowercased vfsPath, metadata).
---@return fun(state: table<string, S3maphoreTrackMetadata>, key: string?): string, S3maphoreTrackMetadata iter
---@return table<string, S3maphoreTrackMetadata> state
---@return nil initIndex
local function iterTracks() return next, Tracks, nil end

---@type S3maphoreMusicMetadataRegistry
local MetadataRegistry = {
  getPlaylistDisplayName = getPlaylistDisplayName,
  getPlaylistMetadata = getPlaylistMetadata,
  getTrackMetadata = getTrackMetadata,
  iterPlaylists = iterPlaylists,
  iterTracks = iterTracks,
  loadYamlFile = loadYamlFile,
}

return MetadataRegistry
