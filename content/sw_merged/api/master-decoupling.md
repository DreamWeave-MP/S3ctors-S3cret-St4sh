---
title: Master decoupling & dependency closure
weight: 30
description: Minimal seed, motherJungle/addVanillaRefs closure, staged vanilla surgery, tombstones, and master removal.
---

# Master decoupling & dependency closure

The canonical Starwind merge still inherits Bethesda master data. Definitive
Edition converts that merged artifact into a self-contained OpenMW plugin by
importing only the required Bethesda records and then removing all masters.

## Minimal seed

The canonical merged Starwind plugin is folded into `Minimal` before
`addVanillaRefs` runs.

`Minimal` is deliberately tiny and contributes no meaningful second dialogue
universe. Its purpose is to provide a controlled TES3 master context for the
historical merge/decoupling workflow.

## `addVanillaRefs`

motherJungle's `addVanillaRefs` is the core decoupler. It recursively resolves
hard TES3 references from the current plugin into staged Morrowind, Tribunal,
and Bloodmoon inputs.

The dependency model covers, among other relationships:

- NPC race, class, faction, head, hair, script, inventory, and spells;
- creature inventory, spells, script, and creature sound-generator inheritance;
- equipment bodyparts and enchantments;
- containers, books, ingredients, lights, activators, and doors;
- leveled-list entries;
- cell-reference target, owner, key, trap, and soul relationships;
- faction reactions;
- dialogue speaker/player constraints after dialogue liveness is known;
- other typed TES3 references modeled by the closure audit.

Typed namespaces matter. A text ID collision across record types is not a
valid dependency. `RACE "Argonian"` and `DIAL "argonian"` are independent
records even though their normalized editor-ID strings collide.

## Why dialogue dependencies are deferred

Earlier versions allowed pre-pruned dialogue to feed the first generic closure
pass. That created a feedback loop:

```text
dirty vanilla/Starwind INFO
    -> speaker NPC imported
    -> actor now appears live
    -> more inherited dialogue appears live
    -> more vanilla content imported
```

The modern decoupler therefore builds the pre-dialogue actor population from
non-dialogue dependencies first, reconstructs/prunes dialogue against that
population, and only then performs another dependency-closure pass for the
surviving dialogue.

The validator records the pre-dialogue-liveness population separately from the
final actor population so this timing is part of the acceptance model rather
than an undocumented implementation detail.

## Staged vanilla INFO surgery

A closure audit once identified real unresolved faction dependencies created by
retained vanilla dialogue:

```text
Morag Tong             61 references
Hands of Almalexia      4 references
Census and Excise       2 references
```

Those 67 dependency occurrences came from **53 unique INFO IDs**. A broad
`tes3cmd --sub-match` experiment returned 563 IDs and was rejected because it
matched faction names in arbitrary INFO text/fields.

The final 53-ID set comes from exact unresolved-source provenance and is
embedded in the build driver. Those INFOs are removed only from the temporary
staged Bethesda masters before dialogue materialization.

The purpose is not to modify Bethesda data globally. It is to define which
pieces of vanilla dialogue are valid dependencies of masterless Starwind.

## `FFFF` is not a faction

TES3 uses `FFFF` in dialogue faction fields as the Construction Set
`-NO FACTION-` sentinel.

It must never create a dependency on a `FACT "FFFF"` record. The closure audit
special-cases the sentinel accordingly.

## Second closure pass

Dialogue materialization can create new hard dependencies after the first
closure has already completed. Factions were the concrete case that exposed
this.

The current sequence is:

```text
non-dialogue recursive closure
        -> capture pre-dialogue actor population
        -> dialogue reconstruction / liveness / physical rebuild
        -> second recursive closure over surviving dialogue dependencies
        -> remove masters
```

## Tombstones

Deletion records must survive long enough to suppress the inherited records
they delete. They are not useful after the parent masters are gone.

Definitive therefore follows this rule:

```text
merge + inherited-state reconstruction
        -> apply deletion semantics
        -> remove masters
        -> strip dead tombstones from final masterless serialization
```

The dialogue cleanup proved this mechanically. A prior Standalone artifact
contained exactly **4,826** excess physical INFO records, and all 4,826 were
TES3 deletion tombstones. Once the decoupler stopped serializing dead INFO
records, the physical INFO set, physical order, and serialized links all became
exactly equal to the expected OpenMW-effective chain.

The same principle was later generalized to non-dialogue tombstones.

## Exact duplicate foundational records

MGEF/SKIL/GMST are foundational record families and are not subject to
reachability pruning. They may be necessary even when no ordinary object graph
appears to reference them.

Exact *physical duplicates* are different: duplicate byte-identical MGEF
records can be collapsed without deciding that the effect is unused. This is
why duplicate MGEF cleanup is allowed while MGEF reachability pruning is not.

## Other dependency cleanups discovered during decoupling

The decoupling audits also exposed several narrower problems:

- vanilla region `sleep_creature` links could import Morrowind/Bloodmoon sleep encounter leveled lists and their transitive creatures into Starwind pseudo-exterior regions;
- dialogue-only actor imports exposed TESCS link-dirt INFOs that pulled vanilla NPCs and their inventories/scripts into the masterless result;
- leftover exterior/LAND/LTEX islands from the old corpus were audited and removed where proven unnecessary;
- deleted records still referenced by live data were surfaced once final tombstone stripping stopped hiding them.

These were fixed at the causal edge rather than by deleting arbitrary imported
records from the final plugin.

## Closure acceptance

A valid Definitive monolith must report:

```text
masters = 0
hard unresolved occurrences = 0
hard unresolved unique IDs = 0
hard unresolved source records = 0
```

The closure audit is intentionally independent of successful TES3
serialization. A plugin that saves successfully can still contain unresolved
editor-ID references and is not considered valid.

[API index](../) · [Dialogue canonicalization](../dialogue-canonicalization/) · [Validation](../validation-and-reports/)
