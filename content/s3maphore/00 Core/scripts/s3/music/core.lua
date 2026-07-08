---@module 'doc.s3maphoreTypes'
---@omw-context player

local ambient = require 'openmw.ambient'
local async = require 'openmw.async'
---@type openmw.core
local core = require 'openmw.core'
local input = require 'openmw.input'
local self = require 'openmw.self'
local storage = require 'openmw.storage'
local types = require 'openmw.types'

local clear = require 'scripts.s3.clear'

local MusicManager = require 'scripts.s3.music.musicManager'
local MusicSettings = require 'scripts.s3.music.musicSettings'
local TrackSelection = require 'scripts.s3.music.trackSelection'

---@type S3maphorePlaylistEnv
local PlaylistEnv
---@type function?
local PlaylistLoader = require 'scripts.s3.music.playlistLoader'
local PlaylistState, updateCellMetadata = require 'scripts.s3.music.playlistState'

--- updateCellMetadata for me, but not for thee
---@diagnostic disable-next-line: invisible
updateCellMetadata, PlaylistState.updateCellMetadata = PlaylistState.updateCellMetadata, nil

---@type PlaylistRules
local PlaylistRules = require 'scripts.s3.music.playlistRules'
local SilenceManager = require 'scripts.s3.music.silenceManager'

local Strings = require 'scripts.s3.music.staticStrings'

---@type CombatState
local CombatState = require 'scripts.s3.music.combatState'

local activePlaylistSettings = storage.playerSection 'S3maphoreActivePlaylistSettings'
local musicUtil = require 'scripts.s3.music.util'

local NullFunction = require 'scripts.s3.nullFunction'

---@type Rand
local randomGen = require 'scripts.s3.randomGen'

local error, pairs, next, TableSort, type =
  error, pairs, next, table.sort, type

local CollisionEnabled, IsDead, IsSoundEnabled, IsMusicPlaying, IsSwimming, SendEvent, SendGlobalEvent, StopMusic, StreamMusic =
  require('openmw.debug').isCollisionEnabled,
  types.Actor.isDead,
  core.sound.isEnabled(),
  ambient.isMusicPlaying,
  types.Actor.isSwimming,
  self.sendEvent,
  core.sendGlobalEvent,
  ambient.stopMusic,
  ambient.streamMusic

local ActiveEffects, LevitateEffect =
  types.Actor.activeEffects(self), core.magic.EFFECT_TYPE.Levitate
local GetMagicEffect = ActiveEffects.getEffect

---@type fun(dt: number)
local currentUpdateHandler

local handlePlayback, resolvePlaylist = NullFunction, NullFunction

local desiredPlaylist, resolverDirty, didTransition, waitingOnPresence, wasExterior =
  nil, false, false, true, false

---@type QueuedEvent
local queuedEvent = {
  backup = {},
  data = nil,
  name = '',
}

--- Always actually use the `backup` table as `data` may be overwritten with
--- non-table types. see `clearQueuedData`
queuedEvent.data = queuedEvent.backup

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

local function clearQueuedData()
  if type(queuedEvent.data) ~= 'table' then queuedEvent.data = queuedEvent.backup end
  clear(queuedEvent.data)
  queuedEvent.name = ''
end

--- Updates the playlist state for this frame, before it is actively used in playlist selection
local function updatePlaylistState()
  --- Explicitly advance the generator on each round-robin cycle to improve distribution
  randomGen.int()

  local oldTod, newTod = PlaylistState.playlistTimeOfDay, MusicManager.playlistTimeOfDay()
  local TODChanged = oldTod and oldTod ~= newTod
  PlaylistState.playlistTimeOfDay = newTod

  local wasMoving, controls = PlaylistState.movementMode, self.controls
  if
    not CollisionEnabled()
    --- Magic effect enums are strings now
    --- This is why you use the enum values :)
    ---@diagnostic disable-next-line: param-type-mismatch
    or GetMagicEffect(ActiveEffects, LevitateEffect).magnitude > 0
  then
    PlaylistState.movementMode = 'flying'
  elseif IsSwimming(self) then
    PlaylistState.movementMode = 'swimming'
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

local initialUpdateFunction
if IsSoundEnabled then
  initialUpdateFunction = function()
    if not SilenceManager:silenceActive() then currentUpdateHandler = updatePlaylistState end
  end
