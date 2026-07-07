---@module 'doc.s3maphoreTypes'
---@omw-context player

local ambient = require 'openmw.ambient'
local async = require 'openmw.async'
---@type openmw.core
local core = require 'openmw.core'
local debug = require 'openmw.debug'
local input = require 'openmw.input'
local nearby = require 'openmw.nearby'
local self = require 'openmw.self'
local storage = require 'openmw.storage'
local types = require 'openmw.types'

local clear = require 'scripts.s3.clear'

local MusicManager = require 'scripts.s3.music.musicManager'
local MusicSettings = require 'scripts.s3.music.musicSettings'

---@type S3maphorePlaylistEnv
local PlaylistEnv
---@type function?
local PlaylistLoader = require 'scripts.s3.music.playlistLoader'
---@type PlaylistRules
local PlaylistRules
---@type PlaylistState
local PlaylistState

local SilenceManager = require 'scripts.s3.music.silenceManager'
local Strings = require 'scripts.s3.music.staticStrings'
---@type CombatState
local CombatState

local activePlaylistSettings = storage.playerSection 'S3maphoreActivePlaylistSettings'
local musicUtil = require 'scripts.s3.music.util'

local NullFunction = require 'scripts.s3.nullFunction'

---@type Rand
local randomGen = require 'scripts.s3.randomGen'

local Ceil, error, next, pairs, Max, Min, StrFormat, StrLower, Remove, TableSort, type =
  math.ceil,
  error,
  next,
  pairs,
  math.max,
  math.min,
  string.format,
  string.lower,
  table.remove,
  table.sort,
  type

local IsDead, IsSoundEnabled, IsSwimming, SendEvent, SendGlobalEvent =
  types.Actor.isDead,
  core.sound.isEnabled,
  types.Actor.isSwimming,
  self.sendEvent,
  core.sendGlobalEvent

local ActiveEffects, LevitateEffect =
  types.Actor.activeEffects(self), core.magic.EFFECT_TYPE.Levitate
local GetMagicEffect = ActiveEffects.getEffect
local HasTag

---@type fun(dt: number)
local currentUpdateHandler

local handlePlayback, onSoundEnabledChanged, resolvePlaylist, updateActorChain =
  NullFunction, NullFunction, NullFunction, NullFunction
---@cast updateActorChain fun(dt: number)

local desiredPlaylist, resolverDirty, didTransition, wasExterior = nil, false, false, false

---@type QueuedEvent
local queuedEvent = {
  backup = {},
  data = {},
  name = nil,
}

local PlaybackParams = {
  fadeOut = MusicSettings.FadeOutDuration,
}

---@type S3maphorePlaybackChangeEventData
local TrackChangeData = {
  fadeOut = MusicSettings.FadeOutDuration,
  playlistId = '',
  reason = MusicManager.STATE.TrackChanged,
  trackName = '',
}

local CachedCellGrid = { x = 0, y = 0 }

local Actors = nearby.actors
local MIN_BATCH_SIZE, MAX_BATCH_SIZE, TARGET_LATENCY, THIRTY_FRAMES = 4, 16, 1 / 3, 1 / 30
local chainPosition = 2

local function clearQueuedData()
  if type(queuedEvent.data) ~= 'table' then queuedEvent.data = queuedEvent.backup end
  clear(queuedEvent.data)
end

--- Updates PlaylistState cell metadata from self.cell.
--- Called from both S3LFCellChanged and the init handler.
local function updateCellMetadata()
  local thisCell = self.cell
  ---@cast thisCell openmw.core.LCell

  if not HasTag then HasTag = thisCell.hasTag end

  local shouldUseName = thisCell.name ~= ''

  PlaylistState.cellHasWater = thisCell.hasWater
  PlaylistState.cellWaterLevel = thisCell.waterLevel
  PlaylistState.cellIsExterior = thisCell.isExterior or HasTag(thisCell, 'QuasiExterior')
  PlaylistState.cellName = StrLower(shouldUseName and thisCell.name or thisCell.id)
  PlaylistState.cellId = thisCell.id

  if thisCell.region then PlaylistState.nearestRegion = thisCell.region end

  if thisCell.isExterior then
    CachedCellGrid.x, CachedCellGrid.y = thisCell.gridX, thisCell.gridY
    PlaylistState.currentGrid = CachedCellGrid
  else
    PlaylistState.currentGrid = nil
  end
end

