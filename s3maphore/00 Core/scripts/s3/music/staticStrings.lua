---@class S3maphoreStaticStrings
local Strings = {
    ChangingPlaylist = 'Setting playlist %s to %s',
    CombatTargetCacheStr = '%s%s',
    FailedToLoadPlaylist = 'Failed to load playlist file: %s\nErr: %s',
    FallbackPlaylistDoesntExist =
    'Playlist %s requested to use tracks from backup playlist %s, but it isn\'t registered! Falling back to the default.',
    InterruptModeFallthrough =
    'Playlist Interrupt Modes Fell Through!\nOld Playlist: %s Interrupt Mode: %s\nNew Playlist: %s InterruptMode: %s',
    MusicStopped = 'Music stopped: %s',
    NextTrackIndexNil = 'Can not fetch track: nextTrackIndex is nil',
    NoTrackPath = 'Can not fetch track with index %s from playlist \'%s\'.',
    PlaylistNotRegistered = 'Playlist %s has not been registered!',
    TrackChanged = 'Track changed! Current playlist is: %s Track: %s',
    WeatherChanged = 'Weather changed to %s',
}

return Strings
