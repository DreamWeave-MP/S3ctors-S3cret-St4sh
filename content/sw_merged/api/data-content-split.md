---
title: Star_Data / Starwind split
weight: 50
description: Stable data ABI, content boundary, script exceptions, typed dependency fixed point, and split validation.
---

# Star_Data / Starwind split

After the masterless monolith validates, `split_starwind.py` partitions it into
a stable definition layer and a content layer modeled after the broad
Tamriel_Data / TR_Mainland idea.

The goal is not merely smaller files. `Star_Data` is intended to become
Starwind's more stable dependency/API surface while `Starwind` remains free to
change aggressively during quest, script, and OpenMW Lua modernization.

## Dependency direction

The architectural invariant is:

```text
Star_Data.omwaddon
    ^
    |
Starwind.omwaddon
```

`Star_Data` must never depend on a record that exists only in `Starwind`.
`Starwind` may depend heavily on `Star_Data`.

The splitter iterates candidates to a fixed point: if a proposed Data record
has a typed dependency on content, it is demoted back to `Starwind` unless the
dependency is intentionally promoted too.

## Typed namespaces are mandatory

The first splitter prototype used a flat set of normalized editor IDs. That was
wrong because TES3 permits the same text ID in multiple record namespaces.

The concrete failure was BODY records using races such as `Droid`, `Sith`, and
`Zabrak`: same-named DIAL records caused valid BODY -> RACE dependencies to be
misread as BODY -> content dependencies.

The current splitter resolves dependency target **types**, so:

```text
BODY.race "Droid" -> RACE "Droid"
```

is not affected by:

```text
DIAL "droid"
```

Missing target-type mappings are treated as validator/model defects rather
than an invitation to fall back to ambiguous string-only resolution.

## Default record placement

The practical policy is a mixture of record type, semantic role, and dependency
closure.

### Strong Data defaults

Stable/foundational definitions generally belong in `Star_Data`:

```text
GMST MGEF SKIL
RACE CLAS FACT BSGN
SOUN SNDG
BODY STAT
APPA LOCK PROB REPA
INGR ALCH ENCH SPEL
```

MGEF/SKIL/GMST are foundational and are never reachability-pruned merely
because the ordinary object graph appears not to reference them.

### Dependency-checked Data candidates

Reusable base definitions can move to Data if their entire typed dependency
closure is Data-safe:

```text
WEAP ARMO CLOT MISC LIGH
ACTI CONT DOOR CREA
LEVI LEVC
```

A content-flavored editor ID is not by itself a reason to keep a base object in
`Starwind`. If a stable unscripted definition has no content dependency, it may
live in Data even when only the main Starwind world currently instantiates it.

### Content defaults

The following normally remain in `Starwind`:

```text
CELL PGRD
DIAL INFO
NPC_
SCPT SSCR
GLOB
REGN
BOOK
```

FACT, REGN, and CLAS remain subject to manual semantic review where necessary;
record placement is not driven purely by "currently referenced by an NPC".
Classes, for example, may be intentionally exposed during character creation.

## Scripts are intentionally content-heavy

Legacy MWScript is a major exception to a simplistic "definitions in Data"
rule.

Most `SCPT` records remain in `Starwind.omwaddon` because a large fraction of
Starwind's MWScript is expected to be deleted or replaced with OpenMW Lua. The
project does not want the supposedly stable `Star_Data` layer to churn every
time a legacy script is migrated.

A scripted object therefore usually stays in `Starwind` even if its record type
would otherwise be a Data candidate.

There may be exceptions for deliberately stable shared framework scripts, but
they must be explicitly approved rather than inferred automatically.

## Lua migration boundary

The long-term intent is roughly:

```text
Star_Data
    stable records
    reusable definitions
    intentionally public/shared framework data
    only small, stable script/Lua interfaces when justified

Starwind
    world
    quests
    dialogue
    actors/placements
    most legacy MWScript
    most LUAL registrations during active migration
    content-specific scripted definitions
```

Promotion into Data is earned by stability. A record can remain in content for
one release and move into Data later after its script dependency disappears or
its interface becomes deliberately reusable.

## Books and authored text

Books are kept on the content side by default even when unscripted. Dependency
safety alone does not make authored lore/quest text a reusable public data
resource.

## Current split validation

The splitter validates the serialized outputs, not merely its in-memory
partition.

Required invariants:

- `Star_Data` has no masters;
- `Starwind` has `Star_Data.omwaddon` as its sole master;
- union of serialized split records reconstructs the monolith exactly;
- no effective-record mismatch after reconstruction;
- zero `Star_Data -> Starwind` dependencies;
- no new unresolved dependency is introduced by the split.

Current validated counts from the documented build are:

```text
Starwind-Definitive   30,548 non-header records
Star_Data             13,330
Starwind              17,218
```

The exact counts may change as the corpus is cleaned or modernized; the
invariants above are the stable contract.

## Manual review buckets

Three families deserve semantic review rather than automated pruning:

- **FACT** — a faction may matter through reactions, dialogue, player-facing systems, or future content even when no obvious actor currently belongs to it.
- **REGN** — regions can be deliberately reused by Starwind pseudo-exterior/interior weather systems; vanilla region metadata is not automatically junk.
- **CLAS** — vanilla classes may intentionally be exposed to the player at chargen; "unreferenced by NPC" does not imply unused.

## Split command

The normal Definitive builder invokes the splitter automatically. For forensic
work on an existing monolith:

```bash
./split_starwind.py \
  --source .swbuild/definitive/out/Starwind-Definitive.omwaddon \
  --data-output .swbuild/definitive/out/Star_Data.omwaddon \
  --content-output .swbuild/definitive/out/Starwind.omwaddon \
  --report .swbuild/definitive/reports/starwind-split-report.json
```

[API index](../) · [Design decisions](../design-decisions/) · [Validation](../validation-and-reports/)
