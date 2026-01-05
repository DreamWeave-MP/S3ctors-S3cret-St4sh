---
title: Starwind Merged Plugin Project
description: The Starwind Merged Plugin Project began as an effort to consolidate the Starwind ESM files, to eventually make them entirely indepentent of Morrowind.esm and friends. At this time, the merged plugin project primarily focuses on the vanilla ESM files, with additional content stripped out.
date: 2023-04-26

taxonomies:
  tags:
    - Starwind
    - Patches

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - Starwind-Solo.omwaddon

  version: 0.2
---
<h1 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Brought to you by the Starwind Team and all the players on <a href="https://discord.gg/wcMj2b2svh">The Starwind Initiative</a></h1>

The Starwind Merged Plugin Project began as an effort to consolidate the Starwind ESM files, to eventually make them entirely indepentent of Morrowind.esm and friends. At this time, the merged plugin project primarily focuses on the vanilla ESM files, with additional content stripped out.

{{ install_instructions(describe=true) }}

NOTE: Only use one of the two plugins, either the Singleplayer version or the Multiplayer one. They are meaningfully different.  

## WARNING

Please do not try to use the merged plugin project with any other Starwind mods. They are not presently compatible, but will be in the future!

## History

Over time as The Starwind Initiative matured, we collected lots of minor bug fixes we needed to implement for multiplayer and wanted to make sure they were available to all Starwind players. Everything built here is available in the [Starwind-Builder](https://gitlab.com/modding-openmw/Starwind-Builder) repo, which is also used for deploying all content patches for TSI.

## Credits

{% credits(default=true) %}
Most of the changes and fixes in here were drawn from bug reports and other errata discovered by the TSI community. Thanks to all of you, as well <3.
- Special Thanks to:
Ignatious  
SkoomaBreath  
RymanTheGreat  
VidiAquam
{% end %}
