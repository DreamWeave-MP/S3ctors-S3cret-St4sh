---
title: Source corpus & preprocessing
weight: 20
description: Included and excluded sources, Definitive preprocessing policy, and main-quest preservation.
---

# Source corpus & preprocessing

The Definitive builder deliberately separates **what belongs in Starwind**
from **how historical TSI deployment happened to be assembled**.

## Included sources

The builder compiles the following fixed inputs:

| Logical source | Role |
| --- | --- |
| Morrowind | Bethesda dependency/reference input |
| Tribunal | Bethesda dependency/reference input |
| Bloodmoon | Bethesda dependency/reference input |
| Minimal | minimal TES3 master seed for decoupling |
| Starwind Remastered V1.15 | principal Starwind base |
| Starwind Remastered Patch | principal Starwind patch/content layer |
| Bing's Race Pack | considered base Starwind content; folded into Enhanced |
| Starwind Enhanced | approved base content |
| PlanExp | approved Definitive content |
| Alt Start | approved Definitive content |
| Community Patch Project | approved fixes/content |
| Naboo | approved base content; historically TSI-exclusive and largely undeployed |
| PartyHats | approved Definitive content |

Naboo is intentionally part of the modern single-player/Definitive corpus; it
is not treated as a multiplayer-only addon.

## Explicitly excluded sources

```text
StarwindMPRecords
StarwindVvardenfell
```

These are not compiled, cleaned, merged, or used as dependency inputs by the
Definitive builder.

The source manifest records both included-source hashes and excluded logical
sources so accidental corpus drift is visible.

## Why the old TSI preprocess cannot be reused

The old TSI build path mixed legitimate source integration with server policy.
It included operations whose explicit purpose was to remove or replace content
for multiplayer.

Examples of historical TSI-only behavior that Definitive **must not** inherit:

- use of a `nomq` Patch variant rather than the normal main-quest source;
- TSI gold substitution (`random gold` -> `tsi_gold` and related leveled records);
- TSI Kolto substitutions;
- Taris and other instance deletions labeled as records that should not exist in MP;
- Freighter/embassy replacements supplied by MP-side scripts/plugins;
- `SW_CourteCompScript` multiplayer cleanup;
- `SW_ShipQuester` removal;
- Hutt/Ragax/Badhiya reference removals labeled as broken MP refs;
- Vvardenfell-specific surgery;
- MPRecords merge/deployment assumptions.

Some old Shade/Thegg deletion commands were commented out in the historical
script, but the surrounding TSI path was destructive enough that Definitive
uses an explicit whitelist rather than trying to turn TSI preprocessing into a
new product with switches.

## Reviewed Definitive preprocessing

The current builder performs only operations that have been reviewed as
source hygiene, merge integration, or explicit Definitive design policy.

### General source hygiene

The historical Builder transcription contains known fixes such as typo/text
corrections, removal of stale compiled script bytecode before recompilation,
known junk-cell cleanup, and other source repairs accumulated during Starwind
maintenance.

The implementation is the source of truth for the exact commands. This wiki
records the *reason* and status of each class of change rather than duplicating
hundreds of command-line selectors that could drift out of sync.

### Bing integration

Bing's Race Pack is treated as base content and merged into Enhanced first.
Reviewed dirty-cell/bodypart/duplicate-reference cleanup is allowed where it
resolves known plugin integration defects rather than multiplayer policy.

### Alt Start integration

Alt Start contributes the background-selection escape pods to the canonical
`Imperial Prison Ship` cell. The Definitive build preserves those source-owned
placements because `StarwindMPRecords` is intentionally excluded; deleting the
whole Alt Start cell would incorrectly remove the pod doors while leaving some
of their definitions behind. The canonical merge therefore retains the Alt
Start cell additions while the existing Starwind prison-ship content remains
authoritative.

### Naboo integration

Naboo's obsolete DRM/test machinery is removed as source hygiene. Attachments
and dependencies must be removed coherently; a deletion that leaves live
containers or other records referring to the removed object is considered a
build bug and is caught by closure validation.

### Enhanced cleanup

Known duplicate/reference/bodypart corrections discovered during earlier
Starwind/TSI maintenance remain valid when they fix the data itself rather
than enforcing multiplayer behavior.

## Main-quest preservation guard

The Definitive builder has a dedicated regression guard because historical
multiplayer builds deliberately removed portions of the main quest.

The current anchor set includes reviewed quest DIALs, Shade NPCs, Shade
scripts, `SW_ShipQuester`, and a required live `SW_ShipQuester` cell reference.
The exact set is emitted to `main-quest-preservation.json`.

Checks occur at four stages:

1. before Definitive preprocessing;
2. after Definitive preprocessing;
3. after canonical merge;
4. after master decoupling.

The post-preprocess check examines only the active staged source filenames.
`tes3cmd` backup plugins (`~1.esm`, `~2.esp`, etc.) are excluded so deleted
main-quest content cannot be hidden by a stale backup copy.

## Enchantment normalization

Unenchanted `CLOT`, `ARMO`, and `WEAP` records are normalized to enchantment
capacity `375`.

This is intentional Definitive Edition game design. Long-term TSI experience
showed that players valued easier personalization and equipment freedom.
Starwind is not trying to reproduce Morrowind's original balance merely because
Morrowind supplied the engine.

## Source edit versus build policy

Use this rule:

**Canonical source cleanup** belongs in `plugins/*.json` when a source record is
actually corrupt, redundant, or intentionally removed from Starwind.

**Build policy** belongs in `build_starwind.py` when it describes how valid
sources are combined into the Definitive product.

**Bethesda-only dependency surgery** belongs in staged work copies under
`.swbuild/definitive/work/`, never in canonical Bethesda JSON.

This distinction is why, for example, dirty Starwind INFOs were removed from
Starwind source while the 53 known-dead Morrowind/Tribunal/Bloodmoon INFOs are
pruned only from temporary vanilla masters during the build.

[API index](../) · [Build pipeline](../build-pipeline/) · [Historical cleanup ledger](../historical-cleanup-ledger/)
