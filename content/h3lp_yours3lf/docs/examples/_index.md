---
title: Examples
template: docs/section.html
page_template: docs/page.html
sort_by: weight
weight: 40

extra:
  kind: example
---

Examples lead with working code, then point back to the API contract and the relevant context rules.

## Learn a concept

- [First integration](@/h3lp_yours3lf/docs/getting-started/overview.md): installation, a complete player script, and expected log output.
- [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md): settings, inventory grids, tabs, and searchable lists.
- [Debounced input](@/h3lp_yours3lf/docs/api/packages/debounce.md): refresh only after changes settle.
- [Periodic checks](@/h3lp_yours3lf/docs/api/timing.md): poll without confusing interval coalescing with catch-up execution.
- [Pooling and Signals](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md): synchronous payload reuse, explicit ownership, and cleanup on error.

## From the St4sh

These are production junctions rather than toy tutorials. Each one shows several H3 contracts working beside one another in a real subsystem.

{{ h3_usage(overview=true) }}
