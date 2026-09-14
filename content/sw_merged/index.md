---
title: Starwind Merged Plugin Project
description: Reproducible local builds of the merged Starwind plugin family, including an OpenMW-targeted masterless Standalone build with recursive vanilla dependency closure and audited dialogue decoupling.
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
      - Starwind-Solo.omwaddon

  version: 0.3
---
<h1 style="font-size: 1.5em;text-align: center;font-style: italic;padding-top: 45px;padding-bottom: 45px;">Brought to you by the Starwind Team and all the players on <a href="https://discord.gg/wcMj2b2svh">The Starwind Initiative</a></h1>

The **Starwind Merged Plugin Project** began as an effort to consolidate Starwind's main ESM files into a single maintained plugin. It has since grown into a reproducible build and audit pipeline whose long-term goal is to make Starwind independent of `Morrowind.esm`, `Tribunal.esm`, and `Bloodmoon.esm` while preserving the behavior Starwind actually relies on.

The current project produces three related build targets:

- **`Starwind-Solo.omwaddon`** — the merged single-player Starwind base, preserving the historical Starwind-Builder merge behavior.
- **`Starwind-Standalone.omwaddon`** — an OpenMW-targeted, masterless build that imports the vanilla records Starwind really needs, prunes vanilla content it does not, and reconstructs dialogue under OpenMW semantics.
- **`Starwind-TSI.omwaddon`** — the historical multiplayer/TSI merge path when all TSI-only source plugins are present.

<!-- more -->

{{ install_instructions(describe=true) }}

> **Do not load more than one merged Starwind build at once.** `Solo`, `Standalone`, and `TSI` are alternative products with meaningfully different content and dependency assumptions.
>
> **OpenMW is the compatibility target for Standalone.** Morrowind.exe compatibility is not a goal for the masterless build.

## Project status

As of **2026-09-13**, the Standalone pipeline has reached the first strong behavioral-equivalence milestone:

| Audit | Current result |
| --- | ---: |
| Header masters | **0** |
| Hard unresolved dependencies | **0** |
| Expected live DIALs | **498** |
| Standalone DIALs | **498** |
| Missing/extra DIALs | **0 / 0** |
| Missing/extra effective INFOs | **0 / 0** |
| OpenMW engine-order mismatches | **0** |
| Precedence inversions | **0** |
| Dialogue payload mismatches | **0** |
| Orphan INFOs | **0** |
| Physical INFO-order mismatches | 12, diagnostic only |
| Serialized `prev_id`/`next_id` mismatches | 33, diagnostic only |

The remaining physical/link differences do **not** currently change the OpenMW-effective dialogue order. Cleaning that physical historical baggage is the next phase of this project.

The current Standalone closure audit reports **31,884 objects plus the header**, no masters, and no unresolved hard references.

## Why this exists

The original Starwind data is the product of years of Construction Set editing, patching, merging, multiplayer fixes, and several generations of build tooling. It contains all the usual TES3 archaeology:

- redundant overrides introduced by TESCS;
- dialogue INFOs dirtied only because neighboring INFOs were inserted;
- old vanilla dialogue carried into Starwind chains;
- deliberate deletions mixed with accidental copies;
- stale references to Tribunal/Morrowind systems;
- duplicate/corrupt cell references;
- script bytecode that should not survive modern rebuilding;
- historical one-off fixes that existed only in Starwind-Builder CI.

The goal is therefore **not** simply to run a generic merge command. The goal is to reproduce the known-good historical surgery, make every transformation explicit, and continuously prove that the result still behaves correctly in OpenMW.

## Provenance and reference implementations

The current pipeline is derived from the following projects and source material:

