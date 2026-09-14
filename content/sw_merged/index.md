---
title: Starwind Merged Plugin Project
description: Reproducible Definitive Starwind builds with recursive master decoupling, audited dialogue behavior, and a validated Star_Data/Starwind split.
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
**Definitive Starwind** edition for OpenMW.

The release is split into two plugins:

- **`Star_Data.omwaddon`** — stable definitions, reusable resources, shared records, and the long-term foundation for Starwind mods.
- **`Starwind.omwaddon`** — world content, actors, quests, dialogue, legacy MWScript, and other content expected to keep changing during modernization.

`Starwind.omwaddon` depends only on `Star_Data.omwaddon`. Load both, with
`Starwind.omwaddon` after `Star_Data.omwaddon`.

<!-- more -->

{{ install_instructions(describe=true) }}

> **This pair is the supported merged Starwind product.** Do not load an older merged Starwind plugin alongside it.
>
> **OpenMW is the compatibility target.** Morrowind.exe compatibility is not a goal of the masterless Definitive build.

## Current status

The current pipeline builds the complete approved Definitive corpus, decouples
it from Bethesda masters, canonicalizes dialogue, and validates the final
`Star_Data` / `Starwind` partition.

| Invariant | Current result |
| --- | ---: |
| Monolith records, excluding header | **30,573** |
| Header masters | **0** |
| Hard unresolved dependencies | **0** |
| Expected / actual DIALs | **591 / 591** |
| Missing / extra live INFOs | **0 / 0** |
| OpenMW engine-order mismatches | **0** |
| Physical-order mismatches | **0** |
| Serialized-link mismatches | **0** |
| Dialogue payload mismatches | **0** |
| `Star_Data -> Starwind` dependencies | **0** |
| Split reconstruction | **exact** |

The generated split currently contains **13,355** non-header records in
`Star_Data.omwaddon` and **17,218** in `Starwind.omwaddon`.

## Build it

```bash
./build_starwind.py --strict
```

Keep the temporary work tree and forensic logs when investigating a build:

```bash
./build_starwind.py --strict --keep-work
```

The build always follows one fixed source graph. There are no Solo, Standalone,
or TSI modes in the Definitive builder.

## What is included

The approved source corpus is:

- Morrowind, Tribunal, Bloodmoon, and Minimal as dependency/reference inputs;
- Starwind Remastered V1.15 and Remastered Patch;
- Bing's Race Pack;
- Starwind Enhanced;
- PlanExp;
- Alt Start;
- Starwind Community Patch Project;
- Naboo;
- PartyHats.

`StarwindMPRecords` and `StarwindVvardenfell` are explicitly excluded from the
Definitive product.

## What the builder does

At a high level:

```text
approved source corpus
        -> compile + source hygiene
        -> reviewed Definitive preprocessing
        -> canonical merge
        -> master decoupling + dependency closure
        -> OpenMW dialogue canonicalization
        -> final tombstone cleanup
        -> closure/dialogue/MQ validation
        -> Star_Data / Starwind split
        -> exact reconstruction validation
```

The builder intentionally preserves the main Starwind quest, does **not** run
the old multiplayer-specific TSI surgery, and retains a small set of deliberate
Definitive design policies such as the `375` equipment enchantment-capacity
normalization.

## Deep reference

The project history became too detailed for a useful landing page. The full
implementation and archaeology are maintained as a navigable reference under
**[Definitive Build API & Wiki](./api/)**.

Start with:

- **[Build pipeline](./api/build-pipeline/)** — exact source graph, merge order, generated tree, and stage-by-stage behavior.
- **[Source corpus & preprocessing](./api/source-corpus-and-preprocessing/)** — every included/excluded source, reviewed cleanup policy, MQ preservation, and old TSI operations that are intentionally *not* run.
- **[Master decoupling & dependency closure](./api/master-decoupling/)** — `Minimal`, `addVanillaRefs`, staged vanilla surgery, recursive closure, tombstone handling, and dependency rules.
- **[Dialogue canonicalization](./api/dialogue-canonicalization/)** — the full OpenMW dialogue reconstruction story, TESCS dirt cleanup, liveness model, and why the final chain is physically canonical.
- **[Star_Data / Starwind split](./api/data-content-split/)** — record placement policy, dependency-direction rules, script/Lua exceptions, and exact split validation.
- **[Validation & reports](./api/validation-and-reports/)** — every validator, hard-failure contract, report path, and current invariants.
- **[Historical cleanup ledger](./api/historical-cleanup-ledger/)** — specific records/classes of records removed or changed, why they were changed, and where the decision came from.
- **[Design decisions](./api/design-decisions/)** — OpenMW-only target, Lua migration boundaries, no reachability-pruning of foundational GMST/MGEF/SKIL data, manual FACT/REGN/CLAS review, and player-customization policy.
- **[Tools & commands](./api/tools-and-commands/)** — `tes3conv`, `tes3cmd`, `merge_to_master`, motherJungle, audit scripts, and useful forensic commands.

## Generated outputs

```text
.swbuild/definitive/
├── work/
├── out/
│   ├── Starwind-Definitive.omwaddon
│   ├── Star_Data.omwaddon
│   └── Starwind.omwaddon
├── reports/
└── build-manifest.json
```

`Starwind-Definitive.omwaddon` is the masterless canonical monolith used as the
split oracle. The supported release is the `Star_Data.omwaddon` +
`Starwind.omwaddon` pair.

## Compatibility and warnings

- Do not combine the Definitive pair with an older merged Starwind plugin.
- OpenMW is the release oracle; Morrowind.exe-specific behavior is not preserved merely for compatibility.
- Same editor-ID text in different TES3 namespaces does not imply the same dependency (`RACE "Argonian"` is not `DIAL "argonian"`).
- Generated `.swbuild` files are disposable. Canonical source edits belong in `plugins/*.json` and the upstream source repositories.
- Legacy MWScript generally remains in `Starwind.omwaddon` because much of it is expected to be replaced with OpenMW Lua. `Star_Data` is intended to remain the more stable dependency surface.

## History

This project grew out of years of Starwind and TSI maintenance. Multiplayer
operation exposed a large number of broken assumptions in the original data,
and that history became useful source archaeology for the modern Definitive
build. The current pipeline keeps reviewed fixes and intentional design
choices while discarding the old deployment-mode architecture.

For the exhaustive history, including the old dialogue strategies that were
tried and rejected, see the **[historical cleanup ledger](./api/historical-cleanup-ledger/)** and **[dialogue canonicalization reference](./api/dialogue-canonicalization/)**.

Principal upstream references:

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
