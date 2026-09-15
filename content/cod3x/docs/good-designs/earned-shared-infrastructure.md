---
title: 'Design Genealogy: Earned Shared Infrastructure'
description: How specific solutions become H3 only after repetition proves their contract.
weight: 80
extra:
  kind: guide
---

## Prediction versus evidence

It is easy to look at a first implementation and imagine the reusable library it might become.

That is usually the wrong time to generalize. You do not yet know which parts are stable, which requirements are imaginary, or whether a second consumer would want the same boundary.

> Duplication is evidence. Premature generalization is prediction.

The useful sequence is:

{{ schematic(data_path="data/schematics/earned-shared-infrastructure.json") }}

The shared module is the end of the investigation, not the beginning of it.

## SSS to H3

Static Switching System had local copies of utilities that were no longer local in any meaningful sense. Commit [`7cb5a731`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/7cb5a7310a6f0d37036c5a96b12c284f5caf4cd9) moved `szudzik`, `tableHash`, and `randomGen` into H3 because repeated instances already existed and another project was using the same ideas.

The migration removed SSS-local duplicate files and changed consumers to stable H3 module paths. The current [SSS module format](@/static_switching_system/docs/api/module-format.md) and [H3 API reference](@/h3lp_yours3lf/docs/api/_index.md) show the resulting package boundary.

The same promotion appears in smaller stories:

- S3maphore's `isOpenMW` module became H3 in [`a9afe80a`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/a9afe80ac47b34e98c590fa55b3ac0c7534335e5), then S3maphore deleted its copy in [`d6a45c62`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/d6a45c6254c817557fa1d2da64fe12c236675cd2);
- a dedicated `clear` operation moved from a S3maphore-specific need into an H3 module that can use Rubic0n's fast implementation or a Lua fallback in [`30ca0dbe`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/30ca0dbe30093e0ab686c56fed5ac0df8c831237) and [`bf0b6505`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bf0b6505f154ad3b0890405b61bccad9d3afcd21);
- `randomGen` gained a non-allocating range path and uniform integer selection in [`0595f2b1`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/0595f2b1f938b419b0dce99466a85dd64f77e012) and [`4e8235f5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/4e8235f53c5c183409c3de7dcbc9ad23687936d4).

The library was not guessed into existence. Consumers earned it.

## Keep the contract small

Promotion is not a reward for having a clever implementation. It is a response to a stable question that multiple consumers need answered.

The reusable module should own the parts that are genuinely shared:

- the semantic name;
- the input and output contract;
- the relevant failure behavior;
- the package and context boundary.

It should not inherit every detail from its first consumer. A shared helper that exposes one project's storage layout, lifecycle assumptions, or private cache is not shared infrastructure yet. It is a copy with a nicer address.

See [API and Interface Design](@/cod3x/docs/practice/api-design.md) for the broader contract rules. [S3lf](@/cod3x/docs/good-designs/s3lf-semantic-boundary.md) and [CamHelper](@/cod3x/docs/good-designs/cam-helper-extraction.md) show the same promotion pressure at larger semantic boundaries.

## What to steal

When you see duplication, do not immediately extract it. First ask whether the copies share meaning, lifetime, ownership, and failure behavior.

If repeated consumers prove that they do, extract the smallest stable contract and move the implementation behind it. Let the callers become simpler because they no longer need to know how the answer is produced.

## When not to use this

If there is only one consumer or the repeated code only looks similar, keep it local. Do not extract a library because two files happen to have matching shapes; that is a prediction, not evidence.