| Component | Role | Provenance |
| --- | --- | --- |
| Starwind-Builder | Historical CI/build surgery and merge ordering | <https://github.com/DreamWeave-MP/Starwind-Builder/> |
| `build.sh` | Exact historical `tes3cmd` surgery transcribed into Python | preserved locally and transcribed into `motherjungle_audit.py` |
| motherJungle / `addVanillaRefs` | Recursive vanilla-reference import and master decoupling | <https://github.com/DreamWeave-MP/motherJungle> |
| `merge_to_master` | Historical Starwind merge engine | <https://github.com/Greatness7/merge_to_master> |
| MTM dialogue implementation | Important comparison point for Morrowind.exe-style dialogue merging | <https://raw.githubusercontent.com/Greatness7/merge_to_master/refs/heads/main/src/types/dialogue.rs> |
| `tes3conv` | JSON ↔ TES3 plugin conversion | <https://github.com/Greatness7/tes3conv/releases/tag/v0.4.1> |
| Makron Dockerfile | Confirms historical Builder-side `tes3conv` 0.4.1 usage | <https://github.com/DreamWeave-MP/makron/blob/e0084ae44ce59949937005fee173725821ad900b/Dockerfile#L2> |
| `tes3cmd` | Deterministic record surgery and diagnostics | historical Starwind-Builder dependency |
| OpenMW | Runtime compatibility target and authoritative dialogue behavior | <https://github.com/OpenMW/openmw> |

The original Starwind developers opened permissions on the project, and this merged-plugin work has been developed over several years alongside the Starwind/TSI team. A large number of merge fixes were found while maintaining multiplayer and later fed back into this build project.

## Repository layout

The St4sh `sw_merged` directory is intentionally self-contained:

```text
sw_merged/
├── addVanillaRefs              # motherJungle standalone decoupler
├── merge_to_master             # Greatness7 merge tool
├── tes3conv                    # JSON/TES3 converter
├── tes3cmd                     # preferred local copy; PATH fallback supported
├── motherjungle_audit.py       # build driver + dependency closure auditor
├── dialogue_chain_audit.py     # OpenMW dialogue equivalence validator
├── dialogue_source_hygiene.py  # parent-aware Starwind dialogue dirt auditor
├── plugins/
│   ├── Morrowind.json
│   ├── Tribunal.json
│   ├── Bloodmoon.json
│   ├── Minimal.json
│   ├── StarwindRemasteredV1.15.json
│   ├── StarwindRemasteredPatch.json
│   └── ... optional TSI/MP sources ...
└── .swbuild/                   # disposable generated work/output/report tree
```

The canonical build inputs are the JSON files under `plugins/`. `.swbuild/` is generated and may be deleted at any time.

Tools are resolved beside `motherjungle_audit.py` first and from `$PATH` second.

## Quick start

Verify tools and available sources:

```bash
./motherjungle_audit.py doctor
```

Build the normal merged single-player plugin:

```bash
./motherjungle_audit.py build solo
```

Build the masterless Standalone plugin:

```bash
./motherjungle_audit.py build standalone
```

Build the historical TSI path:

```bash
./motherjungle_audit.py build tsi
```

Build everything available locally and require Standalone dependency closure to succeed:

```bash
./motherjungle_audit.py all --fail-on-unresolved
```

Run the closure audit directly:

```bash
./motherjungle_audit.py audit \
  .swbuild/standalone/out/Starwind-Standalone.omwaddon \
  --fail-on-unresolved
```

Run the dialogue-equivalence validator:

```bash
./dialogue_chain_audit.py
```

Use exact physical/link parity as an additional forensic requirement when desired:

```bash
./dialogue_chain_audit.py --strict-structure
```

Audit Starwind's source dialogue against its inherited parent state:

```bash
./dialogue_source_hygiene.py
./dialogue_source_hygiene.py --topic hello
```

## Generated build tree

Each build mode receives an independent disposable work tree:

```text
.swbuild/
├── solo/
│   ├── work/
│   ├── out/Starwind-Solo.omwaddon
│   ├── reports/
│   └── build-manifest.json
├── standalone/
│   ├── work/
│   │   ├── Morrowind.esm
│   │   ├── Tribunal.esm
│   │   ├── Bloodmoon.esm
│   │   ├── Starwind.esp
│   │   └── decoupleLog.txt
│   ├── out/Starwind-Standalone.omwaddon
│   ├── reports/
│   └── build-manifest.json
└── tsi/
    └── ...
```

Keeping each mode isolated is important: the Standalone build intentionally modifies its **staged vanilla masters** before `addVanillaRefs`; those work copies must never leak into the Solo or TSI build.

# Build pipeline

## 1. Compile JSON sources

`motherjungle_audit.py` uses `tes3conv` to compile the required `plugins/*.json` files into ESM/ESP files in the selected mode's `.swbuild/<mode>/work/` directory.