--- Updates the playlist state for this frame, before it is actively used in playlist selection
local function updatePlaylistState()
  local oldTod, newTod = PlaylistState.playlistTimeOfDay, MusicManager.playlistTimeOfDay()
  local TODChanged = oldTod and oldTod ~= newTod
  PlaylistState.playlistTimeOfDay = newTod

  local wasMoving, controls = PlaylistState.movementMode, self.controls
  if IsSwimming(self) then
    PlaylistState.movementMode = 'swimming'
  elseif
    not debug.isCollisionEnabled()
    --- Magic effect enums are strings now
    --- This is why you use the enum values :)
    ---@diagnostic disable-next-line: param-type-mismatch
    or GetMagicEffect(ActiveEffects, LevitateEffect).magnitude > 0
  then
    PlaylistState.movementMode = 'flying'
  elseif controls.sneak then
    PlaylistState.movementMode = 'sneaking'
  elseif controls.movement ~= 0 or controls.sideMovement ~= 0 then
    if controls.run then
      PlaylistState.movementMode = 'running'
    else
      PlaylistState.movementMode = 'walking'
    end
  else
    PlaylistState.movementMode = 'standing'
  end
  local movementChanged = wasMoving ~= PlaylistState.movementMode

  if TODChanged or movementChanged then
    queuedEvent.name = 'S3maphoreStateChanged'
    local flags = 0
    if TODChanged then flags = flags + MusicManager.STATE_FLAGS.TOD end
    if movementChanged then flags = flags + MusicManager.STATE_FLAGS.MOVEMENT end
    queuedEvent.data = flags
  end

  currentUpdateHandler = handlePlayback
end

local function checkSilenceManager()
  currentUpdateHandler = SilenceManager:silenceActive() and onSoundEnabledChanged
    or updatePlaylistState
end
onSoundEnabledChanged = function()
  --- Explicitly re-seed the generator on each round-robin cycle to improve distribution
  randomGen.int()

  if not IsSoundEnabled() then return end

  currentUpdateHandler = checkSilenceManager
end

---@param dt number
local function realUpdateActorChain(dt)
  local numActors = #Actors
  if numActors < 2 then return end

  dt = dt == 0 and THIRTY_FRAMES or dt

  local batchSize =
    Max(MIN_BATCH_SIZE, Min(MAX_BATCH_SIZE, Ceil((numActors - 1) * dt / TARGET_LATENCY)))

  for _ = 1, batchSize do
    if chainPosition > numActors then chainPosition = 2 end
    local actor = Actors[chainPosition]
    SendEvent(actor, 'S3maphoreCheckCombat')
    chainPosition = chainPosition + 1
  end
end

local function realResolvePlaylist()
  local newPlaylist = musicUtil.getActivePlaylistByPriority(
    MusicManager.specialPlaylists,
    PlaylistEnv.Playback,
    MusicManager.activePlaydeck
  )

  if newPlaylist == desiredPlaylist then return end
  desiredPlaylist = newPlaylist
  resolverDirty = true
end

---@type fun(_: number)
currentUpdateHandler = function(_)
  if not PlaylistLoader then error 'Playlist loader not found during initialization!' end

  ---@type S3maphorePlaylistEnv?
  local playlistEnv = PlaylistLoader()

  if playlistEnv then
    PlaylistEnv = playlistEnv
    PlaylistState, PlaylistRules = PlaylistEnv.Playback.state, PlaylistEnv.Playback.rules
  else
    return
  end

  PlaylistLoader = nil
  updateActorChain = realUpdateActorChain
  resolvePlaylist = realResolvePlaylist

  local function priorityThenRegistration(a, b)
    return a.priority < b.priority
      or (a.priority == b.priority and a.registrationOrder > b.registrationOrder)
  end
  TableSort(MusicManager.explorePlaylists, priorityThenRegistration)
  TableSort(MusicManager.battlePlaylists, priorityThenRegistration)
  TableSort(MusicManager.specialPlaylists, priorityThenRegistration)

  CombatState = require 'scripts.s3.music.combatState'(
    MusicSettings,
    PlaylistRules,
    MusicManager,
    PlaylistState
  )

  storage.playerSection('SettingsS3Music'):subscribe(async:callback(function(_, key)
    if key == 'BannerEnabled' then
      MusicManager.updateBanner()
    elseif key == 'MusicEnabled' then
      musicUtil.debugLog('Music state changed to: %s', MusicSettings.MusicEnabled)

      MusicManager.forceSkip = false
      queuedEvent.name = nil
      clearQueuedData()

      if MusicSettings.MusicEnabled then
        currentUpdateHandler = onSoundEnabledChanged
      else
        currentUpdateHandler = NullFunction

        if ambient.isMusicPlaying() then
          ambient.stopMusic()
          MusicManager.currentPlaylist = nil
          MusicManager.currentTrack = nil

          queuedEvent.data.reason = MusicManager.STATE.Disabled
          SendEvent(self, 'S3maphoreMusicStopped', queuedEvent.data)
        end
      end
    elseif
      key == 'PlayerTargetedCombatOnly'
      or key == 'CombatLevelGap'
      or key == 'CombatHealthThreshold'
    then
      CombatState.recomputeState()
      resolvePlaylist()
    end
  end))

  SendGlobalEvent('S3maphoreInitializationComplete', self.object)

  updateCellMetadata()

  musicUtil.debugLog 'Coroutine load complete, initializing cell presence'
  currentUpdateHandler = NullFunction
