+++
title = "PlaylistRules"
description = "Built-in predicates for common contextual playlist decisions."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 30

[extra]
api_docs = true
kind = "api"
+++

Rules are ordinary functions exposed as `Playback.rules` inside a playlist file. The complete set is split by the kind of context being inspected:

- [Location and time](@/s3maphore/docs/api/rules/location.md)
- [Presence and content](@/s3maphore/docs/api/rules/presence.md)
- [Combat](@/s3maphore/docs/api/rules/combat.md)
- [Journal and services](@/s3maphore/docs/api/rules/quest-and-services.md)

Keep reusable lookup tables outside callbacks so S3maphore can cache their work where possible. Most identifier lookups are case-sensitive against normalized, lowercased engine values; the individual entries call out exceptions.