Even `solo` stages `Morrowind.esm`, `Tribunal.esm`, and `Bloodmoon.esm`, because `merge_to_master` resolves declared masters by filename from its current working directory.

No canonical Bethesda source JSON is modified by this staging step.

## 2. Reproduce historical Starwind-Builder preprocessing

The old Starwind-Builder `build.sh` has been transcribed into `motherjungle_audit.py` rather than hidden behind an ad-hoc hook. The goal is to keep historical behavior inspectable and reproducible.

Common preprocessing includes, among other operations:

- correcting known script/text typos (`who's ship` → `whose ship`, plasma grenade spelling, `Asteriod` → `Asteroid`);
- deleting the unreferenced `SCPT "sw_"` record;
- destroying compiled script bytecode so scripts are rebuilt from source text;
- deleting the historical junk-cell/PGRD list and exterior cells from the Starwind sources;
- removing `sEffectTurnUndead` and magic effect `101` from the Patch;
- removing the old Rakghoul entry from `sw_sandcreatures`;
- applying known Enhanced duplicate/reference/bodypart fixes when Enhanced is present;
- removing the `DoNothing` script reference from the known small door record;
- preserving the historical Tatooine ObjIdx diagnostic as a build artifact.

The exact junk-cell list and exact `tes3cmd` commands live in `motherjungle_audit.py`; they are intentionally not paraphrased into a second competing source of truth here.

### TSI-specific preprocessing

The `tsi` path additionally reproduces the historical multiplayer surgery, including:

- exact ObjIdx/MastIdx cell-reference removals;
- TSI gold and Kolto substitutions;
- Bing's race-pack cell cleanup;
- duplicate Hutt/Nar Shaddaa/Taris actor/reference cleanup;
- Courte companion script removal;
- ship-quester cleanup;
- Naboo DRM/test-content cleanup;
- Vvardenfell and alternate-start cell cleanup.

One historical oddity is deliberately preserved: the old `build.sh` creates and cleans `beastlair.esp`, but never merges it back. The Python transcription does the same rather than silently rewriting history.

## 3. Merge graphs

`merge_to_master` is invoked exactly as `merge_to_master <plugin> <master>`; the second file becomes the merged result.

### Solo

```text
StarwindRemasteredPatch.esm
        ↓ merge_to_master
StarwindRemasteredV1.15.esm
        ↓ rename
Starwind-Solo.omwaddon
```

Equivalent command:

```bash
merge_to_master StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
```

### Standalone seed

Standalone first builds `Starwind-Solo.omwaddon`, then folds it into the deliberately minimal master seed:

```bash
merge_to_master Starwind-Solo.omwaddon Minimal.esp
mv Minimal.esp Starwind.esp
```

`Minimal` contributes no dialogue of its own; it exists to provide a minimal TES3 master context before complete decoupling.

### TSI

The historical TSI ordering is preserved:

```text
bings race pack       → Starwind Enhanced
Starwind Enhanced     → RemasteredPatch
StarwindPlanExp       → RemasteredPatch
alt_start             → RemasteredPatch
StarwindVvardenfell   → RemasteredPatch
Community Patch       → RemasteredPatch
naboo                 → RemasteredPatch
RemasteredPatch       → V1.15
```

After the merge, historical `DELE` instances are removed. `StarwindMPRecords` is merged unless `--nomp` is requested, then `PartyHats` is merged. The historical final enchantment normalization to `375` is also preserved.

# Standalone/masterless pipeline

Standalone is where the modern work happens.

## 4. Prune known-dead vanilla faction dialogue from staged masters

Before `addVanillaRefs` sees the vanilla masters, `motherjungle_audit.py` removes **53 known-dead vanilla INFOs** from the **temporary** staged copies of:

```text
Morrowind.esm
Tribunal.esm
Bloodmoon.esm
```

These 53 INFOs were not guessed by a broad text search. They were derived from the dependency closure audit after dialogue materialization:

```text
Morag Tong             61 unresolved references
Hands of Almalexia      4 unresolved references
Census and Excise       2 unresolved references
FFFF                     2 apparent references
```

The first 67 references collapsed to **53 unique INFO IDs**. The two `FFFF` references were not real dependencies at all: `FFFF` is TES3's `-NO FACTION-` dialogue sentinel.

