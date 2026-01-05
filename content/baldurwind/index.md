---
title: Baldurwind
description: Turn-based Combat For Morrowind!
date: 2024-04-13

taxonomies:
  tags:
    - Combat
    - Gameplay
    - Turn-Based

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - Baldurwind.omwaddon

  version: 0.5
---
Baldurwind is a mechanical total conversion for OpenMW. More features are planned, but in essence, Baldurwind's goal is to convert Morrowind into turn-based, party RPG!

The idea was inspired due to the sheer popularity of Baldur's Gate 3 (obviously) and some of my longstanding grievances with the combat system. There's not enough audiovisual feedback in typical Morrowind combat, so instead of removing hit chance (as I did in another mod), I designed some mechanics which enable the game to (in my opinion) more properly lean into that idea.

<!-- more -->

# Usage

Baldurwind is specifically designed to be compatible with whatever the latest stable release of OpenMW is. At the time of this writing, that is 0.48. To the best of my knowledge, Baldurwind still works on development builds as of commit cd116ebe5f .

Otherwise, just follow the installation instructions below and be ready for a hard time. Turn-based Morrowind is extremely punishing and necessitates a proper build, and having friends along helps quite a bit.
If you don't typically play with followers or companions, you probably will now!

Pairs great with [AttendMe](https://gitlab.com/urm-openmw-mods/attend-me/-/tree/0.49?ref_type=heads) and [OpenNeverMind](https://modding-openmw.gitlab.io/opennevermind/).

{{ install_instructions(describe=true) }}

{{ image(src="/img/modathonbanner2024.png", alt="Morrowind Modathon 2024", style="border-radius: 8px;") }}

{% credits(default=true) %} 
Everyone in the MMC who kept constantly going on about how good BG3 was, thank you for annoying me into making this.
{% end %}
