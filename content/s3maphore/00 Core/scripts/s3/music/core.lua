---@module 'doc.s3maphoreTypes'
---@omw-context player

local error, floor, pairs, next, Remove, StrFormat, TableSort, type =
  error, math.floor, pairs, next, table.remove, string.format, table.sort, type

local ambient = require 'openmw.ambient'
local async = require 'openmw.async'
---@type openmw.core
local core = require 'openmw.core'
local input = require 'openmw.input'
local self = require 'openmw.self'
local storage = require 'openmw.storage'
local types = require 'openmw.types'

local I = require 'openmw.interfaces'
local s3lf = require('openmw.interfaces').s3.lf

local Magic = require 'scripts.s3.spellUtil'
local StateMachine = require('scripts.s3.statemachine').new()
local clear = require 'scripts.s3.clear'
StateMachine:state('idle', {})

---@type CombatState
local CombatState = require 'scripts.s3.music.combatState'
local MusicManager = require 'scripts.s3.music.musicManager'
local MusicSettings = require 'scripts.s3.music.musicSettings'
---@type function?
local PlaylistLoader = require 'scripts.s3.music.playlistLoader'
local PlaylistModule = require 'scripts.s3.music.playlistRules'
local PlaylistPriority = require 'doc.playlistPriority'
local PlaylistState, updateCellMetadata = require 'scripts.s3.music.playlistState'
local DisplayTier = require 'scripts.s3.music.playlistEditor.displayTier'
local PlaylistEditor = require 'scripts.s3.music.playlistEditor'
local SilenceManager = require 'scripts.s3.music.silenceManager'
local TrackSelection = require 'scripts.s3.music.trackSelection'
local musicUtil = require 'scripts.s3.music.util'
---@type Rand
local randomGen = require 'scripts.s3.randomGen'

---@type S3maphorePlaylistEnv
local PlaylistEnv

--- updateCellMetadata for me, but not for thee
---@diagnostic disable-next-line: invisible
updateCellMetadata, PlaylistState.updateCellMetadata = PlaylistState.updateCellMetadata, nil

---@type PlaylistRules
local PlaylistRules = PlaylistModule.rules
local clearJournalCache = PlaylistModule.clearJournalCache
local clearGlobalCombatTargetCache = PlaylistModule.clearGlobalCombatTargetCache

local activePlaylistSettings = storage.playerSection 'S3maphoreActivePlaylistSettings'

local CollisionEnabled, IsDead, IsSoundEnabled, IsMusicPlaying, IsSwimming, SendEvent, SendGlobalEvent, StopMusic, StreamMusic, GetSelectedSpell, GetStance =
  require('openmw.debug').isCollisionEnabled,
  types.Actor.isDead,
  core.sound.isEnabled(),
  ambient.isMusicPlaying,
  types.Actor.isSwimming,
  self.sendEvent,
  core.sendGlobalEvent,
  ambient.stopMusic,
  ambient.streamMusic,
  types.Actor.getSelectedSpell,
  types.Actor.getStance

local ActiveEffects, LevitateEffect =
  types.Actor.activeEffects(self), core.magic.EFFECT_TYPE.Levitate
local GetMagicEffect = ActiveEffects.getEffect

local lastSelectedSpell, lastStance = GetSelectedSpell(self), GetStance(self)
local lastSpellSchool = lastSelectedSpell and Magic:getSpellSchool(lastSelectedSpell)

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

local function roundToHundredths(n) return floor(n * 100 + 0.5) / 100 end

local resolvePlaylist = function() end

local function clearQueuedData()
  if type(queuedEvent.data) ~= 'table' then queuedEvent.data = queuedEvent.backup end
  clear(queuedEvent.data)
  queuedEvent.name = ''
end

StateMachine:state('update_playlist_state', function(dt)
  -- When sound is enabled, check silence before doing state work.
  -- When sound is disabled, skip the check entirely and proceed to state update.
  if IsSoundEnabled and SilenceManager:silenceActive() then return end

  --- Explicitly advance the generator on each round-robin cycle to improve distribution
  randomGen.int()

  if dt == 0 then return StateMachine:jump 'handle_playback' end

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

  PlaylistState.normalizedHealth = roundToHundredths(s3lf.health.current / s3lf.health.base)
  PlaylistState.normalizedMagicka = roundToHundredths(s3lf.magicka.current / s3lf.magicka.base)
  PlaylistState.normalizedFatigue = roundToHundredths(s3lf.fatigue.current / s3lf.fatigue.base)

  local currentSpell = GetSelectedSpell(self)
  local currentSpellSchool = currentSpell and Magic:getSpellSchool(currentSpell)
  local spellSchoolChanged = lastSpellSchool ~= currentSpellSchool
  lastSpellSchool = currentSpellSchool
  PlaylistState.selectedSpellSchool = currentSpellSchool

  local currentStance = GetStance(self)
  local stanceChanged = lastStance ~= currentStance
  lastStance = currentStance

  if TODChanged or movementChanged or spellSchoolChanged or stanceChanged then
    queuedEvent.name = 'S3maphoreStateChanged'
    local flags = 0
    if TODChanged then flags = flags + MusicManager.STATE_FLAGS.TOD end
    if movementChanged then flags = flags + MusicManager.STATE_FLAGS.MOVEMENT end
    if spellSchoolChanged then flags = flags + MusicManager.STATE_FLAGS.SPELL_SCHOOL end
    if stanceChanged then flags = flags + MusicManager.STATE_FLAGS.STANCE end
    queuedEvent.data = flags
  end

  StateMachine:transition 'handle_playback'
end)

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