A preliminary `tes3cmd --sub-match` experiment returned **563 INFO IDs** because it matched faction names anywhere in INFO data. That result was deliberately rejected. The embedded 53-ID set comes from the exact closure-source IDs instead.

The authoritative ID list is `DEAD_VANILLA_FACTION_INFO_IDS` in `motherjungle_audit.py`.

This surgery happens only in `.swbuild/standalone/work/`; it does **not** alter the canonical Bethesda JSON sources and it occurs after the `Starwind-Solo → Minimal` merge, so it cannot perturb the earlier MTM merge.

## 5. Recursive vanilla dependency closure (`addVanillaRefs`)

`addVanillaRefs` is the motherJungle decoupler. Its job is to make `Starwind.esp` self-contained by importing records referenced from Starwind that would otherwise have come from the Bethesda masters.

The resolver recursively follows hard TES3 dependencies such as:

- NPC race/class/faction/head/hair/script/inventory/spells;
- creature inventories/spells/scripts;
- armor/clothing bodyparts and enchantments;
- doors, activators, containers, books, ingredients, lights, sounds;
- leveled-list entries;
- cell-reference targets/owners/keys/traps/souls;
- faction reactions;
- dialogue speaker/player constraints;
- other typed references represented by the closure audit.

Some TES3 record families are deliberately special-cased rather than blindly copied. Dialogue in particular receives its own reconstruction pass described below.

## 6. Reconstruct and physically prune dialogue

Dialogue became the hardest part of the masterless build because Starwind simultaneously:

- adds thousands of new INFOs;
- modifies some vanilla INFOs;
- deliberately deletes large portions of vanilla dialogue;
- depends on some unchanged vanilla INFOs;
- contains substantial TESCS-generated structural dirt.

The final strategy is therefore **not** "copy Starwind-owned INFOs only" and not "keep all vanilla dialogue but poison it".

Instead, `addVanillaRefs` reconstructs the effective mixed dialogue database, computes the Starwind-live subset, physically discards everything else, and rewrites the surviving chain.

### OpenMW is authoritative

`merge_to_master` contains a highly useful dialogue implementation intended to reproduce Morrowind.exe behavior. During this work we found structural differences between MTM's approach and OpenMW's loader.

Standalone never targets Morrowind.exe, so the acceptance question became:

> **Does OpenMW construct the same observable dialogue behavior from Standalone as it would from the intended Starwind + vanilla load order?**

The current dialogue replay models OpenMW's important INFO behavior:

- `prev_id` drives placement; `next_id` is not the insertion authority;
- empty `prev_id` inserts at the beginning;
- an existing predecessor inserts after that predecessor;
- a missing predecessor appends;
- an override with the same predecessor replaces in place;
- an override with a changed predecessor moves the existing node;
- the insertion point is determined before moving an existing node, matching OpenMW's list/splice semantics;
- IDs are compared case-insensitively for TES3 purposes.

We deliberately did **not** fork `merge_to_master`. Once source dirt and liveness rules were corrected, OpenMW-effective dialogue reached exact behavioral parity without changing MTM.

### Topic liveness

A dialogue topic may survive when it is justified by dialogue-specific evidence, including:

- a DIAL/INFO physically owned by Starwind;
- an engine-driven dialogue family such as Greeting/Voice/Persuasion;
- an explicit `AddTopic` dependency from reachable script content;
- other explicitly reviewed dialogue-specific dependencies.

An ordinary word appearing in response text is **not** sufficient.

This distinction matters because TES3 namespaces can share names. For example, Starwind may legitimately depend on:

```text
RACE "Argonian"
```

without needing:

```text
DIAL "argonian"
```

Starwind reuses some original race records for Star Wars races — Gungans are one example — so typed dependencies remain valid even when the same-named Morrowind lore topic is removed.

### Why generic response-text materialization was removed

Earlier prototypes treated recognized topic names in INFO response text as one-hop dependencies. This pulled large amounts of Morrowind lore into Standalone merely because responses contained words such as:

```text
argonian
bosmer
nord
orc
vivec
skooma
Ghostgate
Nerevar
```

