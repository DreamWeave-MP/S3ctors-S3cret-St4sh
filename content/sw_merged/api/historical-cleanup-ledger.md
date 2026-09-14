---
title: Historical cleanup ledger
weight: 70
description: Specific data cleanups, removals, rejected historical behavior, and provenance behind the Definitive transformation.
---

# Historical cleanup ledger

This page is the durable archaeology record: what was changed or removed, why,
and whether the action applies to canonical source, staged vanilla inputs, or
final masterless serialization.

It is intentionally more detailed than the project landing page.

## Historical build lineage

The modern builder descends from Starwind-Builder and TSI deployment work, but
**Definitive is not the old TSI build**.

Historical CI had separate SP/TSI behavior. The TSI path was explicitly allowed
to alter or remove content for server operation, including using a no-main-
quest Patch variant and performing reference surgery that a definitive
single-player base must never inherit.

The modern builder therefore preserves historical scripts as provenance but
re-approves operations individually.

## Source dialogue exact-copy cleanup

A parent-aware RemasteredPatch audit identified **3,002** INFO records that were
byte-for-byte identical to the inherited parent record, including linkage.

These records contributed no semantic or structural change and were removed
from canonical Starwind source.

This cleanup alone reduced enormous TESCS dialogue snapshots such as `Hello`
without changing effective dialogue.

## Link-only TESCS dialogue dirt

Many physical Starwind INFOs were semantically identical to Bethesda parent
INFOs but carried modified `prev_id`/`next_id` links because TESCS rewrote
neighboring records when new dialogue was inserted.

These were *not* globally deleted on sight. Link-only overrides can be the
mechanical glue surrounding a legitimate new Starwind INFO.

Later actor-provenance analysis identified a subset that served only to import
vanilla actors and dependency trees. Those proven dirty roots were removed at
source, allowing their actor/script/inventory trees to disappear through normal
closure rather than final-plugin whack-a-mole.

## Dead Tribunal `TR08_Hlaalu` INFOs

Three V1.15 INFO IDs were modified Starwind copies of Tribunal dialogue gated
on unreachable Tribunal journal state:

```text
19191290671947220251
192701535310983235
3221696071812632454
```

They were removed from Starwind source.

A fourth Helseth `Hello` INFO requiring `TR08_Hlaalu >= 100` had already been
removed by the exact-copy cleanup.

## Vanilla faction-dialogue staged prune

The final exact set of **53** inherited Bethesda INFO IDs responsible for dead
Morag Tong / Hands of Almalexia / Census and Excise dependencies is embedded in
the build driver.

They are deleted only from temporary staged vanilla masters before dialogue
materialization.

A preliminary broad `tes3cmd --sub-match` search returned 563 IDs and was
explicitly rejected as overbroad.

## `FFFF` sentinel

Two apparent missing faction references were actually `speaker_faction =
"FFFF"`, the TES3 Construction Set representation of `-NO FACTION-`.

The closure model was corrected; no fake faction record is imported.

## Response-text dialogue materialization removed

Generic topic-name scanning was progressively narrowed and finally removed.
Ordinary response text is not considered sufficient evidence to import a
Bethesda DIAL.

The final test case was `price on your head`. Manual inspection proved the six
candidate INFOs were Morrowind Thieves Guild bounty-removal content, not generic
crime-system functionality needed by Starwind.

## INFO tombstone serialization removed

An earlier masterless build contained exactly **4,826** more physical INFOs
than the expected live set. Every excess record was a deletion tombstone.

The decoupler was corrected so tombstones suppress their parent during
reconstruction but are not serialized after the masters are gone.

This change brought effective order, physical order, and serialized links to
exact equality.

## Non-dialogue tombstones

The same masterless principle was later generalized to other deleted records:
once parent/master deletion semantics have been applied, dead top-level
tombstones are not useful in the final self-contained artifact.

## Exact duplicate MGEFs

Eight byte-identical physical MagicEffect duplicates were identified in one
intermediate build (`Levitate`, `SlowFall`, `Lock`, `Invisibility`, `Dispel`,
`Telekinesis`, `Mark`, `Reflect`) and deduplicated.

This is **not MGEF pruning**. MGEF/SKIL/GMST remain foundational and off-limits
to reachability-based minimization.

## Region sleep-creature cleanup

Reused vanilla regions carried vanilla `sleep_creature` leveled-list links into
Starwind pseudo-exterior areas. Those links could import Morrowind/Bloodmoon
sleep encounter lists and vanilla creatures into Star Wars locations.

The causal region sleep dependencies were removed rather than pruning the
creatures after import.

## Exterior/LAND/LTEX residue

An earlier Standalone corpus retained a tiny leftover exterior worldspace
island after the large exterior-cell cleanup. That residue was separately
audited and removed where it was proven unnecessary.

Definitive revalidates the full approved corpus after Naboo/Enhanced/etc.; the
historical result is recorded here as provenance, not as a blanket rule that
all future LAND/LTEX records must be deleted.

## Dialogue-driven late actor cleanup

A pre-Definitive provenance pass found **94** actors imported only after
dialogue liveness. **82** were rooted solely in link-only TESCS-dirt INFOs.
Cleaning those causal INFOs removed the actor records and their transitive
inventory/script/etc. dependencies naturally.

This is why the modern decoupler also defers dialogue dependencies until after
the non-dialogue actor population is known.

## Naboo DRM/test cleanup

