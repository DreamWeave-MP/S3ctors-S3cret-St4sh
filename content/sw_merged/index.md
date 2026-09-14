---
title: Starwind Merged Plugin Project
description: Reproducible Definitive Starwind builds with recursive master decoupling, audited dialogue behavior, and a validated Data/content split.
date: 2023-04-26

taxonomies:
  tags:
    - Starwind
    - Patches
    - OpenMW

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - Star_Data.omwaddon
      - Starwind.omwaddon

  version: 0.3
---
<h1 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Brought to you by the Starwind Team and all the players on <a href="https://discord.gg/wcMj2b2svh">The Starwind Initiative</a></h1>

The **Starwind Merged Plugin Project** builds one maintained, masterless
Definitive Starwind edition. Its purpose is to turn the approved Starwind
source corpus into a reproducible OpenMW release pair while preserving the
content and behavior the project actually intends to ship.

The build produces one canonical intermediate and two release plugins:

- **`Starwind-Definitive.omwaddon`** is the complete masterless monolith used for auditing and reconstruction.
- **`Star_Data.omwaddon`** contains stable reusable definitions and has no masters.
- **`Starwind.omwaddon`** contains world content, actors, state, scripts, and dialogue and depends only on `Star_Data.omwaddon`.

Install the two split plugins together. `Starwind.omwaddon` must load after
`Star_Data.omwaddon`; its header declares that dependency explicitly.

<!-- more -->

{{ install_instructions(describe=true) }}

> **The Definitive pair is the only supported merged Starwind product in this project.** Do not combine it with an older merged Starwind plugin.
>
> **OpenMW is the compatibility target.** The build is masterless and is not intended to preserve Morrowind.exe-specific behavior.

## Project status

As of **2026-09-13**, the Definitive pipeline passes the complete strict
validation suite:

| Audit | Current result |
| --- | ---: |
| Monolith records, excluding header | **30,707** |
| Header masters | **0** |
| Hard unresolved dependencies | **0** |
| Expected live DIALs | **591** |
| Definitive DIALs | **591** |
| Missing/extra DIALs | **0 / 0** |
| Missing/extra live INFOs | **0 / 0** |
| OpenMW engine-order mismatches | **0** |
| Precedence inversions | **0** |
| Physical-order mismatches | **0** |
| Serialized-link mismatches | **0** |
| Dialogue content mismatches | **0** |
| Orphan INFOs | **0** |

The split is record-for-record exact:

| Output | Records, excluding header |
| --- | ---: |
| `Star_Data.omwaddon` | **13,374** |
| `Starwind.omwaddon` | **17,333** |
| Reconstructed total | **30,707** |

The split has zero Data-to-content dependencies, zero newly unresolved
dependencies, and no header masters on `Star_Data`.

## Approved source corpus

`build_starwind.py` compiles this fixed source set:

- Morrowind, Tribunal, Bloodmoon
- Minimal
- Starwind Remastered V1.15
- Starwind Remastered Patch
- Bing's Race Pack
- Starwind Enhanced
- PlanExp
- Alt Start
- Community Patch Project
- Naboo
- PartyHats

`StarwindMPRecords` and `StarwindVvardenfell` are explicitly excluded. They
are not compiled, preprocessed, merged, or used as dependency inputs by the
Definitive builder.

The canonical inputs are the JSON files under `plugins/`. Generated binaries,
reports, and temporary work files live under `.swbuild/` and can be deleted at
any time.

## Why this exists

The original Starwind data is the product of years of Construction Set
editing, patching, merging, deployment scripts, and multiplayer maintenance.
It contains the usual TES3 archaeology:

- redundant overrides introduced by TESCS;
- dialogue INFOs dirtied only because neighboring INFOs were inserted;
- deliberate deletions mixed with accidental copies;
- stale references to Tribunal and Morrowind systems;
- duplicate or corrupt cell references;
- script bytecode that should not survive modern rebuilding;
- historical one-off fixes from old Builder automation.

The goal is not to run a generic merge command. The goal is to make the
intended transformation explicit and continuously prove that the result is
self-contained and behaves correctly in OpenMW.

