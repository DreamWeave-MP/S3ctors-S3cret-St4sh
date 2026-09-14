---
title: Design decisions
weight: 80
description: Intentional project policies that should not be mistaken for implementation accidents.
---

# Design decisions

This page records decisions that are part of Definitive Starwind's intended
product behavior or maintainability model. Future cleanup should not "fix"
these merely because they differ from Morrowind or from an earlier build.

## OpenMW is the target

The masterless build is designed and validated for OpenMW. Morrowind.exe is not
a compatibility target.

This matters most for dialogue, where merge/load behavior can differ. OpenMW's
effective result is the release oracle.

## Definitive is one product, not a build mode matrix

The modern builder has one approved content graph. Historical Solo/Standalone/
TSI branches remain useful provenance but are not alternative outputs of the
Definitive toolchain.

## Star_Data is a stability boundary

`Star_Data.omwaddon` is not merely "everything except CELL and INFO." It is the
stable dependency/API surface for reusable Starwind records.

Records may remain in `Starwind.omwaddon` even when technically reusable if
they are still coupled to high-churn content or legacy scripts.

## Legacy MWScript defaults to Starwind

Most `SCPT` records stay in `Starwind.omwaddon` because a large portion of the
MWScript implementation is expected to be removed or replaced with OpenMW Lua.

Putting that legacy corpus in `Star_Data` would make the supposedly stable
foundation churn throughout modernization.

Exceptions are possible for deliberately stable shared framework behavior, but
they must be explicit.

## LUAL and Lua migration

During active migration, most LUAL registrations/content Lua should also remain
on the `Starwind` side unless they form a deliberately public/stable framework.

The long-term goal is a small intentional shared Lua API rather than a dump of
content scripts into Data.

## GMST, MGEF, and SKIL are foundational

These record families are not reachability-pruned.

The absence of an obvious ordinary record reference does not prove that an
engine-facing game setting, effect, or skill is unused.

Exact byte-identical physical duplicates may still be deduplicated because
that operation does not decide the record is semantically unused.

## FACT, REGN, and CLAS are manual-review families

These record types can be semantically important even when simple reachability
looks weak:

- factions can participate in reactions, dialogue, player systems, or future content;
- regions can be reused for weather/pseudo-exterior behavior;
- classes may be made available to the player during chargen even if no current NPC uses them.

Automated deletion based only on "no current actor references it" is therefore
not allowed.

There is one audited exception: Definitive preprocessing removes 25
non-playable classes whose NPC, dialogue, and script reference counts are all
zero. The 18 playable Starwind chargen classes and every referenced non-playable
class remain. This is an explicit reviewed source boundary, not an automated
reachability rule.

## Equipment enchantment capacity is normalized to 375

Definitive Starwind intentionally makes otherwise-unenchanted equipment broadly
customizable.

This is not an attempt to preserve Morrowind balance. Player personalization is
a product goal informed by long-term TSI operation and by the modding-oriented
nature of the game.

## Naboo is base Definitive content

Naboo was historically tied to TSI and was barely deployed, but it is considered
part of modern base Starwind. The Definitive build brings it into the supported
single-player/OpenMW corpus and subjects it to the same cleanup/validation as
the older content.

## Bing's Race Pack and Enhanced are base content

They are not optional historical extras in the new product. Bing is merged into
Enhanced and both feed the canonical Patch merge.

## MPRecords and Vvardenfell are excluded by product definition

Their absence is not a temporary build optimization. They are outside the
approved Definitive corpus unless project policy changes explicitly.

## Main quest must survive

Historical multiplayer operations intentionally removed pieces of Starwind's
main quest. Definitive must preserve it. A dedicated regression guard exists
because relying on memory or comments in old scripts is not sufficient.

## Delete causes, not symptoms

When closure imports irrelevant vanilla data, the preferred repair is to remove
or correct the causal stale reference/INFO/list/region edge rather than delete
the imported target from the final plugin.

This principle produced cleaner fixes for dialogue-only actors, region sleep
encounters, and dead faction dialogue.

## Data split should be conservative about promotion

A reusable record can safely remain in `Starwind` while its dependencies are
still unstable. Moving content-specific or high-churn records into `Star_Data`
is harder to undo because downstream mods may begin depending on them.

Promotion into Data is therefore earned by stability and dependency safety.

[API index](../) · [Data/content split](../data-content-split/) · [Historical cleanup ledger](../historical-cleanup-ledger/)
