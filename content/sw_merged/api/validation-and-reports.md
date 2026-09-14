---
title: Validation & reports
weight: 60
description: Closure, dialogue, main-quest, late-actor, and split validators plus hard-failure policy.
---

# Validation & reports

A successful TES3 serialization is not considered evidence that the Definitive
build is correct. The pipeline uses multiple independent validators with
different models so that one implementation is not grading its own homework.

## Closure audit

`motherjungle_audit.py` converts the final plugin back to JSON and walks hard
typed dependencies.

It checks actor definitions, inventories, races/classes/factions, cell refs,
bodyparts, equipment, scripts, leveled lists, dialogue constraints, faction
reactions, and other modeled record relationships.

Hard success requires:

```text
masters                               0
hard unresolved occurrences           0
hard unresolved unique IDs            0
hard unresolved source records        0
```

`FFFF` in dialogue faction fields is recognized as TES3's `-NO FACTION-`
sentinel and does not create a fake `FACT "FFFF"` dependency.

## Dialogue audit

`dialogue_chain_audit.py` reconstructs the expected mixed dialogue database
independently and compares it to the masterless output.

The expected model uses:

- the exact staged Bethesda masters seen by `addVanillaRefs` when available;
- Starwind physical dialogue ownership;
- Rust's pre-dialogue actor-population snapshot from `decoupleLog.txt`;
- OpenMW INFO placement semantics;
- current topic/materialization policy;
- source provenance when a mismatch needs triage.

Hard failures include at least:

- missing/extra DIALs;
- missing live INFOs;
- extra dead INFOs;
- engine-order mismatch;
- precedence inversion that changes possible selection;
- retained dialogue payload mismatch;
- orphan INFOs.

Strict Definitive builds additionally require physical INFO order and serialized
links to match exactly. The current build satisfies those too.

Current documented result:

```text
expected live DIALs                    591
Definitive DIALs                       591
missing / extra DIALs                  0 / 0
missing / extra live INFOs             0 / 0
engine-order mismatches                 0
precedence inversions                   0
physical-order mismatches               0
serialized-link mismatches              0
dialogue content mismatches             0
INFO content mismatches                 0
orphan INFOs                            0
```

## Main-quest preservation

The MQ guard records every checkpoint to:

```text
.swbuild/definitive/reports/main-quest-preservation.json
```

It protects a reviewed set of quest DIALs, Shade-related NPC/script anchors,
`SW_ShipQuester`, and a required live placed reference.

Checks run before preprocessing, after preprocessing, after canonical merge,
and after decoupling.

The guard intentionally ignores `tes3cmd` backup plugin files.

## Split validation

`split_starwind.py` validates both topology and reconstruction:

- exact monolith reconstruction from `Star_Data` + `Starwind`;
- no effective record mismatches;
- zero Data-to-content dependencies;
- no newly unresolved dependencies;
- correct header master lists and file types.

A prior validator bug treated `CREA.sound` as a direct `SOUN` dependency and
produced hundreds of false unresolved entries. The field actually names the
creature whose sound-generator assignments are inherited, so the dependency
model resolves it as `Creature`.

## Late-actor provenance

`late_actor_provenance.py` compares:

```text
pre-dialogue-liveness actor population
vs.
final post-second-closure actor population
```

The audit exists because dialogue used to bootstrap vanilla actors into the
plugin. It reports which actors appear late and attempts to explain the causal
references that imported them.

Late actors are a diagnostic set, not an automatic deletion list. The proper
fix is to remove or correct the causal dependency when that dependency is
proven dirty.

## Source dialogue hygiene

`dialogue_source_hygiene.py` is not a final-output validator. It is a source
forensics tool that classifies physical Starwind INFOs relative to their real
parent state.

It is used to find exact copies, link-only TESCS dirt, parent deletions, and
semantic modifications before deciding what belongs in canonical source.

## Build manifest

`build-manifest.json` records:

- edition name;
- included sources and SHA-256 hashes;
- explicitly excluded sources;
- output paths;
- report paths;
- closure counts;
- split counts and invariants.

This makes a built artifact auditable back to the exact source corpus rather
than only to a human-readable version number.

## Report locations

Typical current paths:

```text
.swbuild/definitive/build-manifest.json
.swbuild/definitive/work/decoupleLog.txt
.swbuild/definitive/reports/main-quest-preservation.json
.swbuild/definitive/reports/Starwind-definitive-dialogue-source-hygiene.json
.swbuild/definitive/reports/Starwind-Definitive-dialogue-chain-audit.json
.swbuild/definitive/reports/starwind-split-report.json
.swbuild/definitive/reports/late-actor-provenance.json
.swbuild/reports/Starwind-Definitive-closure-audit.json
```

The manifest is authoritative if a helper emits one report under a historical
shared path.

## Why multiple validators are retained after reaching zero errors

Many bugs found during this project were not serialization failures:

- full chains of irrelevant Morrowind dialogue could serialize perfectly;
- tombstones could remain physically present after their parents were gone;
- same-named IDs in different record namespaces could cause false dependency
  classification;
- final actor populations could make the validator expect dialogue that Rust
  correctly rejected earlier in the pipeline;
- old TSI preprocessing could manufacture references to excluded MP-only
  records while still producing a valid TES3 file.

The validators therefore document the semantic contract, not just build
health. A future refactor is safe only when the independent invariants stay
green.

[API index](../) · [Build pipeline](../build-pipeline/) · [Dialogue canonicalization](../dialogue-canonicalization/)