## Provenance and tools

The current pipeline uses the following components:

| Component | Role | Provenance |
| --- | --- | --- |
| `build_starwind.py` | Definitive source graph, preprocessing, merge, validation, and split orchestration | current project pipeline |
| `motherjungle_audit.py` | Record parser, historical surgery helpers, closure audit, and decoupling support | local transcription of prior Builder behavior |
| `addVanillaRefs` | Recursive vanilla-reference import and master decoupling | motherJungle |
| `merge_to_master` | TES3 merge engine | Greatness7 |
| `tes3conv` | JSON to TES3 plugin conversion | version 0.4.1 |
| `tes3cmd` | Deterministic record surgery and diagnostics | historical Starwind tooling |
| OpenMW | Runtime target and dialogue behavior oracle | OpenMW project |

Historical multiplayer maintenance remains useful provenance for fixes and
source archaeology, but it is not a second build product here. The old
`tsi_preprocess()` implementation remains available only as historical code;
`build_starwind.py` never calls it.

## Repository layout

```text
sw_merged/
├── addVanillaRefs
├── build_starwind.py          # the one supported build entry point
├── merge_to_master
├── tes3cmd
├── tes3conv
├── motherjungle_audit.py      # parsing, historical helpers, closure audit
├── split_starwind.py          # Data/content partition and reconstruction audit
├── dialogue_chain_audit.py    # OpenMW dialogue equivalence validator
├── dialogue_source_hygiene.py
├── late_actor_provenance.py
├── plugins/                   # canonical JSON inputs
└── .swbuild/                  # disposable generated build tree
```

Tools are resolved beside the project scripts first and from `$PATH` second.

## Quick start

Build and require behavioral plus structural validation:

```bash
./build_starwind.py --strict
```

Keep the intermediate work tree and decoupler log for investigation:

```bash
./build_starwind.py --strict --keep-work
```

The normal build sequence is:

```text
approved source corpus
        -> source compilation and hygiene report
        -> explicit Definitive preprocessing
        -> Definitive merge graph
        -> master decoupling and dialogue reconstruction
        -> final tombstone cleanup and validation
        -> Star_Data / Starwind split
```

## Definitive generated build tree

```text
.swbuild/definitive/
├── work/                         # temporary compiled inputs and decoupler log
├── out/
│   ├── Starwind-Definitive.omwaddon
│   ├── Star_Data.omwaddon
│   └── Starwind.omwaddon
├── reports/
│   ├── main-quest-preservation.json
│   ├── starwind-split-report.json
│   ├── Starwind-Definitive-dialogue-chain-audit.json
│   └── late-actor-provenance.json
└── build-manifest.json
```

The output locations are also recorded in `build-manifest.json`.

## Definitive build pipeline

`build_starwind.py` always performs the same sequence.

1. Compile the approved JSON source corpus with `tes3conv`.
2. Run parent-aware source dialogue hygiene.
3. Assert that the reviewed main-quest records and live cell references exist.
4. Apply only the reviewed Definitive preprocessing operations.
5. Merge Bing's Race Pack into Enhanced.
6. Merge Enhanced, PlanExp, Alt Start, CPP, and Naboo into Patch.
7. Merge Patch into V1.15, then merge PartyHats into the canonical result.
8. Normalize the canonical equipment enchantment values.
9. Fold the canonical result into Minimal for master decoupling.
10. Apply staged vanilla dependency surgery and run `addVanillaRefs`.
11. Remove final tombstones, then recheck main-quest preservation.
12. Audit closure and OpenMW dialogue equivalence.
13. Split the masterless monolith and validate exact reconstruction.

The merge graph is deliberately fixed:

```text
Bing's Race Pack  -> Starwind Enhanced
Enhanced          -> StarwindRemasteredPatch
PlanExp           -> StarwindRemasteredPatch
Alt Start         -> StarwindRemasteredPatch
CPP               -> StarwindRemasteredPatch
Naboo             -> StarwindRemasteredPatch
Patch             -> StarwindRemasteredV1.15
PartyHats         -> Starwind-Definitive
Definitive        -> Minimal -> addVanillaRefs -> final monolith
```

