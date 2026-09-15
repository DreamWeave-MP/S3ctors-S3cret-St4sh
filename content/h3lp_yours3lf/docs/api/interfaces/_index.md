---
title: Interfaces
description: H3 contracts provided through openmw.interfaces.
template: docs/section.html
page_template: docs/page.html
sort_by: title
weight: 20

extra:
  kind: api
  sidebar_groups:
    - title: Object and actor data
      pages: [s3lf]
    - title: Settings and persistent state
      pages: [protected-table]
    - title: UI and rendering
      pages: [h3ui, image-atlas]
    - title: Camera and projection
      pages: [cam-helper]
---

These interfaces are registered by H3 provider scripts and obtained through `require 'openmw.interfaces'`. They are not replacements for the provider's implementation files.

## Choose by need

| Need | Interface |
| --- | --- |
| Read the attached object's common fields, records, or actor data | [S3lf](@/h3lp_yours3lf/docs/api/interfaces/s3lf.md) |
| Keep settings and runtime state behind one manager | [ProtectedTable](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md) |
| Build high-level UI from recipes with player-configured appearance and style rules | [H3UI](@/h3lp_yours3lf/docs/api/interfaces/h3ui.md) |
| Display or cycle frames from an atlas texture | [ImageAtlas](@/h3lp_yours3lf/docs/api/interfaces/image-atlas.md) |
| Project world objects into a player's viewport | [CamHelper](@/h3lp_yours3lf/docs/api/interfaces/cam-helper.md) |
