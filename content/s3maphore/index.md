---
title: S3maphore
description: Modern music management for OpenMW, inspired by MUSE and Dynamic Music.
date: 2025-06-06

taxonomies:
  tags:
    - Music
    - OpenMW-Lua
    - Frameworks

extra:
  nexus_id: 56836
  nexus_group_id: 3323002

  install_info:
    data_directories:
        - "# Required"
        - 00 Core
        - "# Recommended"
        - 01 Tamriel Rebuilt Playlists
        - 02 Project Cyrodiil Playlists
        - 03 Muse Expansion Playlists
        - "# Extended/Unsupported"
        - 04 Vindsvept Solstheim
        - 05 Secrets of the Crystal City
        - 06 Songbook of the North
        - 08 Redguard Music
        - 09 Nordic Lands
        - 10 Inns and Taverns
        - 11 Daggerfall Guild Themes
        - 14 General Dungeon
        - 15 Provincial Music
        - 18 Better Music System Redone
        - "# Shitpost Playlists"
        - 12 BBL Drizzy
        - 16 Bgi Inor
        - "# Starwind only!"
        - 07 Starwind Playlists

    content_files:
        - S3maphore.esp

  version: 0.94
---

Your music, just the way you want it. No compromises, no bullshit, with a focus on scalability and extreme attention to performance optimization.

<!-- more -->

<div align="center">

  <figure>
    <img src="../img/S3maphoreBanner.png" alt="semaphore icon" width="512" height="608" />
    <figcaption><h2 class="notoc">Brought to You by the DreamWeave-MP</h2></figcaption>
  </figure>

  <br>
  <br>
</div>

## Requirements

<div align="center">
    <a href="https://www.nexusmods.com/morrowind/mods/56417"><img src="../img/h3Required.svg" alt="H3lp Yours3lf"></a>
    <a href="https://openmw.org/downloads"><img src="../img/openmwRequired.svg" alt="OpenMW 0.51"></a>
    <br>
</div>

## Introduction

In order to understand how S3maphore works, you need to understand three basic ideas:

1. __Playlist__ - Just like in real life, S3maphore playlists are contextual. You may have a Spotify playlist for working out, long drives, or having a bad day - S3maphore playlists can run indoors, outdoors, in hostile areas, in bad weather, or even if you're using a specific type of magic.
2. __Priority__ - If two playlists should play at the same time, priority decides which one wins. Battle playlists don't have special powers - it's just a combat check in the rule and a really high priority value, so they win when you're actually fighting.
3. __Playdeck__ - S3maphore loads every playlist it can find in your OpenMW install and orders them by priority - like a big deck of cards. When conditions change, it deals the topmost playlist whose conditions are met.

Playlists are the atom, priority resolves conflicts, and the deck puts both into practice.

That's all you need to really understand this mod. No file shuffling, config digging, or command-line wizardry is required.

## Backstory

During OpenMW 0.49's development, music playback was dehardcoded and the groundwork for an incredibly powerful system was laid in OpenMW.

However, the public API was removed before release, and nothing has ever replaced it.

Music and programming are my two biggest passions in life. The solution seemed obvious - so S3maphore was made to fix that.

Why call it S3maphore?

In computing, a semaphore is a synchronization primitive designed to allow concurrent access to systems which may really only have one consumer at a time.

This definition and application both date back to mid-nineteenth century, when the semaphore was first developed as a safety measure for signalling train drivers on railways.

This one is no different - S3maphore is a full replacement for OpenMW's builtin music handling that can be configured or permutated in any way you can imagine.

Should you imagine one which it does not address, please let me know so we can improve it together.

## Installation

### For Most Users

Here's the honest truth: installing S3maphore is not hard. If you already know how to install any other OpenMW mod, you already know how to install this one - same mod manager, same drag-and-drop, nothing special going on under the hood.

Only two things separate you from a working setup:

Knowing how to install an OpenMW mod at all. If you don't, watch this for the short version or this for the long one. This is genuinely the only technical skill required.
Knowing what music you actually want to hear. That part's on you - but the compatibility list below will get you most of the way there.

Got both of those covered? Here's all you do:

1. Install H3lp Yours3lf (see Requirements above) - it has to go in first.
2. Install 00 Core. This is the foundation of the whole mod - vanilla Explore/Battle, standalone, works with zero other mods installed.
3. Add 01 Tamriel Rebuilt Playlists through 03 Muse Expansion Playlists if you want broader coverage. Recommended for most people, but not required for any of the above to work.
4. Download whichever actual music mods you want from the compatibility list below (found one that's missing? Let me know!).
5. Enable S3maphore.esp in your content list, same as any other plugin.

The numbers on the module folders (00, 01, 02...) are just there to keep things sorted in your mod manager - they don't control load order or affect anything in-game. Install whatever subset you want, in whatever order you want.

You genuinely cannot break your game by installing extra modules you don't need. If S3maphore loads a playlist and can't find any matching tracks for it, that playlist is just quietly ignored - no conflicts, no crashes, nothing to troubleshoot. When in doubt, install more rather than less; you can always prune later.

To add your own tracks - nothing has changed. Vanilla Morrowind Explore and Battle playlists still work the same way they always did: drop new files into Music\Explore or Music\Battle and the game picks them up. S3maphore extends this to every playlist in the deck that chooses to support it - most do. Deviations from this default are called out in the module list below.

### Compatibility With Other Music Mods

Dynamic Music and MUSE soundbanks are not natively supported. I have done my best to port every MUSE module and Dynamic Music soundbank I could, but, 100% coverage cannot be guaranteed by me alone. Your bug reports are so valuable!

Any mods which simply add to or replace music Morrowind already provides (EG, in the `Battle`, `Explore`, or `Special` folders) are natively compatible with zero extra work.

For example - Tamriel Rebuilt inclues an optional TRMusic addon. It adds new songs to both `Music/Explore` and `Music/Battle`. You install it the same way you always did. Nothing to see here.

Every `.lua` file, in every module, is called a playlist *array*. This is just because it can have more than one playlist in it. Each playlist in the array points at either a folder to load tracks from, or a set of specific tracks to play.

If a playlist is loaded, but no matching tracks are found, it's simply ignored. This means you can never encounter compatibility issues by installing S3maphore modules you don't actually need.

Compatibility with Dynamic Music mods is provided on a case-by-case basis as they tend to be more specialized.

Some mods use MWScript to play music - I'm not bothering to document those as their compatibility surface is unchanged by this mod.

### How Modules Work

You know how playlists work already. But most playlists also need actual music tracks to go along with them - either from another mod, or you. A few modules include their own music.

Every folder in this mod is a *module*: it contains one or more `.lua` files, which may have one or more playlists in them.

Modules come in one of three flavors:

- __*Playlist-Only*__ - These modules only include playlist arrays and *MUST* be paired with a music mod, or your own tracks, to actually work.
- __*Standalone*__ - These modules were made specifically for S3maphore and include both playlists *and* tracks. No accompanying mod is needed for these modules.
- __*Pure Replacement*__ - The rarest case. In some circumstances, old mods provided something akin to __*Playlist-Only*__ S3maphore modules. __*Pure Replacement*__ modules for S3maphore replace these and may or may not include their own tracks.

All playlist modules include empty folders where you can put your own songs. The vanilla `Explore` and `Battle` playlists, for example, work exactly like they always did - drop a new `.mp3` into `Music\Explore` or `Music\Battle`, and the game picks it up. S3maphore extends this to every playlist in the deck that chooses to do so. Not every playlist works this way, but most do.

If a playlist is loaded but no matching tracks are found, it's simply ignored. Installing a module you don't need can never cause compatibility problems - you'll just never hear it.

### The Modules

Compatibility is defined at the module level, not the playlist level. Each entry below tells you what folders to enable, what playlists they provide, where your own tracks go, and which mod actually provides the tracks you're __expected__ to use.

#### Required
The engine itself. Includes the built-in `Explore` and `Battle` playlists, which are yours to move, remove, or replace at your leisure.

Natively compatible with any mod that adds music to those folders.

- 00 Core:
  Type: __*Standalone*__
    Playlists:
        Explore: `Music\Explore`
        Battle: `Music\Battle`
    Compatible with:
        - [0 A.D Music For Morrowind](https://www.nexusmods.com/morrowind/mods/45113)
        - [AMAR - Swordsman - A Music and Ambience Replacer](https://www.nexusmods.com/morrowind/mods/57456) NOTE: This one includes a large number of silence tracks which I recommend deleting.
        - [Battle for Wesnoth Music for Morrowind](https://www.nexusmods.com/morrowind/mods/45540)
        - [Luigi's More Music for Morrowind](https://www.nexusmods.com/morrowind/mods/53432)
        - [Morrowind Music Overdose](https://www.nexusmods.com/morrowind/mods/44084)
        - [Morrowind Music Overdose II](https://www.nexusmods.com/morrowind/mods/44083)
        - [Morrowind Music Overdose III](https://www.nexusmods.com/morrowind/mods/43410)
        - [Morrowind Music Overdose IV](https://www.nexusmods.com/morrowind/mods/43407)
        - [Stronghold Music](https://www.nexusmods.com/morrowind/mods/50326)
        - [Tamriel Rebuilt - TRMusic Addon](https://www.nexusmods.com/morrowind/mods/42145)
        - [Vindsvept Fantasy Music Overhaul](https://www.nexusmods.com/morrowind/mods/45089) WARNING: This one is actually not recommended in favor of `04 Vindsvept Solstheim` but it still works
        - [Witcher 3 Music Overhaul](https://www.nexusmods.com/morrowind/mods/52562)
        - [Witcher Music](https://www.nexusmods.com/morrowind/mods/45369)
        # Starwind-Only
        - [Alternate Cantina Music For Starwind](https://www.nexusmods.com/morrowind/mods/52171)
        - [Alternate music for Starwind](https://www.nexusmods.com/morrowind/mods/52090)
        - [Starwind - KOTOR Music](https://www.nexusmods.com/morrowind/mods/53453)
        - [Starwind Music Replacer - Star Wars Conquest Mount and Blade soundtrack](https://www.nexusmods.com/morrowind/mods/52370)

#### Recommended

- 01 Tamriel Rebuilt Playlists:
    Type: __*Playlist-Only*__
    Requires: [Tamriel Rebuilt - Original Soundtrack](https://www.nexusmods.com/morrowind/mods/47254)
    Playlists (folder-derived — each reads from `Music\<playlist id>\`, with two shared fallback dirs `Music\ms\general\trairdepths` and `Music\ms\general\tr dungeon`):
      - ms/region/aanthirin
      - ms/region/armun ashlands region
      - ms/region/grey meadows region
      - ms/region/lan orethan
      - ms/region/mournhold hills
      - ms/region/seas
      - ms/region/telvannis
      - ms/region/velothis upper
      - ms/region/sacred lands region
      - ms/region/telvanni isles
      - ms/cell/imperialcity
      - ms/cell/mourncity
      - ms/cell/telcity
      - ms/interior/tr dwemer
      - ms/interior/tr cave
      - ms/interior/tr tomb
      - ms/region/alt orethan region _(disabled — serves as the Lan Orethan fallback target)_
      - sacred lands region fallback _(cascade-only — no tracks of its own)_
      - Tamriel Rebuilt - Thirr _(track-listed — reads `thirr*.mp3` from `Music\ms\region\aanthirin`)_

- 02 Project Cyrodiil Playlists:
    Type: __*Playlist-Only*__
    Requires: [Project Cyrodiil Music - Anvil and Sutch](https://www.nexusmods.com/morrowind/mods/55779)
    Playlists (folder-derived — each reads from `Music\<playlist id>\`):
      - ms/interior/cyrodiil tombs imperial — Abecean Shores: Imperial Crypts
      - ms/interior/cyrodiil tombs colovian — Abecean Shores: Colovian Barrows
      - ms/interior/cyrodiil caves — Abecean Shores: Caves
      - ms/interior/cyrodiil ayleid — Abecean Shores: Ayleid
      - ms/cell/cyrodiil sutch — Abecean Shores: Kingdom of Sutch
      - ms/cell/cyrodiil anvil — Abecean Shores: Kingdom of Anvil
      - ms/cell/nine divine temples — Abecean Shores: Divine Temples
      - ms/region/cyrodiil brennan bluffs — Abecean Shores: Brennan Bluffs
      - ms/region/cyrodiil strident coast — Abecean Shores: Strident Coast
      - ms/region/cyrodiil stirk isle — Abecean Shores: Stirk Isle

#### Extended
#### Shitpost

## Usage

Make sure to install the playlist files *and* tracks for any S3maphore playlist arrays you install. In the settings menu, you can toggle S3maphore debug messages and the onscreen track/playlist name display.

All S3maphore playlists may ship a unique l10n context with the appropriate playlist/name strings for your preferred language. Presently, only English is supported, but translations are greatly welcomed!

Also in the settings menu, you can scroll through registered playlists and manually enable/disable them completely.

TIP: If you can't toggle a playlist on or off, that means S3maphore couldn't find any of the tracks this playlist has registered in your game.

Finally, pressing F8 will always skip the current track if one is playing - if the shift key is held when pressing F8, it will toggle music playback on or off entirely.

### For Playlist Authors

The full [S3maphore modder documentation](@/s3maphore/modder-docs.md) covers playlist creation, playlist rules, events, localization, and the public interface.

### Settings

S3maphore's main settings group is a `Player` scoped storage section called `SettingsS3Music`. It contains the following keys and values:

1.`Enable Debug Messages` - `Checkbox` - Whether or not to use verbose logging. Press F10 in-game or veiew openmw.log for more details. Every line with S3maphore log outputs will start with `[ S3MAPHORE ]:`

1. `Enable Music` - `Checkbox` - Whether or not S3maphore will play music *at all*, for the purposes of temporarily stopping playback to be managed by something else

1. `Show Track Info` - `Checkbox` - Whether or not the current playlist and track names will be shown when S3maphore changes songs.

1. `Enable Combat Music` - `Checkbox` - If this is disabled, combat music will never play. Added by request.

1. `Finish Previous Track` - `Checkbox` - Enabled by default, this setting prevents playlist changes with the same interrupt mode from interrupting music playback.

1. `Allow Friendly Interior Playlist Override` - `Checkbox` - disabled by default, this setting allows overriding the finish previous track setting, when entering a friendly interior, such as a tavern.

1. `Allow Dungeon Playlist Override` - `Checkbox`  - enabled by default, overrides the finish previous track setting when entering a dungeon.

1. `Allow Overworld Playlist Override` - `Checkbox` - disabled by default, allows playlist changes while traversing exteriors to override one another. May be removed in a later version as this was the main reason `Finish Previous Track` was implemented in the first place.

1. `Default Fade Duration` - `Number` - Global fadeOut duration used between tracks if a playlist doesn't specify its own.

1. `Enable Silence Tracks` - `Checkbox` - Enabled by default, allows S3maphore to stop music playback for a specified amount of time between track changes in the same playlist.

1. `Global Silence Chance` - `Number` - Defaults to `0.15`, this is the global chance for silence tracks to play. If a playlist specifies this value itself, that is used instead.

1. `Explore Silence Min Duration` - `Number` - Minimum duration for playback to stop between tracks, during Explore playlists. Randomly selected between this and the maximum value.

1. `Explore Silence Max Duration` - `Number` - Maximum duration for playback to stop between tracks, during Explore playlists. Randomly selected between this and the minimum value.

1. `Battle Silence Min Duration` - `Number` - Minimum duration for playback to stop between tracks, during Battle playlists. Randomly selected between this and the maximum value.

1. `Battle Silence Max Duration` - `Number` - Maximum duration for playback to stop between tracks, during Battle playlists. Randomly selected between this and the minimum value.

There also is another `Player` scoped storage section of note - `S3maphoreActivePlaylistSettings`. All playlists registered by S3maphore can have their active states set by other scripts by setting the key `${PLAYLISTNAME}Active` to `true` or `false`. S3maphore will then automatically respond to this change and disable/enable the playlist accordingly. Every playlist can also be permanently toggled on or off in the settings menu manually.

{% credits(default=true) %}
All code was written by Dave Corley under the GPL3 license. Please enjoy my mod, hack away as you please, and respect the freedoms of your fellow modders and players in the meantime.  
I pour my entire heart, soul, and talent into this community. If you appreciate my work, please, [please consider supporting me on Ko-Fi.](https://ko-fi.com/magicaldave)  
I would do this full-time if I could only afford to.  
Thanks for listening <3 
{% end %}

You see S3maphore and your brain fills in the vowel without thinking.