--- Validate all registered playlists' fallback references after loading completes.
--- Strips unregistered fallback playlist IDs and logs each removal so mod authors
--- can detect configuration errors immediately rather than at track-selection time.
local function validatePlaylistReferences()
  local dirty = false
  for playlistId, playlist in next, MusicManager.registeredPlaylists do
    local fallback = playlist.fallback
    if fallback and fallback.playlists then
      for i = #fallback.playlists, 1, -1 do
        local fallbackId = fallback.playlists[i]
        if not MusicManager.registeredPlaylists[fallbackId] then
          musicUtil.debugLog(
            'Removed unregistered fallback playlist "%s" from "%s"\'s fallback list.',
            fallbackId,
            playlistId
          )
          Remove(fallback.playlists, i)
          dirty = true
        end
      end
    end
  end
  if dirty then musicUtil.debugLog 'Fallback reference cleanup completed.' end
end

StateMachine:state('init_player', function()
  if not PlaylistLoader then error 'Playlist loader not found during initialization!' end

  PlaylistEnv = PlaylistLoader()

  if not PlaylistEnv then return end

  PlaylistLoader, resolvePlaylist = nil, realResolvePlaylist
  PlaylistEditor.init()
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
        StateMachine:transition 'update_playlist_state'
      else
        StateMachine:jump 'idle'

        if IsMusicPlaying() then
          StopMusic()

          queuedEvent.data.reason = MusicManager.STATE.Disabled
          SendEvent(self, 'S3maphoreMusicStopped', queuedEvent.data)
        end

        MusicManager.currentPlaylist = nil
        MusicManager.currentTrack = nil
        desiredPlaylist, resolverDirty = nil, false
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

  validatePlaylistReferences()

  musicUtil.debugLog 'Coroutine load complete, initializing cell presence'
  StateMachine:transition 'idle'
end)

StateMachine:state('handle_playback', function()
  StateMachine:transition 'update_playlist_state'

  if queuedEvent.name ~= '' then
    SendEvent(self, queuedEvent.name, queuedEvent.data)
    clearQueuedData()
    return
  end

  local musicPlaying = IsMusicPlaying()

  -- Resolver flagged a new playlist this tick
  if resolverDirty then
    resolverDirty = false

    if not desiredPlaylist then
      if musicPlaying then StopMusic() end

      MusicManager.currentPlaylist = nil
      MusicManager.currentTrack = nil

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
end)

MusicManager.addTrackChangedHandler(
  ---@param eventData S3maphorePlaybackChangeEventData
  function(eventData)
    musicUtil.debugLog(
      'Track changed! Current playlist is: %s Track: %s',
      eventData.playlistId,
      eventData.trackName
    )

    PlaybackParams.fadeOut = eventData.fadeOut or MusicSettings.FadeOutDuration
    StreamMusic(eventData.trackName, PlaybackParams)
    MusicManager.updateBanner()
  end
)

StateMachine:start 'init_player'

