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

  version: 0.95
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

That's all you need to understand the mod. If you use a mod manager, installation is just as straightforward as any other OpenMW mod.

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

### Quick Install

S3maphore is one download containing the core and a collection of optional playlist packs.

1. Install [H3lp Yours3lf](https://www.nexusmods.com/morrowind/mods/56417) first.
2. Download and install S3maphore with your OpenMW mod manager.
3. Keep `00 Core` enabled and enable `S3maphore.esp` in your content list.
4. Start the game. S3maphore works with Morrowind's normal `Explore` and `Battle` music immediately.

The other numbered folders are optional. Install them only when you want playlists for the matching music or content mod. `07 Starwind Playlists` is for Starwind, while `06 Songbook of the North` and `16 Bgi Inor` include their own music. The remaining optional packs mainly provide playlists and need matching music from another mod.

If an optional playlist cannot find any matching tracks, it simply does nothing.

The numbers only identify the modules; they are not load-order numbers.

### Manual Installation

S3maphore contains several OpenMW data directories. Do not copy the contents of the archive directly into Morrowind's `Data Files` folder. Extract the archive to its own folder, then add the numbered folders you want as data directories in `openmw.cfg`.

The config generator below creates the required entries. It includes every S3maphore module; remove any optional `data=` lines you do not want before copying the result into `openmw.cfg`.

{{ install_instructions() }}

### Compatibility With Other Music Mods

Dynamic Music and MUSE soundbanks are not natively supported. I have done my best to port every MUSE module and Dynamic Music soundbank I could, but, 100% coverage cannot be guaranteed by me alone. Your bug reports are so valuable!

Any mods which simply add to or replace music Morrowind already provides (EG, in the `Battle`, `Explore`, or `Special` folders) are natively compatible with zero extra work.

For example - Tamriel Rebuilt inclues an optional TRMusic addon. It adds new songs to both `Music/Explore` and `Music/Battle`. You install it the same way you always did. Nothing to see here.

Every `.lua` file, in every module, is called a playlist *array*. This is just because it can have more than one playlist in it. Each playlist in the array points at either a folder to load tracks from, or a set of specific tracks to play.

For playlist-only modules, missing tracks simply mean that playlist is ignored. Modules that include their own music are the exception; install those only if you want their tracks.

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

If a playlist-only module is loaded but no matching tracks are found, it's simply ignored. Modules that include music are listed above so you can choose whether you want them.

### The Modules

Compatibility is defined at the module level, not the playlist level. Each entry below tells you what folders to enable, what playlists they provide, where your own tracks go, and which mod actually provides the tracks you're __expected__ to use.

#### Required
The engine itself. Includes the built-in `Explore` and `Battle` playlists, which are yours to move, remove, or replace at your leisure.

Natively compatible with any mod that adds music to those folders.

- **00 Core**
  - **Type:** __*Playlist-Only*__
  - **Playlists:**
    - Explore: `Music\Explore`
    - Battle: `Music\Battle`
  - **Compatible with:**
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
    - **Starwind-only:**
      - [Alternate Cantina Music For Starwind](https://www.nexusmods.com/morrowind/mods/52171)
      - [Alternate music for Starwind](https://www.nexusmods.com/morrowind/mods/52090)
      - [Starwind - KOTOR Music](https://www.nexusmods.com/morrowind/mods/53453)
      - [Starwind Music Replacer - Star Wars Conquest Mount and Blade soundtrack](https://www.nexusmods.com/morrowind/mods/52370)

#### Recommended

- **01 Tamriel Rebuilt Playlists**
  - **Type:** __*Playlist-Only*__
  - **Requires:** [Tamriel Rebuilt - Original Soundtrack](https://www.nexusmods.com/morrowind/mods/47254)
  - **Playlists:** folder-derived — each reads from `Music\<playlist id>\`, with two shared fallback dirs `Music\ms\general\trairdepths` and `Music\ms\general\tr dungeon`
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

- **02 Project Cyrodiil Playlists**
  - **Type:** __*Playlist-Only*__
  - **Requires:** [Project Cyrodiil Music - Anvil and Sutch](https://www.nexusmods.com/morrowind/mods/55779)
  - **Playlists:** folder-derived — each reads from `Music\<playlist id>\`
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

#### MUSE Expansions

These are S3maphore playlist definitions for Scipio219's MUSE expansions. They do not include the music itself. Install the original expansion from Nexus, then enable the matching playlist module here. Every path below is relative to the `Music` folder in your OpenMW data directory.

- **Ashlander** — [Nexus](https://www.nexusmods.com/morrowind/mods/51255)
  - `Muse Ashlanders.lua`
    - `Music/ms/cell/ashlander`
    - `Music/ms/combat/ashlander`
  - `Muse Cavern of the Incarnate.lua`
    - `Music/ms/cell/incarnate`
- **Dwemer** — [Nexus](https://www.nexusmods.com/morrowind/mods/51169)
  - `Muse Dwemer.lua`
    - `Music/ms/cell/dwemer`
    - `Music/ms/combat/dwemer`
- **Sixth House** — [Nexus](https://www.nexusmods.com/morrowind/mods/51082)
  - `Muse Sixth House.lua`
    - `Music/ms/cell/6thhouse`
    - `Music/ms/combat/dagoth`
    - `Music/ms/combat/dagoth ur`
- **Tomb** — [Nexus](https://www.nexusmods.com/morrowind/mods/51407)
  - `Muse Tombs.lua`
    - `Music/ms/cell/tomb`
    - `Music/ms/combat/tomb`
- **Daedric** — [Nexus](https://www.nexusmods.com/morrowind/mods/51993)
  - `Muse Daedric.lua`
    - `Music/ms/cell/daedric`
    - `Music/ms/combat/daedric`
- **Empire** — [Nexus](https://www.nexusmods.com/morrowind/mods/52814)
  - `Muse Empire.lua`
    - `Music/ms/cell/empire`
    - `Music/ms/cell/imperial`
    - `Music/ms/combat/empire`
- **Hlaalu** — [Nexus](https://www.nexusmods.com/morrowind/mods/54639)
  - `Muse Hlaalu.lua`
    - `Music/ms/cell/hlaalu`
    - `Music/ms/combat/hlaalu`
- **Redoran** — [Nexus](https://www.nexusmods.com/morrowind/mods/55082)
  - `Muse Redoran.lua`
    - `Music/ms/cell/redoran`
    - `Music/ms/combat/redoran`
- **Telvanni** — [Nexus](https://www.nexusmods.com/morrowind/mods/55730)
  - `Muse Telvanni.lua`
    - `Music/ms/cell/telvanni`
    - `Music/ms/combat/telvanni`
- **Temple** — [Nexus](https://www.nexusmods.com/morrowind/mods/57875)
  - `Muse Temple.lua`
    - `Music/ms/cell/temple`
    - `Music/ms/combat/temple`
  - `Muse Almalexia.lua`
    - `Music/ms/cell/almalexia`
    - `Music/ms/combat/almalexia`
  - `Muse Vivec.lua` — broad Vivec coverage; excludes the palace track below
    - `Music/ms/cell/vivec`
  - `Muse Vivec Palace.lua`
    - `Music/ms/cell/vivec/vivecpalace.mp3`
    - `Music/ms/combat/vivec`

The following playlist files are also included for MUSE-compatible content. They are not separate Scipio219 expansion downloads.

- `Muse Mournhold and Solstheim.lua`
  - `Music/ms/cell/mournhold`
  - `Music/ms/cell/solstheim pack`
- `Muse Regions.lua`
  - `Music/ms/region/ashlands pack`
  - `Music/ms/region/ascadian isles region`
  - `Music/ms/region/azura's coast region`
  - `Music/ms/region/bitter coast region`
  - `Music/ms/region/grazelands region`
  - `Music/ms/region/red mountain region`
  - `Music/ms/region/sheogorad region`
  - `Music/ms/region/west gash region`
- `Muse Caves.lua`
  - `Music/ms/cell/cave`
- `Muse Vampire.lua`
  - `Music/ms/combat/vampire`

#### Morrow Winds

[Morrow Winds](https://www.nexusmods.com/morrowind/mods/51734) is a separate music pack. Install it separately, then enable the S3maphore playlists for its music:

- `Muse Hlaalu.lua` — `Music/MS/cell/Hlaalu`
- `Muse Empire.lua` — `Music/MS/cell/Imperial`
- `Muse Mournhold and Solstheim.lua` — `Music/MS/cell/Mournhold` and Solstheim
- `Muse Redoran.lua` — `Music/MS/cell/Redoran`
- `Muse Telvanni.lua` — `Music/MS/cell/Telvanni`
- `Muse Vivec.lua` — `Music/MS/cell/Vivec`
- `Muse Regions.lua` — the Ashlands, Ascadian Isles, Azura's Coast, Bitter Coast, Grazelands, Red Mountain, Sheogorad, and West Gash region folders
- `Muse Caves.lua` — Cave interiors
- `Muse Daedric.lua` — Daedric interiors
- `Muse Dwemer.lua` — Dwemer interiors
- `Muse Tombs.lua` — Tomb interiors
- `Muse Sixth House.lua` — `Music/MS/combat/Dagoth Ur`

#### CaptainCreepy Music Pack

[CaptainCreepy Music Pack](https://www.nexusmods.com/morrowind/mods/51769) is also a separate music pack. Its `00 CORE` option matches these S3maphore playlists:

- `Muse Hlaalu.lua` — `Music/MS/cell/Hlaalu`
- `Muse Empire.lua` — `Music/MS/cell/Imperial`
- `Muse Redoran.lua` — `Music/MS/cell/Redoran`
- `Muse Telvanni.lua` — `Music/MS/cell/Telvanni`
- `Muse Vivec.lua` — `Music/MS/cell/Vivec`
- `Muse Regions.lua` — the Ashlands, Ascadian Isles, Azura's Coast, Red Mountain, Sheogorad, and West Gash region folders
- `Muse Mournhold and Solstheim.lua` — Solstheim
- `Muse Daedric.lua` — Daedric interiors
- `Muse Vampire.lua` — `Music/MS/combat/Vampire`

The optional `01 TAVERNS` folder is supported by `10 Inns and Taverns`. The optional `02 VAMPIRE COMBAT` folder is supported by `Muse Vampire.lua`.

#### Extended
#### Shitpost

## Usage

Make sure to install the playlist files *and* tracks for any S3maphore playlist arrays you install. In the settings menu, you can toggle S3maphore debug messages and the onscreen track/playlist name display.

All S3maphore playlists may ship a unique l10n context with the appropriate playlist/name strings for your preferred language. Presently, only English is supported, but translations are greatly welcomed!

Also in the settings menu, you can scroll through registered playlists and manually enable/disable them completely.

TIP: If you can't toggle a playlist on or off, that means S3maphore couldn't find any of the tracks this playlist has registered in your game.

Finally, pressing F8 will always skip the current track if one is playing - if the shift key is held when pressing F8, it will toggle music playback on or off entirely.

### For Playlist Authors

The [S3maphore documentation](@/s3maphore/docs/_index.md) covers playlist creation, playlist rules, batched combat checks, events, metadata, settings, and the public interface.

### Settings

S3maphore's main settings group is a `Player` scoped storage section called `SettingsS3Music`. It contains the following keys and values:

1. `Enable Debug Messages` - `Checkbox` - Whether or not to use verbose logging. See `openmw.log` for more details. Every line with S3maphore log outputs will start with `[ S3MAPHORE ]:`

1. `Enable Music` - `Checkbox` - Whether or not S3maphore will play music *at all*. Disabling it stops S3maphore playback; re-enabling it resumes normal contextual resolution.

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