else
  -- Normally, the silenceManager is the first step in the chain.
  -- But, since sound can't be disabled at runtime we skip the SilenceManager update entirely
  -- if it's not enabled to get fresher state
  initialUpdateFunction = updatePlaylistState
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

  PlaylistEnv = PlaylistLoader()

  if not PlaylistEnv then return end

  PlaylistLoader, resolvePlaylist = nil, realResolvePlaylist
  TableSort(MusicManager.explorePlaylists, MusicManager.priorityThenRegistration)
  TableSort(MusicManager.battlePlaylists, MusicManager.priorityThenRegistration)
  TableSort(MusicManager.specialPlaylists, MusicManager.priorityThenRegistration)

  storage.playerSection('SettingsS3Music'):subscribe(async:callback(function(_, key)
    if key == 'BannerEnabled' then
      MusicManager.updateBanner()
    elseif key == 'MusicEnabled' then
      musicUtil.debugLog('Music state changed to: %s', MusicSettings.MusicEnabled)

      MusicManager.forceSkip = false
      clearQueuedData()

      if MusicSettings.MusicEnabled then
        currentUpdateHandler = initialUpdateFunction
      else
        currentUpdateHandler = NullFunction

        if IsMusicPlaying() then
          StopMusic()
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

handlePlayback = function(_)
  currentUpdateHandler = initialUpdateFunction

  if queuedEvent.name ~= '' then
    return SendEvent(self, queuedEvent.name, queuedEvent.data) or clearQueuedData()
  end

  local musicPlaying = IsMusicPlaying()

  -- Resolver flagged a new playlist this tick
  if resolverDirty then
    resolverDirty = false

    if not desiredPlaylist then
      if musicPlaying then
        StopMusic()
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
      and TrackSelection.canSwitchPlaylist(MusicManager.currentPlaylist, desiredPlaylist)
    then
      MusicManager.forceSkip = true
    elseif desiredPlaylist ~= MusicManager.currentPlaylist and didTransition then
      local isExterior = PlaylistState.cellIsExterior
      local friendlyEnter = not PlaylistState.cellHasHostileActors
      local hostileEnter = PlaylistState.cellHasHostileActors

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
    return resolvePlaylist()
  end

  if target ~= MusicManager.currentPlaylist then
    TrackSelection.switchPlaylist(target, PlaybackParams)
  else
    MusicManager.currentTrack = TrackSelection.selectTrackFromPlaylist(target.id)
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
    StreamMusic(eventData.trackName, PlaybackParams)
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
      CombatState.batchPoll(dt)
      currentUpdateHandler(dt)
    end,

    onSave = function()
      local playlistStates = {}

      for playlistId, playlist in next, MusicManager.registeredPlaylists do
        playlistStates[playlistId] = playlist.active
      end

      return {
        playlistStates = playlistStates,
        deathTrack = MusicManager.getDeathTrack(),
      }
    end,

    onLoad = function(data)
      if not data then return end

      if data.playlistStates then
        for playlistId, playlistState in pairs(data.playlistStates) do
          activePlaylistSettings:set(playlistId .. 'Active', playlistState)
        end
      end

      if data.deathTrack then MusicManager.setDeathTrack(data.deathTrack) end
    end,
  },
  eventHandlers = {
    Died = function()
      SendEvent(
        self,
        'S3maphoreSpecialTrack',
        { trackPath = MusicManager.getDeathTrack(), reason = MusicManager.STATE.Died }
      )
      currentUpdateHandler = NullFunction
    end,

    ---@param eventData CombatTargetChangedData
    OMWMusicCombatTargetsChanged = function(eventData)
      if IsDead(self) then return end

      CombatState.onTargetsChanged(eventData.actor, eventData.targets)

      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end

      musicUtil.debugLog('Updating playlist due to combat target change: %s', eventData.actor)
      resolvePlaylist()
    end,

    S3LFCellChanged = function(oldCellId)
      CombatState.resetPollCycle()
      didTransition, wasExterior = true, PlaylistState.cellIsExterior

      updateCellMetadata()

      if PlaylistLoader then return end

      musicUtil.debugLog 'Requesting CellPresence update from PLAYER scope'
      SendGlobalEvent('S3maphoreUpdatePresence', { self.object, oldCellId })
      waitingOnPresence = true
    end,

    S3maphoreToggleMusic = function(enabled)
      MusicManager.overrideMusicEnabled(enabled)
      if not waitingOnPresence and MusicSettings.MusicEnabled then resolvePlaylist() end
    end,

    S3maphoreSkipTrack = function()
      currentUpdateHandler = initialUpdateFunction
      MusicManager.skipTrack()
      if not waitingOnPresence then resolvePlaylist() end
    end,

    S3maphoreSpecialTrack = function(eventData)
      MusicManager.playSpecialTrack(eventData.trackPath, eventData.reason)
    end,

    S3maphoreSetDeathTrack = MusicManager.setDeathTrack,

    S3maphoreResetDeathTrack = MusicManager.resetDeathTrack,

    S3maphoreSetPlaylistActive = function(eventData)
      if PlaylistLoader then error 'S3maphoreSetPlaylistActive called during initialization!' end

      musicUtil.debugLog(Strings.ChangingPlaylist, eventData.playlist, eventData.state)

      MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end
      resolvePlaylist()
    end,

    ---@param eventData S3maphorePlaybackChangeEventData
    S3maphoreMusicStopped = function(eventData)
      musicUtil.debugLog(Strings.MusicStopped, eventData.reason)

      MusicManager.updateBanner()
    end,

    S3maphoreCellPresenceUpdated = function()
      waitingOnPresence = false
      musicUtil.debugLog 'Resolving playlist after cell presence update!'
      resolvePlaylist()
      currentUpdateHandler = initialUpdateFunction
    end,

    S3maphoreWeatherChanged = function(weatherName)
      if PlaylistLoader then error 'S3maphoreWeatherChanged called during initialization!' end

      PlaylistState.weather = weatherName

      musicUtil.debugLog(Strings.WeatherChanged, weatherName)

      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end

      resolvePlaylist()
      currentUpdateHandler = initialUpdateFunction
    end,

    ---@param hitObject openmw.LObject
    S3maphoreClearTargetCache = function(hitObject)
      if PlaylistLoader or not CombatState.actorIsInCombat(hitObject.id) then return end

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
      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end
      musicUtil.debugLog('Performing playlist resolution after state change! Flags: %s', flags)
      resolvePlaylist()
      currentUpdateHandler = initialUpdateFunction
    end,

    S3maphoreTrackChanged = MusicManager.callTrackChangedHandlers,
  },
}
