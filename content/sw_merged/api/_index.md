---
title: Definitive Build API & Wiki
description: Exhaustive technical reference for the Starwind Definitive build, decoupling, dialogue canonicalization, validation, and Star_Data split.
template: docs/section.html
page_template: docs/page.html
sort_by: weight

extra:
  docs_root: true
  docs_project_name: Starwind Merged Plugin Project
  docs_short_title: Definitive Build Docs
  docs_project_path: '@/sw_merged/index.md'
  docs_repository_url: https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/sw_merged
  docs_sidebar_label: API & Wiki
  kind: guide
---

# Definitive Build API & Wiki

This section is the long-form technical and historical reference for the
Starwind Definitive build. The project landing page intentionally stays short;
this reference preserves the details required to reproduce, audit, or modify
the pipeline without rediscovering years of TES3 archaeology.

The word **API** is used broadly here: this documents the build contract, data
boundaries, invariants, generated artifacts, record-placement policy, and the
interfaces between the project's tools.

## Recommended reading order

1. **[Build pipeline](./build-pipeline/)** — start here for the complete stage graph.
2. **[Source corpus & preprocessing](./source-corpus-and-preprocessing/)** — understand what enters the build and which historical edits are allowed.
3. **[Master decoupling](./master-decoupling/)** — how Bethesda-master dependencies are imported and then removed.
4. **[Dialogue canonicalization](./dialogue-canonicalization/)** — the most complicated subsystem and the largest body of source archaeology.
5. **[Star_Data / Starwind split](./data-content-split/)** — the stable-data/content ABI and dependency rules.
6. **[Validation & reports](./validation-and-reports/)** — the acceptance contract for every build.
7. **[Historical cleanup ledger](./historical-cleanup-ledger/)** — specific removals, source fixes, and rejected historical behavior.
8. **[Design decisions](./design-decisions/)** — policies that are intentional rather than accidental artifacts of the implementation.
9. **[Tools & commands](./tools-and-commands/)** — executable/tool reference and common forensic workflows.

## Current contract

A successful strict build must produce a masterless monolith and a split pair
with these properties:

```text
Starwind-Definitive.omwaddon
    masters = 0
    hard unresolved dependencies = 0
    OpenMW dialogue = exact expected effective database

Star_Data.omwaddon
    masters = 0
    no dependency on Starwind.omwaddon

Starwind.omwaddon
    sole master = Star_Data.omwaddon

Star_Data + Starwind
    reconstruct Starwind-Definitive exactly
```

The current corpus validates at **591 DIALs**, with no missing/extra live INFOs,
no engine-order mismatch, no physical-order mismatch, no serialized-link
mismatch, and no dialogue payload mismatch.

## Scope of this reference

This documentation intentionally records both the **current implementation**
and the **reasoning history** that led to it. Old strategies are included when
they explain why a current rule exists, but historical behavior is clearly
marked so that it is not mistaken for current build policy.

[Back to the Starwind Merged Plugin Project](../)