local scriptInterface = {
  interfaceName = 'S3maphore',

  ---@type openmw.interfaces.S3maphore
  interface = {
    actorIsInCombat = CombatState.actorIsInCombat,
    getCombatTargets = CombatState.getCombatTargets,
    isInCombat = CombatState.isInCombat,

    --- Constants
    const = setmetatable({
      STATE = MusicManager.STATE,
      TIME_MAP = MusicManager.TIME_MAP,
      INTERRUPT = MusicManager.INTERRUPT,
      STATE_FLAGS = MusicManager.STATE_FLAGS,
    }, {
      __newindex = function(_, k)
        error(StrFormat('I.S3maphore.const is read-only (attempted to set %s)', k), 2)
      end,
    }),

    --- Playback control
    getEnabled = MusicManager.getEnabled,
    overrideMusicEnabled = MusicManager.overrideMusicEnabled,
    playSpecialTrack = MusicManager.playSpecialTrack,
    setPlaylistActive = MusicManager.setPlaylistActive,
    skipTrack = MusicManager.skipTrack,

    --- Introspection
    getCurrentPlaylist = MusicManager.getCurrentPlaylist,
    getCurrentTrack = MusicManager.getCurrentTrack,
    getCurrentTrackInfo = MusicManager.getCurrentTrackInfo,
    getRegisteredPlaylists = MusicManager.getRegisteredPlaylists,
    getState = MusicManager.getState,
    listPlaylistFiles = MusicManager.listPlaylistFiles,
    listPlaylistsByPriority = MusicManager.listPlaylistsByPriority,
    silenceTime = MusicManager.silenceTime,

    --- Registration and hooks
    addTrackChangedHandler = MusicManager.addTrackChangedHandler,
    registerPlaylist = function(playlist)
      MusicManager.registerPlaylist(playlist)

      if PlaylistLoader then return end

      if playlist.priority <= PlaylistPriority.Special then
        TableSort(MusicManager.specialPlaylists, MusicManager.priorityThenRegistration)
      elseif playlist.priority <= PlaylistPriority.BattleVanilla then
        TableSort(MusicManager.battlePlaylists, MusicManager.priorityThenRegistration)
      else
        TableSort(MusicManager.explorePlaylists, MusicManager.priorityThenRegistration)
      end
    end,

    --- Death track
    getDeathTrack = MusicManager.getDeathTrack,
    resetDeathTrack = MusicManager.resetDeathTrack,
    setDeathTrack = MusicManager.setDeathTrack,

    --- Metadata, state, and direct queries
    playlistMetadata = MusicManager.playlistMetadata,
    playlistTimeOfDay = MusicManager.playlistTimeOfDay,
    rules = PlaylistRules,
    --- Light proxy for state to keep interface callers from
    --- writing or wasting allocations copying read-only versions
    state = setmetatable({}, {
      __index = PlaylistState,
      __newindex = function(_, k)
        error(StrFormat('S3maphore state is read-only (attempted to set %s)', k), 2)
      end,

      __pairs = function() return next, PlaylistState end,
    }),
  },

  engineHandlers = {

    onQuestUpdate = function()
      clearJournalCache()
      resolvePlaylist()
    end,

    onKeyPress = function(key)
      if key.code == input.KEY.F8 then
        if key.withShift then
          -- PlaylistEditor.toggle()
          MusicManager.overrideMusicEnabled()
        else
          SendEvent(self, 'S3maphoreSkipTrack')
        end
      elseif key.code == input.KEY.F4 then
      end
    end,

    onUpdate = function(dt)
      CombatState.batchPoll(dt)
      StateMachine:tick(dt)
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
      StateMachine:jump 'idle'
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
      StateMachine:transition 'update_playlist_state'
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

      musicUtil.debugLog('Setting playlist %s to %s', eventData.playlist, eventData.state)

      MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end
      resolvePlaylist()
    end,

    ---@param eventData S3maphorePlaybackChangeEventData
    S3maphoreMusicStopped = function(eventData)
      musicUtil.debugLog('Music stopped: %s', eventData.reason)

      MusicManager.updateBanner()
    end,

    S3maphoreCellPresenceUpdated = function(cellId)
      if cellId ~= self.cell.id then return end

      waitingOnPresence = false
      musicUtil.debugLog 'Resolving playlist after cell presence update!'
      resolvePlaylist()
      StateMachine:transition 'update_playlist_state'
    end,

    S3maphoreWeatherChanged = function(weatherName)
      if PlaylistLoader then error 'S3maphoreWeatherChanged called during initialization!' end

      PlaylistState.weather = weatherName

      musicUtil.debugLog('Weather changed to %s', weatherName)

      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end

      resolvePlaylist()
      StateMachine:transition 'update_playlist_state'
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
      clearGlobalCombatTargetCache()
      resolvePlaylist()
    end,

    ---@param flags S3maphoreStateChangedFlag
    S3maphoreStateChanged = function(flags)
      if waitingOnPresence or PlaylistState.cellId ~= self.cell.id then return end
      musicUtil.debugLog('Performing playlist resolution after state change! Flags: %s', flags)
      resolvePlaylist()
      StateMachine:transition 'update_playlist_state'
    end,

    S3maphoreTrackChanged = MusicManager.callTrackChangedHandlers,

    ---@param eventData { oldMode: string, newMode: string, arg: any }
    UiModeChanged = function(eventData)
      if eventData.oldMode == I.UI.MODE.Interface and PlaylistEditor.isVisible() then
        PlaylistEditor.hide()
      end
    end,
  },
}

if core.API_REVISION >= 137 then
  scriptInterface.engineHandlers.onViewportResized = function(width, height)
    DisplayTier.refreshDisplayTier(height)
    PlaylistEditor.onViewportResized(width, height)
  end
end

return scriptInterface
