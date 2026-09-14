---
title: Build pipeline
weight: 10
description: Exact Definitive source graph and stage-by-stage build contract.
---

# Build pipeline

`build_starwind.py` is the only supported build entry point. The modern project
has no Solo, Standalone, or TSI content modes. Definitive Starwind has one
approved source corpus and one deterministic build graph.

## Entry point

```bash
./build_starwind.py --strict
```

Useful operational flags may control cleanup or retained work artifacts, but
they do not change which Starwind content belongs to the product.

## Fixed source graph

The canonical merge order is:

```text
Bing's Race Pack  -> Starwind Enhanced
Enhanced          -> StarwindRemasteredPatch
PlanExp           -> StarwindRemasteredPatch
Alt Start         -> StarwindRemasteredPatch
CPP               -> StarwindRemasteredPatch
Naboo             -> StarwindRemasteredPatch
Patch             -> StarwindRemasteredV1.15
PartyHats         -> canonical Definitive merge
canonical merge   -> Minimal -> addVanillaRefs -> masterless monolith
masterless monolith -> Star_Data + Starwind
```

The `merge_to_master` command takes `<plugin> <master>` and writes the merged
result into the second file. The arrows above describe the effective flow, not
an abstract dependency graph.

## Stages

### 1. Compile canonical JSON sources

All approved `plugins/*.json` sources are converted to temporary TES3
ESM/ESP files with `tes3conv` under:

```text
.swbuild/definitive/work/
```

Canonical JSON inputs are never edited by compilation. `tes3cmd` surgery is
performed against staged work copies unless a cleanup has explicitly been
promoted to a canonical source change.

### 2. Parent-aware source dialogue hygiene

Before the canonical merge, the source dialogue is audited against the parent
state it actually inherits from. This prevents a Patch record from being
misclassified by comparing it only to Bethesda masters when it is actually
an override of V1.15.

See [Dialogue canonicalization](../dialogue-canonicalization/) and the
[Historical cleanup ledger](../historical-cleanup-ledger/).

### 3. Main-quest preservation: pre-preprocess check

A reviewed set of main-quest DIAL/NPC/SCPT anchors and a live
`SW_ShipQuester` cell reference are asserted before any Definitive source
surgery runs.

This guard exists specifically because the old multiplayer build intentionally
removed pieces of Starwind's main quest. Definitive Edition must never inherit
those destructive server-only edits by accident.

### 4. Definitive preprocessing

Only reviewed source-cleaning and integration operations run. Historical TSI
multiplayer policy is not reused as a convenience layer.

The build explicitly does **not** apply the old TSI gold/Kolto substitutions,
main-quest instance removals, `SW_ShipQuester` removal, Courte server cleanup,
or other server-only reference surgery.

See [Source corpus & preprocessing](../source-corpus-and-preprocessing/).

### 5. Main-quest preservation: post-preprocess check

The exact active staged source files are checked again. `tes3cmd` backup files
such as `~1.esm` are excluded so a backup copy cannot falsely satisfy a quest
anchor that preprocessing deleted from the real input.

### 6. Canonical merge

Bing is first folded into Enhanced. Enhanced, PlanExp, Alt Start, CPP, and
Naboo are folded into the Patch. Patch is folded into V1.15. PartyHats is then
folded into the canonical merged result.

`StarwindMPRecords` and `StarwindVvardenfell` never enter this graph.

### 7. Equipment enchantment normalization

Otherwise-unenchanted clothing, armor, and weapons receive enchantment
capacity `375`.

This is a **Definitive Edition design policy**, not a compatibility hack. The
project deliberately favors equipment freedom and player personalization over
preserving Morrowind's original item-enchantment balance.

### 8. Main-quest preservation: post-merge check

The canonical merged artifact is checked before master decoupling.

### 9. Fold into Minimal

The canonical Starwind merge is merged into the deliberately tiny `Minimal`
plugin. `Minimal` provides the TES3 master context required by the historical
merge/decoupling path without contributing a second body of world/dialogue
content.

### 10. Standalone-only vanilla surgery

The staged Bethesda masters are adjusted only where Definitive Starwind has a
reviewed reason not to see certain inherited data. The canonical Bethesda JSON
files remain untouched.

The best-known example is the exact 53-INFO vanilla faction-dialogue prune.
See [Master decoupling](../master-decoupling/).

### 11. Recursive master decoupling

`addVanillaRefs` recursively imports required Bethesda records, reconstructs
and prunes dialogue, performs a second dependency-closure pass after dialogue
materialization, and removes the Bethesda masters.

### 12. Final masterless cleanup

Deletion tombstones are removed only after their inherited deletion semantics
have done their job. Exact duplicate physical MGEFs may be deduplicated, but
MGEF/SKIL/GMST are never reachability-pruned.

### 13. Main-quest preservation: final monolith check

The final `Starwind-Definitive.omwaddon` is checked once more.

### 14. Closure and dialogue validation

The monolith must have no masters, no unresolved hard references, and exact
OpenMW-effective dialogue. In strict mode, physical dialogue order and
serialized links must also be exact.

### 15. Data/content split

The validated monolith is partitioned into `Star_Data.omwaddon` and
`Starwind.omwaddon`, then the serialized pair is independently validated to
reconstruct the monolith exactly.

## Generated tree

```text
.swbuild/definitive/
├── work/
│   ├── compiled source plugins
│   ├── staged Bethesda masters
│   └── decoupleLog.txt
├── out/
│   ├── Starwind-Definitive.omwaddon
│   ├── Star_Data.omwaddon
│   └── Starwind.omwaddon
├── reports/
│   ├── main-quest-preservation.json
│   ├── Starwind-definitive-dialogue-source-hygiene.json
│   ├── Starwind-Definitive-dialogue-chain-audit.json
│   ├── starwind-split-report.json
│   └── late-actor-provenance.json
└── build-manifest.json
```

The closure helper currently writes its closure report under the shared
`.swbuild/reports/` path; the manifest records the exact path used by the
current build.

## Build outputs

`Starwind-Definitive.omwaddon` is an internal canonical oracle. The release
pair is:

```text
Star_Data.omwaddon
Starwind.omwaddon
```

The content plugin declares `Star_Data.omwaddon` as its sole master.

## Invariants

The builder is considered correct only if changing internal implementation
leaves these externally observable invariants intact:

- approved source corpus is fixed;
- no old TSI server-only surgery executes;
- main quest remains present at every checkpoint;
- monolith is masterless;
- hard closure is complete;
- OpenMW dialogue is exact;
- split reconstructs monolith exactly;
- Data never depends on content.

[API index](../) · [Source corpus & preprocessing](../source-corpus-and-preprocessing/) · [Validation](../validation-and-reports/)
