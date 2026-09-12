---
title: H3lp Yours3lf Documentation
description: Working integrations, source-checked helper contracts, and ownership guidance.
template: docs/section.html
page_template: docs/page.html
sort_by: weight

extra:
  api_docs: true
  docs_root: true
  docs_project_name: H3lp Yours3lf
  docs_short_title: H3lp Yours3lf Docs
  docs_project_path: '@/h3lp_yours3lf/index.md'
  docs_repository_url: https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/h3lp_yours3lf
  docs_sidebar_label: Documentation
  kind: guide
---

H3lp Yours3lf is the shared OpenMW-Lua utility layer: reusable code proven across multiple mods, packaged so authors can build on dependable behavior instead of re-solving the same engine problems. This documentation is organized as a reference for authors who need that foundation.

## Start here

Use [Getting Started](@/h3lp_yours3lf/docs/getting-started/_index.md) for the first integration, [Concepts](@/h3lp_yours3lf/docs/concepts/_index.md) for the mental model, and [API Reference](@/h3lp_yours3lf/docs/api/_index.md) when you already know the symbol you need.

## Build something small first

The [first integration](@/h3lp_yours3lf/docs/getting-started/overview.md) takes you from installation through a running player script and expected output. Then choose [timing](@/h3lp_yours3lf/docs/api/modules/timing.md), [local notifications](@/h3lp_yours3lf/docs/api/modules/signal.md), or [object access](@/h3lp_yours3lf/docs/api/modules/s3lf.md) according to the work you need.

Already maintaining your own helpers? Follow the [migration checklist](@/h3lp_yours3lf/docs/migration/from-local-helpers.md). Optimizing a measured allocation hotspot? Read the [pooling example](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md), including its borrowed-payload restrictions.

The [API coverage note](@/h3lp_yours3lf/docs/api/_index.md#coverage-and-remaining-references) identifies material still awaiting dedicated pages. This manual distinguishes verified references from unfinished coverage rather than treating every module as interchangeable.
