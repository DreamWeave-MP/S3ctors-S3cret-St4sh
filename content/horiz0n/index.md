---
title: Horiz0n
description: View distance manager implemented in OpenMW-Lua to maximize framerate *and* viewing distance whenever possible.
date: 2026-07-23

nexus_id: 59668
nexus_group_id: 7703223

taxonomies:
  tags:
    - Qualify-Of-Life
    - Performance
    - OpenMW-Lua

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - Horiz0n.esp

  version: 1.0
---

I was discussing the concept of occlusion culling with someone recently.

I told them that the engine has no defense against extremely draw-call bound areas, such as Old Ebonheart.

However, I kept thinking about it, and eventually realized that was bullshit - because we DO have frustum and distance cull. These are the oldest tricks in the book for optimizing framerates in Morrowind, going all the way back to the classic `Morrowind FPS Optimizer` app from however long ago.

The problem that I found with prior approaches was that they were *all* dedicated to the idea of *saving* your framerate at all times. You'd get your frames back, but they wouldn't expand your view distance back out when the headroom returned.

Thus was born, Horiz0n.

{{ image(src="/img/horiz0n.png", alt="Horiz0n - View Distance Manager", style="border-radius: 8px;") }}

<!-- more -->

{{ install_instructions(describe=true) }}

# Overview

Much like its sibling, S4V3R, Horiz0n is minimalist in design and aggressively tries to optimize your framerate.

The way it works is simple:
1. Horiz0n keeps track of the fastest frame your game's ever rendered
2. It checks the current frametime, thirty times per second, if the world is not paused AND you are not in a true interior cell - so Starwind and Tribunal should both work fine.
3. If the current frametime is 10% worse than the best one recorded, lower the view distance by 16 units. If it's 30% worse, lower by 32 units. Otherwise, raise view distance by 16 units.

It'll keep going as-needed until you hit either the minimum or the maximum viewing distance.

In order for Horiz0n to work correctly, you *must* set a framerate limit in the OpenMW launcher, or manually in your `settings.cfg` file. ***YOU HAVE BEEN WARNED***.

The fastest-frame tracking is intended to allow maintaining a moving performance baseline rather than a fixed framerate target - consequently, Horiz0n doesn't care if you're at 60, 120, or 240Hz - it just cares how well your system ran the game during this session.

The minimum viewing distance is 2048 units, which is exactly one quarter of a standard Morrowind cell. This prevents your viewing distance from ever becoming *too* short to actually navigate, even in extremely demanding areas.

Interiors are ignored intentionally because they usually hit your framerate limit to begin with.

The steps are all relatively small, and the 30Hz tickrate ensures that transitions generally aren't too noticeable.

There are only two settings, which allow you to enable or disable Horiz0n in-game, and change the maximum viewing distance.

By default, the max view distance is 25 cells, as view distance is extremely cheap outside of the active grid.

This setting is exposed for those who wish to use extreme view distances on either end.

Personally, I cap it to 5 cells.

Also, I recommend using it with [Hawk3ye](https://dreamweave-mp.github.io/S3ctors-S3cret-St4sh/hawk3ye/), as the zoom effect produces a very fun interaction with Horiz0n that causes your view distance to *literally* increase when you zoom in, due to Hawk3ye changing your field of view. Try it out!

{{ credits(default=true) }}
