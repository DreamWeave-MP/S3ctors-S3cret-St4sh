---
title: Horiz0n
description: View distance manager implemented in OpenMW-Lua to maximize framerate *and* viewing distance whenever possible.
date: 2026-07-23

taxonomies:
  tags:
    - Quality-Of-Life
    - Performance
    - OpenMW-Lua

extra:
  cover: /img/horiz0n.webp
---

I was discussing the concept of occlusion culling with someone recently.

I told them that the engine has no defense against extremely draw-call bound areas, such as Old Ebonheart.

However, I kept thinking about it, and eventually realized that was bullshit - because we DO have frustum and distance cull. These are the oldest tricks in the book for optimizing framerates in Morrowind, going all the way back to the classic `Morrowind FPS Optimizer` app from however long ago.

The problem that I found with prior approaches was that they were *all* dedicated to the idea of *saving* your framerate at all times. You'd get your frames back, but they wouldn't expand your view distance back out when the headroom returned.

Thus was born, Horiz0n.

<!-- more -->

{{ install_instructions(describe=true) }}

# Overview

Much like its sibling, S4V3R, Horiz0n is minimalist in design and aggressively tries to optimize your framerate.

The way it works is simple:
1. You tell Horiz0n your target framerate - 60 by default
2. It averages your frametime, thirty times per second, if the world is not paused AND you are not in a true interior cell - so Starwind and Tribunal should both work fine.
3. If the average frametime stays 10% worse than your target, lower the view distance by 1% per measurement. If it's 30% worse, lower by 2%. Reductions are applied at most four times per second, each one covering the time since the last and never more than a quarter of the current view distance, so it falls about as fast with far fewer changes. After any change Horiz0n ignores a quarter second of frames, so the cost of the change itself is never mistaken for load.
4. After lowering it, hold still for the Grow Cooldown - three seconds by default - and only then try raising the view distance by 1% again, at most four times per second so each raise can be judged before the next. If a raise immediately costs frames again, the cooldown doubles, up to one minute.

It'll keep going as-needed until you hit either the minimum or the maximum viewing distance, and once it finds a distance your framerate can hold, it leaves the view distance alone.

The maximum is never higher than the viewing distance you set in OpenMW's own options. Horiz0n only takes view distance away when you need the frames, and gives it back up to what you asked the engine for. If you want longer vistas, raise OpenMW's viewing distance and let Horiz0n manage it.

In order for Horiz0n to work correctly, you *must* set a framerate limit in the OpenMW launcher, or manually in your `settings.cfg` file, and set Horiz0n's Target Framerate to match it. ***YOU HAVE BEEN WARNED***.

The minimum viewing distance is 2048 units, which is exactly one quarter of a standard Morrowind cell. This prevents your viewing distance from ever becoming *too* short to actually navigate, even in extremely demanding areas.

Interiors are ignored intentionally because they usually hit your framerate limit to begin with.

The steps scale with your current view distance, so Horiz0n crosses the whole range in seconds while the 30Hz tickrate keeps transitions from being too noticeable.

Every view distance change makes the engine rebuild its distant terrain, so as of version 1.4 Horiz0n only changes it when it has a reason to. Earlier versions adjusted it thirty times per second, which caused lag spikes with distant terrain and object paging enabled.

As of version 1.2, all of Horiz0n's internal tuning parameters are exposed:
- Target Framerate
- Minimum View Distance
- Maximum View Distance
- Adjustment Framerate
- Normal Frametime Decrease Adjustment
- Severe Frametime Decrease Adjustment
- View Distance Step (as a percentage of the current view distance)
- Severe View Distance Step Multiplier
- Grow Cooldown
- Disable/Enable the entire mod

By default, the max view distance is 25 cells or OpenMW's viewing distance, whichever is lower.

This setting is exposed for those who wish to cap Horiz0n below what the engine is configured for.

Personally, I cap it to 5 cells.

View distance is always maxed whilst indoors, to avoid unneccessary blind spots in dungeons. As of 1.4 this no longer needs [H3lp Yours3lf](https://dreamweave-mp.github.io/S3ctors-S3cret-St4sh/h3lp_yours3lf/), and turning Horiz0n off puts your view distance back to OpenMW's setting.

If another mod changes the view distance while Horiz0n is managing it, Horiz0n steps back for five seconds at a time instead of fighting over it.

Also, I recommend using it with [Hawk3ye](https://dreamweave-mp.github.io/S3ctors-S3cret-St4sh/hawk3ye/), as zooming in changes your field of view and with it your framerate, so Horiz0n can hand back view distance while you are zoomed. Try it out!

{{ credits(default=true) }}