end

--- If a set of fallback playlists is present, attempt to use them during track selection
--- It should be noted that, for fallback playlists, their `active` parameter is ignored currently.
---@param newPlaylist S3maphorePlaylist
local function getPlaylistIdForTrackSelection(newPlaylist)
  local fallbackData = newPlaylist.fallback
  if not fallbackData or not fallbackData.playlists then return newPlaylist.id end

  local useOtherPlaylist = randomGen.float() <= (fallbackData.playlistChance or 0.5)

  if not useOtherPlaylist then return newPlaylist.id end

  for i = #fallbackData.playlists, 1, -1 do
    local playlistId = fallbackData.playlists[i]
    if not MusicManager.registeredPlaylists[playlistId] then Remove(fallbackData.playlists, i) end
  end

  local numBackupPlaylists = #fallbackData.playlists
  local selectedPlaylistIndex = randomGen.range(numBackupPlaylists, true)
  local selectedPlaylistId = fallbackData.playlists[selectedPlaylistIndex]

  if not MusicManager.registeredPlaylists[selectedPlaylistId] then
    if selectedPlaylistId then
      musicUtil.debugLog(Strings.FallbackPlaylistDoesntExist, newPlaylist.id, selectedPlaylistId)
    end

    return newPlaylist.id
  end

  return selectedPlaylistId
end