`price on your head` was retained temporarily as the only plausible exception. Inspection of its six retained INFOs showed that they were specifically Morrowind **Thieves Guild bounty-removal dialogue**, including Phane Rielle, Tongue-Toad, Rissinia, Crazy-Legs Arantamo, `PCHasGoldDiscount`, `PayFineThief`, and `Gold_001`.

That experiment established the final policy: **plain response text does not materialize inherited vanilla DIALs.**

### INFO liveness and physical rebuild

For every live topic, the decoupler keeps Starwind-owned INFOs and only the inherited vanilla INFOs that are still relevant to Standalone's actor/game population. The resulting INFO order is taken from the reconstructed effective OpenMW chain.

The plugin's DIAL/INFO section is then physically rebuilt:

```text
survivor[0].prev = ""
survivor[0].next = survivor[1]
...
survivor[n].prev = survivor[n-1]
survivor[n].next = ""
```

Starwind-owned DIAL shells are preserved even when they currently contain no surviving INFOs. Duplicate physical DIAL shells are serialized once.

### The old `igtestcell` defense was removed

The old motherJungle strategy rewrote unresolved `DialogueInfo.speaker_cell` fields to `igtestcell` and removed certain cell filters. That made old dialogue effectively impossible to match while leaving it structurally present.

Once dialogue began being physically pruned and relinked, that defense became both unnecessary and undesirable. It had been mutating **9,816 Starwind INFO payloads** in one audit run.

The current pipeline preserves retained INFO payloads verbatim. The final dialogue audit reports **zero INFO-content mismatches**.

## 7. Run dependency closure again after dialogue materialization

Materializing an inherited vanilla INFO can introduce new typed references — factions were the concrete case that exposed this.

Therefore `addVanillaRefs` now performs a **second recursive dependency-closure pass after dialogue materialization** and before stripping masters:

```text
initial recursive closure
        ↓
dialogue reconstruction/materialization
        ↓
new typed dependencies may now exist
        ↓
second recursive closure
        ↓
remove masters
```

This prevents dialogue materialization from creating unresolved dependencies late in the build.

## 8. Strip masters and save Standalone

After the second closure pass, the Bethesda masters are removed from the output header and `Starwind.esp` becomes:

```text
.swbuild/standalone/out/Starwind-Standalone.omwaddon
```

The current closure audit verifies that the output header contains **no masters**.

# Dialogue source hygiene and TESCS dirt

The masterless work exposed how much of Starwind's dialogue source is Construction Set history rather than intentional content.

`dialogue_source_hygiene.py` is parent-aware:

```text
V1.15 parent state:
    Morrowind → Tribunal → Bloodmoon

RemasteredPatch parent state:
    Morrowind → Tribunal → Bloodmoon → V1.15
```

That matters because a Patch INFO may be overriding Starwind V1.15 rather than vanilla directly.

The hygiene auditor classifies physical INFOs as:

| Category | Meaning | Default action |
| --- | --- | --- |
| `NEW_INFO` | no active inherited INFO with that topic/ID | keep |
| `MODIFIED_PARENT` | semantic payload differs from inherited parent | keep/review |
| `REDUNDANT_EXACT_COPY` | byte-for-byte identical to inherited parent | safe cleanup candidate |
| `PROBABLE_TESCS_LINK_DIRT` | semantic payload identical; only `prev_id`/`next_id` differs | structural; do **not** bulk-delete blindly |
| `DELETED_PARENT_OVERRIDE` | deliberately deletes an inherited INFO | keep by default |
| `REDUNDANT_DELETE` | parent already deleted | cleanup candidate after review |
| `ORPHAN_DELETE` | deletes no known inherited INFO | investigate |

## The big RemasteredPatch cleanup

Before source hygiene, `StarwindRemasteredPatch` contained **13,077 physical INFOs**. Parent-aware analysis found:

```text
NEW_INFO                    4,659
MODIFIED_PARENT               337
REDUNDANT_EXACT_COPY         3,002
PROBABLE_TESCS_LINK_DIRT       260
DELETED_PARENT_OVERRIDE      4,819
```

The **3,002 exact inherited copies were removed**. A subsequent hygiene report showed Patch at **10,075 physical INFOs and zero redundant exact copies**.

This is precisely the kind of dirt expected from TESCS dialogue editing: inserting or deleting INFOs can cause surrounding nodes to be rewritten even when their actual response/conditions are unchanged.

