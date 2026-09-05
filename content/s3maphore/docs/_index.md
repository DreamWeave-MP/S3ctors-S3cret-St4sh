+++
title = "S3maphore Documentation"
description = "Guides and API reference for creating playlists and integrating with S3maphore."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
aliases = ["/s3maphore/modder-docs/"]

[extra]
api_docs = true
docs_root = true
docs_project_name = "S3maphore"
docs_short_title = "S3maphore Docs"
docs_project_path = "@/s3maphore/index.md"
docs_repository_url = "https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/s3maphore"
docs_sidebar_label = "Documentation"
kind = "guide"
+++

S3maphore is an open playlist engine for OpenMW. This manual separates the fast path for playlist authors from the detailed reference for integrations and tooling.

## Choose your path

Start with **Getting Started** if this is your first S3maphore playlist. Use **Playlist Authoring** when you are shaping a larger music pack. The **API Reference** is the lookup room for the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md), metadata, settings, loading, events, state, and rules. **Examples** show the pieces working together.

If your mod currently polls actors from `onUpdate`, read the [batched combat check event](@/s3maphore/docs/api/events.md#s3maphorecheckcombat). S3maphore already performs the player-side polling; an actor-local handler can replace per-actor update work without adding another scheduler.