### Definitive preprocessing policy

The Definitive path deliberately does not apply the historical multiplayer
surgery. It does not perform the old gold or Kolto substitutions, Courte cleanup,
Ship Quester removal, Hutt/Ragax/Badhiya reference removals, or old Taris and
other main-quest instance removals. It also does not perform Vvardenfell
surgery because Vvardenfell is outside the approved corpus.

The explicit Definitive cleanup is limited to reviewed operations such as:

- known script and text typo corrections;
- script bytecode removal before recompilation;
- reviewed junk-cell and source cleanup;
- Bings orphan bodypart removal and dirty-cell cleanup;
- Alt Start's conflicting Imperial Prison Ship cell removal;
- Naboo's obsolete DRM records and attached references;
- reviewed Enhanced duplicate and reference corrections.

Every preprocessing stage checks the main-quest anchors. The guard includes
17 reviewed records and requires a live `SW_ShipQuester` reference in
`Manaan, Docking Bay`; deleted references do not satisfy the check.

### Definitive enchantment normalization

Otherwise-unenchanted clothing, armor, and weapons are normalized to an
enchantment capacity of **375**. This is an intentional Definitive design
decision, not accidental historical multiplayer policy. Starwind favors player
personalization and equipment freedom over preserving vanilla Morrowind
balance.

### Master decoupling

The canonical merge is folded into `Minimal` before `addVanillaRefs` runs.
The decoupler recursively imports the Bethesda records that Starwind really
needs, reconstructs live dialogue, performs a second closure pass after
dialogue materialization, removes masters, and leaves the final monolith
masterless.

Vanilla surgery is applied only to staged copies in
`.swbuild/definitive/work/`. Canonical Bethesda JSON inputs are never modified
by this step.

Deletion records are retained through the merge and decoupling stages. They
are removed only during final tombstone cleanup, after their deletion
semantics have completed their work.

## Dialogue validation

Dialogue is validated against the effective OpenMW result rather than against
raw physical record history. The validator accounts for:

- Starwind-owned DIAL and INFO records;
- inherited INFOs that remain live for Starwind's actor and game population;
- OpenMW `prev_id` insertion and replacement behavior;
- explicit script `AddTopic` dependencies;
- actor-domain constraints and precedence competition;
- dialogue payload preservation.

Plain topic words in response text do not materialize unrelated inherited
vanilla dialogue. Typed TES3 namespaces are resolved independently, so
`RACE "Argonian"` does not imply `DIAL "argonian"`.

The current Definitive dialogue result is exact:

```text
expected live DIALs                    591
Definitive DIALs                       591
missing / extra DIALs                  0 / 0
missing / extra live INFOs              0 / 0
engine-order mismatches                 0
precedence inversions                   0
physical-order mismatches               0
serialized-link mismatches              0
dialogue content mismatches             0
orphan INFOs                            0
```

Behavioral and engine-order failures are mandatory build failures. Physical
and serialized checks are also required by `--strict`; they are retained as
forensic signals because physical history is still useful when investigating
source dirt.

## Closure validation

The closure auditor converts the final plugin back to JSON and walks hard
typed dependencies across actors, creatures, inventories, definitions, cells,
bodyparts, equipment, scripts, leveled lists, dialogue constraints, and
faction reactions.

The current result is:

```text
masters                               0
hard unresolved occurrences           0
hard unresolved unique IDs            0
hard unresolved source records        0
```

The split validator uses record namespaces when resolving dependencies. A
creature sound field points to a TES3 creature sound-generator record, so it
is resolved as `Creature`, not incorrectly reported as a missing `Sound`.

## Data/content split

The splitter partitions the validated masterless monolith:

```text
Star_Data.omwaddon       stable definitions and reusable data
        ^
        |
Starwind.omwaddon        world, actors, state, scripts, and dialogue
```

Data candidates include definitions such as races, classes, factions, sounds,
spells, bodyparts, creatures, equipment, containers, and leveled lists. World
records such as cells, pathgrids, actors, regions, books, scripts, globals, and
dialogue remain in `Starwind` by default. A candidate is demoted when its typed
dependencies require content; scripts cross the boundary only through an
explicit allowlist.