### `Hello` as the clearest example

At one stage `StarwindRemasteredPatch` physically contained **5,121 `Hello` INFO records**:

```text
979  genuinely new Starwind INFOs
 11  semantic parent modifications
810  exact inherited copies
129  link-only inherited overrides
3192 inherited INFO deletions
```

That record set was effectively a TESCS snapshot/delta of a huge vanilla chain, not 5,121 intentional Starwind responses.

The exact-copy cleanup eliminated hundreds of useless `Hello` records and also removed the apparent Helseth ordering problem without any special MTM workaround.

## Known dead Tribunal-journal dialogue

Three V1.15 INFOs were found to be gated by Tribunal journal `TR08_Hlaalu >= 70` even though Standalone has no path that advances that Tribunal quest state:

```text
19191290671947220251
192701535310983235
3221696071812632454
```

They were removed with `tes3cmd` as source cleanup.

A fourth suspicious Helseth `Hello` INFO (`1971360323023215329`, gated by `TR08_Hlaalu >= 100`) had already disappeared as part of the redundant exact-copy cleanup, so no additional Patch edit was required.

`TR08_Hlaalu` itself is a real Tribunal Journal DIAL; the bug was retaining Tribunal dialogue that depended on it, not an undefined identifier.

# Validation

The project intentionally uses multiple independent audits rather than trusting a successful build.

## Closure audit — `motherjungle_audit.py`

The closure auditor converts the final plugin back to JSON and walks hard typed dependencies. It covers references from NPCs, creatures, inventories, races/classes/factions, cells, bodyparts, armor/clothing, scripts, leveled lists, dialogue constraints, faction reactions, and other TES3 record relationships.

`FFFF` is treated specially in dialogue faction fields because TES3 uses it as the `-NO FACTION-` sentinel, not as a FACT editor ID.

Current result:

```text
masters                               0
hard_unresolved_occurrences           0
hard_unresolved_unique_ids            0
hard_unresolved_source_records        0
hard_unresolved_sources_likely_imported 0
```

## Dialogue audit — `dialogue_chain_audit.py`

The dialogue validator independently reconstructs expected OpenMW dialogue and compares it to Standalone.

Important design decisions accumulated during development:

- expected reconstruction uses the **exact staged Standalone vanilla masters** when available, not pristine JSON, so intentional build-time vanilla pruning is reflected in the oracle;
- Starwind source ownership is tracked independently;
- Rust `decoupleLog.txt` materialization telemetry is correlated against Python expectations;
- actor-domain constraints are used to distinguish harmless order changes from potentially competing INFOs;
- source provenance can be traced back through Morrowind/Tribunal/Bloodmoon/V1.15/Patch;
- physical record order and serialized links can be checked strictly, but behavioral equivalence is the default release criterion.

Current behavioral result:

```text
expected_live_dialogues                498
standalone_dialogues                   498
missing_dialogues                        0
extra_dialogues                          0
missing_live_infos                       0
extra_dead_infos                         0
engine_order_mismatches                  0
precedence_inversions                    0
potentially_competing_inversions         0
dialogue_content_mismatches              0
info_content_mismatches                  0
standalone_orphan_infos                  0
```

The validator also reports:

```text
standalone_physical_order_mismatches    12
serialized_link_mismatches              33
```

These remain visible because they are useful for the next source-cleaning phase, but OpenMW currently reconstructs the exact expected effective order despite them.

## Current release criteria

The following are **hard failures** for Standalone:

- missing or unexpected required DIALs;
- missing or unexpected effective INFOs;
- OpenMW-effective INFO order mismatch;
- a precedence inversion that can affect selection;
- retained dialogue payload mutation;
- orphan INFO records;
- unresolved hard TES3 dependencies;
- any remaining masters.

The following are currently **diagnostic/cleanup targets** rather than behavioral failures:

- physical INFO serialization order;
- stale/overridden physical INFO history;
- serialized `next_id` differences that do not affect OpenMW placement;
- other structural chain differences when the effective OpenMW sequence is identical.

# How the dialogue validator evolved

<details>
<summary>Development history / why the current oracle looks complicated</summary>

The validator was intentionally revised as assumptions were disproven by the real Starwind data:

1. **Initial exact-chain audit** incorrectly compared a masterless file directly against the full vanilla+Starwind dialogue universe.
2. A second model treated Standalone as if vanilla DIAL/INFO would remain inherited; that was also wrong — the whole point is to exclude unnecessary Morrowind dialogue.
3. The next model projected only Starwind-owned INFOs. This exposed broken links but was too aggressive because Starwind legitimately relies on some unchanged vanilla dialogue.
4. A liveness-aware model was introduced: Starwind-owned INFOs plus inherited INFOs that can actually participate in Starwind.
5. Recursive response-text topic discovery exploded through Morrowind's dialogue graph, proving that transitive text closure was inappropriate.
6. One-hop text discovery was tried and still imported ordinary Morrowind lore because topic names are normal words.
7. Behavior-aware inversion analysis showed that exact physical chain equality is stricter than actual gameplay equivalence.
8. Source-provenance tracing identified large quantities of TESCS dirt and exact vanilla copies in RemasteredPatch.
9. The expected base was changed to the staged, build-pruned vanilla masters rather than pristine source JSON.
10. Finally, arbitrary response-text topic materialization was removed. Explicit typed dependencies, engine dialogue, Starwind-owned dialogue, and explicit script `AddTopic` dependencies remain independent.

This sequence of failures is useful provenance: the current policy exists because each broader policy was tested against the real Starwind data and shown to import or retain content the game did not need.

</details>

# Why we did not fork `merge_to_master`

During debugging, MTM's dialogue reconstruction was compared with OpenMW's loader. MTM intentionally models Morrowind.exe-oriented behavior and can structurally reorder/relink dialogue differently from OpenMW.

For a time, `Greeting 0` and `Hello` showed tiny effective-order discrepancies and it was tempting to bypass or fork MTM. Further provenance work demonstrated that the apparent problems were largely caused by Starwind source dirt and dead inherited dialogue.

After exact-copy cleanup, dead Tribunal-dialogue removal, build-local vanilla pruning, and narrower dialogue liveness, the final OpenMW-effective audit reached **zero order mismatches and zero precedence inversions without changing MTM**.

The project therefore keeps MTM as the historical merge engine and validates/canonicalizes the Standalone result for the runtime we actually target.

# Current next step: data/content split

The root `Starwind-Standalone.omwaddon` is now the monolithic baseline for a
Tamriel Rebuilt-style split:

```text
Star_Data.omwaddon       stable definitions and reusable data
        ↑
Starwind.omwaddon        world, actors, state, scripts, and dialogue
```

`split_starwind.py` produces the first dependency-checked definition split.
Always-Data families are `GMST`, `MGEF`, `SKIL`, `RACE`, `CLAS`, `FACT`,
`BSGN`, `SOUN`, `SNDG`, `STAT`, `BODY`, `APPA`, `LOCK`, `PROB`, `REPA`,
`INGR`, `ALCH`, `ENCH`, and `SPEL`. Candidate families are `WEAP`, `ARMO`,
`CLOT`, `MISC`, `LIGH`, `ACTI`, `CONT`, `DOOR`, `CREA`, `LEVI`, and `LEVC`;
only records whose typed dependencies also resolve inside Data are promoted.

`CELL`, `PGRD`, `DIAL`, `INFO`, `NPC_`, `SCPT`, `GLOB`, `REGN`, `BOOK`,
`StartScript`, and other world/content records remain in `Starwind` by
default. A legacy script may cross the boundary only when its ID is explicitly
added to the splitter's approved Data-script allowlist.

Scripted item/object definitions therefore remain in `Starwind` unless their
script is explicitly approved. Dependency resolution is record-namespace-aware;
for example, `RACE "Droid"` cannot match `DIAL "droid"`. This preserves the
one-way invariant:

```text
Star_Data → Starwind = 0 dependencies
Starwind → Star_Data = allowed
```

Run the split from the repository root with:

```bash
./split_starwind.py
```

The generated `.swbuild/split/starwind-split-report.json` records the boundary,
demotions, header masters, dependency checks, and record-for-record
reconstruction result.

# Later next step: physical dialogue cleanup

Behavioral correctness is no longer the blocker. The next goal is the one that motivated this archaeology in the first place: **remove unnecessary physical dialogue baggage instead of merely proving it harmless.**

The current validator still finds:

```text
12 topics with physical INFO-order differences
33 serialized prev/next differences
```

Some historically large groups have contained far more physical records than the effective OpenMW chain because overwritten/deleted/TESCS-dirt history is still serialized.

The cleanup strategy should stay conservative:

1. Re-run `dialogue_source_hygiene.py` after every source edit.
2. Treat exact inherited copies as safe cleanup candidates.
3. Do **not** globally delete link-only overrides merely because TESCS generated them; some encode the intended insertion of real Starwind INFOs.
4. Keep parent deletions by default — they are often exactly how Starwind suppresses vanilla dialogue.
5. Clean one structural class/topic at a time.
6. Rebuild Standalone after every batch.
7. Require closure audit = 0 unresolved.
8. Require dialogue behavioral audit = exact match.
9. Use `--strict-structure` as the progress meter toward the eventual physical-canonicalization goal.

The eventual ideal is not merely behavioral parity but:

```text
physical INFO set == intended effective INFO set
physical INFO order == OpenMW effective order
serialized prev/next == canonical survivor links
```

without reintroducing vanilla content Starwind does not need.

# Source-edit policy

There are two intentionally different kinds of surgery in this project:

### Canonical Starwind source cleanup

When a record is genuinely corrupt/redundant in Starwind itself, clean the Starwind source and commit the resulting JSON. Examples so far include:

- removal of the 3,002 exact parent INFO copies from RemasteredPatch;
- removal of the three dead V1.15 `TR08_Hlaalu` INFOs.

### Standalone-only build surgery

When vanilla data is legitimate in Morrowind but specifically unwanted for the masterless Starwind product, modify only the staged `.swbuild/standalone/work/` masters. The 53 dead vanilla faction INFOs are the canonical example.

This distinction prevents the project from quietly maintaining modified copies of Bethesda's master data while still allowing Standalone to define a precise vanilla dependency boundary.

# Reports and forensic artifacts

Useful generated files include:

```text
.swbuild/standalone/build-manifest.json
.swbuild/standalone/work/decoupleLog.txt
.swbuild/standalone/reports/Starwind-Standalone-closure-audit.json
.swbuild/reports/Starwind-Standalone-dialogue-chain-audit.json
.swbuild/reports/Starwind-dialogue-source-hygiene-v2.json
.swbuild/split/starwind-split-report.json
```

`decoupleLog.txt` is particularly useful because `addVanillaRefs` records why vanilla dialogue topics/INFOs were retained or materialized.

# Compatibility and project warnings

- **Standalone is OpenMW-only by design.** Do not use Morrowind.exe behavior as the release oracle.
- Do not load `Solo`, `Standalone`, and `TSI` together.
- The merged plugin project should not be assumed compatible with arbitrary old Starwind add-ons. Mods are being modernized and reintegrated deliberately.
- Do not import an entire Morrowind subsystem merely to satisfy a dead dialogue condition. Prove the dependency is live first.
- Same editor-ID text in different TES3 record namespaces does not imply the same dependency (`RACE "Argonian"` is not `DIAL "argonian"`).
- Generated `.swbuild` files are disposable. Canonical source changes belong in `plugins/*.json` and the source repositories.

# History

Over time, as **The Starwind Initiative** matured, the team accumulated multiplayer fixes, content corrections, and one-off Builder surgery. Many fixes were discovered because multiplayer was exceptionally good at exposing broken assumptions in old Starwind data.

The original merged-plugin work was an attempt to get those fixes into one maintained Starwind base rather than leaving them scattered across deployment scripts. The modern version of the project goes further: historical Builder behavior is reproduced locally, dependency closure is measured, dialogue is validated against OpenMW, and masterless output is treated as a testable transformation rather than a black-box merge.

The work remains available through the surrounding DreamWeave/TSI projects, especially:

- [Starwind-Builder](https://github.com/DreamWeave-MP/Starwind-Builder/)
- [motherJungle](https://github.com/DreamWeave-MP/motherJungle)

## Credits

{% credits(default=true) %}
Most of the changes and fixes in here were drawn from bug reports and other errata discovered by the TSI community. Thanks to all of you, as well <3.

- Special Thanks to:  
Ignatious  
SkoomaBreath  
RymanTheGreat  
VidiAquam
{% end %}