---@param playlistId string name of a playlist stored in registeredPlaylists table
local function selectTrackFromPlaylist(playlistId)
  local playlist = MusicManager.registeredPlaylists[playlistId]

  if not playlist then error(StrFormat(Strings.PlaylistNotRegistered, playlistId)) end

  local playlistOrder = MusicManager.playlistsTracksOrder[playlist.id]
  local nextTrackIndex = Remove(playlistOrder)

  if not nextTrackIndex then error(Strings.NextTrackIndexNil) end

  -- If there are no tracks left, fill playlist again.
  if not next(playlistOrder) then
    playlistOrder = musicUtil.initTracksOrder(playlist.tracks, playlist.randomize)

    if not playlist.cycleTracks then playlist.deactivateAfterEnd = true end

    -- If next track for randomized playist will be the same as one we want to play, swap it with random track.
    if playlist.randomize and #playlistOrder > 1 and playlistOrder[1] == nextTrackIndex then
      local index = randomGen.range(2, #playlistOrder, true)
      playlistOrder[1], playlistOrder[index] = playlistOrder[index], playlistOrder[1]
    end

    MusicManager.playlistsTracksOrder[playlist.id] = playlistOrder
  end

  musicUtil.setStoredTracksOrder(playlist.id, playlistOrder)

  local trackPath = playlist.tracks[nextTrackIndex]

  if not trackPath then error(StrFormat(Strings.NoTrackPath, nextTrackIndex, playlist.id)) end

  return trackPath
end

---@param newPlaylist S3maphorePlaylist
local function switchPlaylist(newPlaylist)
  local nextPlaylist = getPlaylistIdForTrackSelection(newPlaylist)
  local nextTrack = selectTrackFromPlaylist(nextPlaylist)

  if newPlaylist.playOneTrack then newPlaylist.deactivateAfterEnd = true end

  if MusicManager.currentPlaylist and newPlaylist.id == MusicManager.currentPlaylist.id then
    SilenceManager:updateSilenceParams(newPlaylist)
  end

  MusicManager.currentPlaylist = newPlaylist
  MusicManager.currentTrack = nextTrack
  PlaybackParams.fadeOut = newPlaylist.fadeOut or MusicSettings.FadeOutDuration
end

---@param oldPlaylist S3maphorePlaylist?
---@param newPlaylist S3maphorePlaylist
---@return boolean canSwitchPlaylist
local function canSwitchPlaylist(oldPlaylist, newPlaylist)
  if not oldPlaylist then --- No playlist, eg no music playing, means we can switch
    return true
  elseif oldPlaylist.interruptMode == MusicManager.INTERRUPT.Never then --- But never interrupt a playlist that specifies it can't be interrupted
    return false
  elseif
    MusicSettings.ForceFinishTrack and oldPlaylist.interruptMode == newPlaylist.interruptMode
  then --- And also allow battle and explore playlist to flow nicely between themselves
    return false
  elseif oldPlaylist.interruptMode <= MusicManager.INTERRUPT.Other then --- And otherwise, if the interrupt mode changes then allow the new playlist
    return true
  end

  musicUtil.debugLog(
    Strings.InterruptModeFallthrough,
    oldPlaylist.id,
    oldPlaylist.interruptMode,
    newPlaylist.id,
    newPlaylist.interruptMode
  )

  return false
end

handlePlayback = function(_)
  currentUpdateHandler = onSoundEnabledChanged

  if queuedEvent.name then
    SendEvent(self, queuedEvent.name, queuedEvent.data)
    queuedEvent.name = nil
    clearQueuedData()
    return
  end

  local musicPlaying = ambient.isMusicPlaying()

  -- Resolver flagged a new playlist this tick
  if resolverDirty then
    resolverDirty = false

    if not desiredPlaylist then
      if musicPlaying then
        ambient.stopMusic()
        MusicManager.currentPlaylist = nil
        MusicManager.currentTrack = nil
      end

      clearQueuedData()
      queuedEvent.data.reason = MusicManager.STATE.NoPlaylist
      SendEvent(self, 'S3maphoreMusicStopped', queuedEvent.data)
      return
    end

    if
      desiredPlaylist ~= MusicManager.currentPlaylist
      and canSwitchPlaylist(MusicManager.currentPlaylist, desiredPlaylist)
    then
      MusicManager.forceSkip = true
    elseif desiredPlaylist ~= MusicManager.currentPlaylist and didTransition then
      local isExterior = PlaylistState.cellIsExterior
      local friendlyEnter = not PlaylistState.cellPresence.cellHasHostileActors
      local hostileEnter = PlaylistState.cellPresence.cellHasHostileActors

      local overworldCross = wasExterior
        and isExterior
        and desiredPlaylist.priority
          < (MusicManager.currentPlaylist and MusicManager.currentPlaylist.priority or 1000)

      if
        (MusicSettings.ForcePlaylistChangeOnFriendlyExteriorTransition and friendlyEnter)
        or (MusicSettings.ForcePlaylistChangeOnHostileExteriorTransition and hostileEnter)
        or (MusicSettings.ForcePlaylistChangeOnOverworldTransition and overworldCross)
      then
        MusicManager.forceSkip = true
      end
    end

    didTransition = false
  end

  -- Need a new track?
  local pickNewTrack = not musicPlaying or MusicManager.forceSkip

  if not pickNewTrack then return end

  MusicManager.forceSkip = false

  local target = desiredPlaylist or MusicManager.currentPlaylist
  if not target then return end

  if target.deactivateAfterEnd then
    target.deactivateAfterEnd = nil
    target.active = false
    desiredPlaylist = nil
    MusicManager.currentPlaylist = nil
    MusicManager.currentTrack = nil
    resolvePlaylist()
    return
  end

  if target ~= MusicManager.currentPlaylist then
    switchPlaylist(target)
  else
    local nextTrack = selectTrackFromPlaylist(target.id)
    MusicManager.currentTrack = nextTrack
    PlaybackParams.fadeOut = target.fadeOut or MusicSettings.FadeOutDuration
  end

  clear(TrackChangeData)

  TrackChangeData.fadeOut = PlaybackParams.fadeOut
  TrackChangeData.playlistId = target.id
  TrackChangeData.trackName = MusicManager.currentTrack
  TrackChangeData.reason = MusicManager.STATE.TrackChanged

  SendEvent(self, 'S3maphoreTrackChanged', TrackChangeData)
end

MusicManager.addTrackChangedHandler(
  ---@param eventData S3maphorePlaybackChangeEventData
  function(eventData)
    musicUtil.debugLog(Strings.TrackChanged, eventData.playlistId, eventData.trackName)

    PlaybackParams.fadeOut = eventData.fadeOut or MusicSettings.FadeOutDuration
    ambient.streamMusic(eventData.trackName, PlaybackParams)
    MusicManager.updateBanner()
  end
)

return {
  interfaceName = 'S3maphore',

  interface = MusicManager,

  engineHandlers = {

    onQuestUpdate = function()
      ---@diagnostic disable-next-line: invisible
      PlaylistRules.clearJournalCache()
      resolvePlaylist()
    end,

    onKeyPress = function(key)
      if key.code == input.KEY.F8 then
        if key.withShift then
          SendEvent(self, 'S3maphoreToggleMusic')
        else
          SendEvent(self, 'S3maphoreSkipTrack')
        end
      elseif key.code == input.KEY.F4 then
      end
    end,

    onUpdate = function(dt)
      updateActorChain(dt)
      currentUpdateHandler(dt)
    end,

    onSave = function()
      local playlistStates = {}

      for playlistId, playlist in pairs(MusicManager.registeredPlaylists) do
        playlistStates[playlistId] = playlist.active
      end

      return {
        playlistStates = playlistStates,
      }
    end,

    onLoad = function(data)
      if not data then return end

      if data.playlistStates then
        for playlistId, playlistState in pairs(data.playlistStates) do
          activePlaylistSettings:set(playlistId .. 'Active', playlistState)
        end
      end
    end,
  },
  eventHandlers = {
    Died = function()
      SendEvent(
        self,
        'S3maphoreSpecialTrack',
        --- Expand this to allow registering deathHandlers to provide custom death tracks instead of hardcoding Soule's path
        { trackPath = 'music/special/mw_death.mp3', reason = MusicManager.STATE.Died }
      )
      currentUpdateHandler = NullFunction
    end,

    ---@param eventData CombatTargetChangedData
    OMWMusicCombatTargetsChanged = function(eventData)
      if IsDead(self) then return end

      CombatState.onTargetsChanged(eventData.actor, eventData.targets)
      if PlaylistState.cellId ~= self.cell.id then return end

      musicUtil.debugLog('Updating playlist due to combat target change: %s', eventData.actor)
      resolvePlaylist()
    end,

    S3LFCellChanged = function(oldCellId)
      chainPosition, didTransition, wasExterior = 2, true, PlaylistState.cellIsExterior

      updateCellMetadata()

      if not PlaylistLoader then
        musicUtil.debugLog 'Requesting CellPresence update from PLAYER scope'
        SendGlobalEvent('S3maphoreUpdatePresence', { self.object, oldCellId })
      end
    end,

    S3maphoreToggleMusic = function(enabled)
      MusicManager.overrideMusicEnabled(enabled)
      if MusicSettings.MusicEnabled then resolvePlaylist() end
    end,

    S3maphoreSkipTrack = function()
      currentUpdateHandler = onSoundEnabledChanged
      MusicManager.skipTrack()
      resolvePlaylist()
    end,

    S3maphoreSpecialTrack = function(eventData)
      MusicManager.playSpecialTrack(eventData.trackPath, eventData.reason)
    end,

    S3maphoreSetPlaylistActive = function(eventData)
      musicUtil.debugLog(Strings.ChangingPlaylist, eventData.playlist, eventData.state)

      MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
      if PlaylistState.cellId ~= self.cell.id then return end
      resolvePlaylist()
    end,

    ---@param eventData S3maphorePlaybackChangeEventData
    S3maphoreMusicStopped = function(eventData)
      musicUtil.debugLog(Strings.MusicStopped, eventData.reason)

      MusicManager.updateBanner()
    end,

    S3maphoreCellPresenceUpdated = function()
      musicUtil.debugLog 'Resolving playlist after cell presence update!'
      resolvePlaylist()
      currentUpdateHandler = onSoundEnabledChanged
    end,

    S3maphoreWeatherChanged = function(weatherName)
      PlaylistState.weather = weatherName

      musicUtil.debugLog(Strings.WeatherChanged, weatherName)

      if PlaylistState.cellId ~= self.cell.id then return end

      resolvePlaylist()
      currentUpdateHandler = onSoundEnabledChanged
    end,

    ---@param hitObject openmw.LObject
    S3maphoreClearTargetCache = function(hitObject)
      if PlaylistLoader then return end

      musicUtil.debugLog(
        'Clearing target cache for hit event on %s: %s',
        hitObject.recordId,
        hitObject.id
      )

      CombatState.onHit()
      PlaylistRules.clearGlobalCombatTargetCache()
      resolvePlaylist()
    end,

    ---@param flags S3maphoreStateChangedFlag
    S3maphoreStateChanged = function(flags)
      if PlaylistState.cellId ~= self.cell.id then return end
      musicUtil.debugLog('Performing playlist resolution after state change! Flags: %s', flags)
      resolvePlaylist()
      currentUpdateHandler = onSoundEnabledChanged
    end,

    S3maphoreTrackChanged = MusicManager.callTrackChangedHandlers,
  },
}