The splitter validates the serialized plugins, not only its in-memory model:

- exact record reconstruction;
- no effective record mismatches;
- no `Star_Data -> Starwind` dependencies;
- no newly introduced unresolved dependencies;
- correct `Starwind -> Star_Data` master declaration.

Run the splitter independently only when inspecting an existing monolith:

```bash
./split_starwind.py \
  --source .swbuild/definitive/out/Starwind-Definitive.omwaddon \
  --data-output .swbuild/definitive/out/Star_Data.omwaddon \
  --content-output .swbuild/definitive/out/Starwind.omwaddon \
  --report .swbuild/definitive/reports/starwind-split-report.json
```

The normal `build_starwind.py` invocation performs this automatically.

## Late actor provenance

The late-actor audit compares actors present before dialogue liveness and
actors present in the final masterless output. The current Definitive corpus
has:

```text
pre-liveness actors                     2427
final actors                             2441
late actors                                14
```

All 14 are currently classified as requiring further provenance review. The
report is diagnostic and does not alter content.

Run it against a kept work tree with:

```bash
python3 late_actor_provenance.py \
  --log .swbuild/definitive/work/decoupleLog.txt \
  --standalone .swbuild/definitive/out/Starwind-Definitive.omwaddon \
  --report .swbuild/definitive/reports/late-actor-provenance.json \
  --markdown .swbuild/definitive/reports/late-actor-provenance.md
```

## Source-edit policy

Canonical source cleanup belongs in `plugins/*.json` when a record is
genuinely corrupt, redundant, or intentionally removed from Starwind. Build
policy belongs in `build_starwind.py` when it defines how the approved corpus
becomes the Definitive product.

Vanilla dependency pruning belongs only in staged files under
`.swbuild/definitive/work/`. This prevents the project from maintaining
modified Bethesda source data while still allowing the Definitive build to
define its exact dependency boundary.

## Reports and artifacts

Useful generated files include:

```text
.swbuild/definitive/build-manifest.json
.swbuild/definitive/work/decoupleLog.txt
.swbuild/definitive/reports/main-quest-preservation.json
.swbuild/definitive/reports/starwind-split-report.json
.swbuild/reports/Starwind-Definitive-closure-audit.json
.swbuild/definitive/reports/Starwind-Definitive-dialogue-chain-audit.json
.swbuild/definitive/reports/late-actor-provenance.json
```

The closure report is emitted under `.swbuild/reports/` by the historical
closure helper; the manifest records its exact path.

## Compatibility and warnings

- The supported release is the `Star_Data.omwaddon` plus `Starwind.omwaddon` pair.
- Do not load an older merged Starwind plugin alongside the Definitive pair.
- OpenMW is the release oracle; Morrowind.exe behavior is not the target for the masterless result.
- Do not import an entire Morrowind subsystem merely to satisfy a dead dialogue condition. Prove the dependency is live first.
- Same editor-ID text in different TES3 namespaces does not imply the same dependency.
- Generated `.swbuild` files are disposable. Canonical source changes belong in `plugins/*.json` and the source repositories.

## History

The project grew out of Starwind maintenance and deployment work. Multiplayer
testing exposed many broken assumptions in the original data, and those fixes
provided useful source archaeology for the current build. The Definitive
pipeline keeps the validated corrections and intentional design decisions,
but no longer exposes the historical deployment variants as separate products.

The principal historical references remain:

- [Starwind-Builder](https://github.com/DreamWeave-MP/Starwind-Builder/)
- [motherJungle](https://github.com/DreamWeave-MP/motherJungle)
- [merge_to_master](https://github.com/Greatness7/merge_to_master)
- [OpenMW](https://github.com/OpenMW/openmw)

## Credits

{% credits(default=true) %}
Most of the changes and fixes in here were drawn from bug reports and other errata discovered by the Starwind community. Thanks to all of you, as well <3.

- Special Thanks to:  
Ignatious  
SkoomaBreath  
RymanTheGreat  
VidiAquam
{% end %}
