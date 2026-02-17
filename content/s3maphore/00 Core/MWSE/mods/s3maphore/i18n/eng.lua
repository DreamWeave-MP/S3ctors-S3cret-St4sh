return
{
    Music = "S3maphore - MWSE Music",
    settingsPageDescription = "Enable and disable playback, specific playlists, battle music, and playlist override behavior.",

    musicSettings = "Music Configuration",

    DebugEnabled = "Enable Debug Messages",
    DebugEnabledDescription = "Whether to show debug messages in MWSE.log",

    MusicEnabled = "Enable Music",
    MusicEnabledDescription = "Whether or not S3maphore will play any music.\nUseful when overriding its builtin behavior to allow something else to control music playback.",

    PlaylistSelection = "Enable/Disable Playlists",

    CurrentPlaylistSelection = "Current Playlist",
    CurrentPlaylistSelectionDescription = "Playlist currently selected in the scroller.\nPlaylists are sorted alphabetically.\nResetting this group will cause all playlists to revert to their default active states.",

    --PlaylistActivity = "",

    PlaylistActiveState = "Playlist State",
    PlaylistActiveStateDescription = "Whether or not the playlist will be selected for playback at all.\n\nWARNING = This does not mean the playlist will be played immediately, it simply means it *can* be played under the conditions it defines.\n\nNOTE = If this option is disabled, it means you have not loaded any tracks this playlist defines and it would never play anyway.",

    BannerEnabled = "Show Track Info",
    BannerEnabledDescription = "Displays the current playlist and track name at the top of the screen, if localizations for the playlist are available.",

    ResetAllPlaylists = "Reset All Playlists",
    ResetAllPlaylistsDescription = "Set all playlists back to their default active states.",
    ResetButtonLabel = "Reset",

    BattleEnabled = "Enable Battle Music",
    BattleEnabledDescription = "If off, all battle playlists will be skipped.",

    NoInterrupt = "Finish Previous Track",
    NoInterruptDescription = "Allow finishing the previous song when the current playlist changes.\n\nOnly affects playlists with the same interrupt priority, so entering a Dwemer dungeon while an Ashlands track is playing,\nwill mean the Dwemer track does not start, until the Ashland one has finished.\n\nGenerally playlists will interrupt one another in order of Explore -> Battle -> Special, if their interrupt modes are different.",

    ForcePlaylistChangeOnOverworldTransition = "Allow Overworld Playlist Override",
    ForcePlaylistChangeOnOverworldTransitionDescription = "If on, overrides the finish previous track setting when outdoors.\n\nThis setting takes playlist priority into account, so that, if on, a city or faction-based playlist will override a region-based one, but not vice-versa.",

    ForcePlaylistChangeOnHostileExteriorTransition = "Allow Dungeon Playlist Override",
    ForcePlaylistChangeOnHostileExteriorTransitionDescription = "If on, overrides the finish previous track setting when entering an interior with hostile targets.\n\nNote that this means overrides will not occur after a dungeon or cell has been cleared of enemies.",

    ForcePlaylistChangeOnFriendlyExteriorTransition = "Allow Friendly Interior Playlist Override",
    ForcePlaylistChangeOnFriendlyExteriorTransitionDescription = "If on, overrides the finish previous track setting when entering an interior with no hostile targets.",

    FadeOutDuration = "Default Fade Duration",
    FadeOutDurationDescription = "Fadeout time between tracks used if the current playlist doesn't define its own fadeout timer.",

    SilenceConfiguration = "Silence Configuration",

    GlobalSilenceToggle = "Enable Silence Tracks",
    GlobalSilenceToggleDesc = "Whether or not there may be a period of silence between each song played.",

    GlobalSilenceChanceName = "Global Silence Chance",
    GlobalSilenceChanceDesc = "The chance that a playlist which does not define its own silence rules may not immediately play another song.",

    ExploreSilenceMinDuration = "Minimum Explore Silence Duration",
    ExploreSilenceMinDesc = "The minimum possible duration for silence when an explore playlist is running.",

    ExploreSilenceMaxDuration = "Maximum Explore Silence Duration",
    ExploreSilenceMaxDesc = "The maxiumum possible duration for silence when an explore playlist is running.",

    BattleSilenceMinDuration = "Minimum Battle Silence Duration",
    BattleSilenceMinDesc = "The minimum possible duration for silence when a battle playlist is running.",

    BattleSilenceMaxDuration = "Maximum Battle Silence Duration",
    BattleSilenceMaxDesc = "The maxiumum possible duration for silence when a battle playlist is running."
}