Naboo is approved Definitive content, but old DRM/test machinery is not. Those
records are removed as integration/source hygiene, with closure validation used
to ensure no live container/object still references a deleted dependency.

## Bing/Enhanced integration cleanup

Reviewed dirty-cell, orphan-bodypart, duplicate-reference, and related merge
fixes discovered during TSI maintenance remain valid when they correct the
source data itself rather than implement server policy.

The final actor-provenance pass also removed **23** source-owned INFO records
that imported vanilla actors only through dialogue dependency closure. The
records were limited to the approved Starwind source packs:

- Bing's Race Pack: `946685598144191231`, `2301111508799109825`,
  `909260325349167310`, `864550852431976539`, `1906888690290850855`,
  `859512568224451931`, `4773219712502012140`, `883924055226252767`,
  `129241610110205027`, `2734162771419514016`, `135879349263212923`,
  `3260216811858410234`, `17567110311180430349`;
- Enhanced: `3109648071102316693`, `2257190978769676981`;
- Naboo: `283975135048201436`;
- StarwindPlanExp: `1847857661117273120`, `1910916768339372042`,
  `2230768852655184036`, `1416449617362841427`, `619028186535386174`,
  `1294752263377418595`, `1328358151231324457`.

Six of the Bing records were the same editor-navigation marker across the
`Intruder`, `Hello`, `Thief`, `Idle`, `Flee`, and `Hit` topics. Each used
`dialog placeholder` as speaker and
`-----TSAESCI VOICEFILES START HERE-----` as text. They were editor markers,
not runtime dialogue. Provenance telemetry was used to identify the records;
no broad `PROBABLE_TESCS_LINK_DIRT` deletion was performed.

After the actor-bootstrap class was solved, a controlled source-hygiene batch
removed the **43** remaining records that survived into the Definitive output:
42 link-only overrides and Naboo's one redundant exact copy (`airan's teeth`,
INFO `100711405879315001`). The batch was grouped by source: V1.15 (8),
RemasteredPatch (24), Bing's Race Pack (4), Enhanced (1), PlanExp (4), and
Naboo (2). The strict rebuild preserved all 591 canonical DIALs and INFOs,
all ordering and link invariants, and reduced the final output by only the
records that were not recoverable as effective dialogue.

Two V1.15 Attack link-only findings were intentionally excluded because
RemasteredPatch deletes them later. The remaining 10 orphan-delete tombstones
are still source merge semantics and are not part of this cleanup batch.

## Alt Start Imperial Prison Ship conflict

Alt Start's conflicting Imperial Prison Ship cell is removed so the canonical
Starwind cell remains authoritative.

## Dead non-playable class cleanup

The Definitive pair initially contained 99 `CLAS` records. Manual reference
auditing identified 25 non-playable classes with zero NPC, dialogue, and script
references:

```text
Apothecary       Assassin Service    Bard              Battlemage Service
Bookseller       Clothier            Dreamers          Enchanter Service
Gardener         Gondolier           Guild Guide       Journalist
Mabrigash        Miner               Necromancer       Pawnbroker
Pilgrim          Priest Service      Publican          Shipmaster
Sorcerer Service Warlock             Wise Woman        Wise Woman Service
Witch
```

They are deleted only from staged `Morrowind.esm`, `Tribunal.esm`,
`Bloodmoon.esm`, and `StarwindRemasteredV1.15.esm` inputs before the canonical
merge. The source JSON masters remain unchanged, and the 18 playable Starwind
classes plus 56 referenced non-playable classes are retained. The result is
74 intentional/referenced classes in the Definitive pair.

## Czerka faction reaction cleanup

The V1.15 `Imperial Legion` override is intentionally repurposed as **Czerka
Corporation**, with Czerka rank names and Starwind membership. Its inherited
Imperial Legion reaction table was stale Morrowind diplomacy, so the override
now retains only its self-reaction. This is a faction-record correction, not
part of the class cleanup.

## Main-quest removals deliberately *not* carried forward

Old TSI deployment included or contemplated destructive operations that do not
belong in Definitive Edition. The modern builder does not perform:

- no-main-quest Patch substitution;
- `SW_ShipQuester` removal;
- old Taris/main-quest instance deletions;
- old server-only Shade/Thegg cleanup;
- MP replacement-door/freighter edits;
- Courte server cleanup merely for multiplayer behavior;
- TSI gold/Kolto replacement policy;
- MPRecords merge;
- Vvardenfell merge/surgery.

The main-quest preservation guard exists specifically to prevent accidental
regression toward those historical server transforms.

## Enchantment capacity 375 retained intentionally

The old TSI pipeline also normalized otherwise-unenchanted equipment to
capacity `375`. Unlike the destructive MP operations above, this one was
reviewed and explicitly retained as Definitive design.

The reason is player customization: long-term server experience indicated that
players valued freedom to use the equipment they liked rather than having
Morrowind's original enchantment capacity dictate appearance/build choices.

## Provenance principle

Historical TSI behavior falls into three buckets:

1. **source/data fix** — may be retained after review;
2. **intentional Definitive design** — may be retained and documented as policy;
3. **multiplayer deployment policy** — must not enter Definitive merely because it once existed in `build.sh`.

This classification is more important than whether a line appeared under an
old `tsi` branch.

[API index](../) · [Source corpus & preprocessing](../source-corpus-and-preprocessing/) · [Dialogue canonicalization](../dialogue-canonicalization/)
