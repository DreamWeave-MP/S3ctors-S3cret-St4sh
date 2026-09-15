---
title: 'Design Study: S3maphore Playlist Eligibility'
description: How a frightening playlist-conflict problem became one small callback and generic ordering.
weight: 20
extra:
  kind: guide
---

## The problem

S3maphore needed multiple independent playlists to coexist.

One playlist might apply in combat. Another might apply in a tavern. Another might care about a region, weather, quest stage, nearby object, or another mod's state. Several may be eligible at the same time, and a new playlist should not require a new special case in the resolver.

That is a genuinely awkward problem. Music should respond to context without turning the music engine into a knowledge base about every context any mod might invent.

## The tempting design

The obvious escalation is a central conflict-resolution system that knows about every playlist category and interaction:

- special combat rules;
- location arbitration;
- quest exceptions;
- mod-specific overrides;
- priority graphs;
- a registry of conflict policies.

That resolver would gradually own the policy of every playlist. Adding a new kind of condition would mean teaching the resolver another concept. The system would become harder to extend precisely because it was trying to understand everything.

## The reduction

What does the resolver actually need from a playlist?

It needs an answer to one question:

> Can this playlist play for the current playback state?

That becomes:

```text
fun(playback) -> boolean
```

In a playlist file, the injected `Playback` value lets the callback close over the same context without spelling out the parameter:

```lua
isValidCallback = function()
    return Playback.state.isExploring
        and Playback.state.cellIsExterior
        and Playback.rules.timeOfDay(6, 18)
end
```

The callback owns playlist policy. The resolver only asks for the answer.

## The generic mechanism

S3maphore still needs generic playlist metadata. A playlist must be active, have tracks, and occupy a priority position. But the selection loop does not know whether eligibility came from combat, weather, a cell name, a quest stage, or a custom interface:

```lua
local function firstActivePlaylist(deck, playback)
    for i = 1, #deck do
        local playlist = deck[i]
        if playlist.active
            and next(playlist.tracks) ~= nil
            and playlist.isValidCallback(playback)
        then
            return playlist
        end
    end
end
```

The real implementation is [`firstActivePlaylist`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/util.lua) and the surrounding catalog/reconciliation code. The [playlist contract](@/s3maphore/docs/api/playlist.md), [Playback API](@/s3maphore/docs/api/playback.md), and [priority rules](@/s3maphore/docs/playlist-authoring/priority.md) document the rest of the boundary.

Priority and interruption do not disappear. They remain generic facts about how a selected playlist is handled. What stays out of the resolver is the reason a playlist is eligible.

## Why this primitive is enough

The small callback gives the system room to grow:

- simple rules are simple predicates;
- complex rules compose state and reusable rule functions;
- the resolver never needs to learn a new condition category;
- adding a playlist does not require changing central selection code;
- playlist authors keep ownership of playlist-specific policy;
- callbacks can be evaluated against the current state without mutating the world.

S3maphore's [playlist environment](@/s3maphore/docs/api/playlist-environment.md) makes the intended use explicit: callbacks are cheap queries of `Playback.state` and `Playback.rules`, not update loops or action handlers.

This is why the design is expressive without being clever. The callback says everything the mechanism needs to know and nothing the mechanism should have to understand.

## What to steal

When several producers repeatedly express policy in different forms, do not immediately build a central object model for all of them.

Ask what the consumer actually needs. If the answer is “whether this applies now,” let the producer answer that question and keep the consumer generic.

That is the design lesson. It is not “use predicates everywhere.” It is:

> Put policy behind the boundary that owns it, and make the mechanism ask for the smallest useful answer.

The later [resolver invalidation scar](@/cod3x/docs/paid-for-with-blood/resolver-invalidation.md) is useful for the other half of the story: a small eligibility primitive does not remove the need to track when its inputs become stale. Simplicity in the contract and care in the state lifetime belong together.

## When not to use this

Do not hide a real cross-playlist relationship inside an opaque callback if the resolver must coordinate it. S3maphore's callback works because priority, activation, tracks, and interruption remain generic metadata. If the next layer needs to negotiate shared ownership or explain why two choices conflict, that relationship needs an explicit contract rather than another boolean.
