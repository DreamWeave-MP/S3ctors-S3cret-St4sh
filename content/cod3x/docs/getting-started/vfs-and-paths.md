---
title: VFS and Paths
description: Treat OpenMW's virtual filesystem as the mod's filesystem contract, not the host OS.
weight: 55
extra:
  kind: guide
---

OpenMW mods live in the virtual filesystem (VFS), not in one physical directory you can safely assume at runtime.

Use `openmw.vfs` for mod data that belongs to OpenMW's data-directory overlay.

## Ask the VFS, not the host filesystem

Useful operations include:

- `vfs.fileExists(path)`;
- `vfs.open(path)`;
- `vfs.lines(path)`;
- `vfs.pathsWithPrefix(prefix)`.

A path that resolves in the VFS may come from any active data directory and may be overridden according to OpenMW's VFS rules.

That is a feature. Do not bypass it with host filesystem assumptions for normal mod resources.

## Normalize identifiers at ingress

S3maphore normalizes playlist and track paths before using them as metadata keys. That avoids repeated case/separator normalization in hot lookup paths and prevents the same logical path from occupying multiple cache entries.

A small shared normalizer is appropriate when a project uses VFS paths as stable IDs.

H3 Pattern: [normalizePath](@/h3lp_yours3lf/docs/api/packages/normalize-path.md) handles spelling normalization only. The [S3maphore metadata path](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/musicMetadata.lua) is a production example of normalizing at ingress rather than inside every lookup.

Do not normalize blindly if an API's path semantics are case-sensitive or intentionally preserve form. Know the contract of the particular path surface.

## Large reads can become frame allocation spikes

Cod3x's `openmw.vfs` annotations preserve an important upstream warning: reading a very large file in one frame can place the whole content in memory until GC has an opportunity to run.

For large data:

- read incrementally;
- preserve file position;
- spread work across frames when the feature permits;
- close handles deliberately when ownership ends.

## `pathsWithPrefix` is discovery, not ordering

If output order matters to your format, impose the order yourself rather than depending on an incidental VFS iteration order.

S3maphore builds its own catalog/priority semantics instead of treating filesystem enumeration as business logic.

## Validate at load time

If configuration references required resources, resolve/check them when the configuration is registered or loaded rather than discovering the typo twenty minutes later in a hot path.

Early validation improves both diagnostics and runtime performance.
